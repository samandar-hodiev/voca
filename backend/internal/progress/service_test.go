// The arithmetic behind the dashboard.
//
// Streaks and the week/previous-week comparison are the only real logic in this module,
// and both are the kind that looks obviously right and is quietly wrong at the edges: a
// streak that dies at midnight instead of at the end of the day, or a second day of
// practice reported as a huge improvement because there is nothing to compare it with.

package progress

import (
	"context"
	"io"
	"log/slog"
	"testing"
	"time"

	"github.com/google/uuid"
)

type fakeRepo struct {
	attempts []RecentAttempt
	days     []time.Time
	words    int
	weakArgs []int
}

func (f *fakeRepo) AttemptsSince(context.Context, uuid.UUID, time.Time) ([]RecentAttempt, error) {
	return f.attempts, nil
}
func (f *fakeRepo) PracticeDays(context.Context, uuid.UUID, string, int) ([]time.Time, error) {
	return f.days, nil
}
func (f *fakeRepo) DistinctWords(context.Context, uuid.UUID) (int, error) {
	return f.words, nil
}
func (f *fakeRepo) WeakSounds(
	_ context.Context, _ uuid.UUID, minSamples, maxAccuracy, limit int,
) ([]WeakSound, error) {
	f.weakArgs = []int{minSamples, maxAccuracy, limit}
	return nil, nil
}
func (f *fakeRepo) RecentAttempts(context.Context, uuid.UUID, int) ([]RecentAttempt, error) {
	return f.attempts, nil
}

type fixedLearner struct {
	goal int
	tz   string
	err  error
}

func (l fixedLearner) DailyGoal(context.Context, uuid.UUID) (int, string, error) {
	return l.goal, l.tz, l.err
}

// A fixed clock, so "today" never moves under the test.
var testNow = time.Date(2026, 9, 13, 15, 0, 0, 0, time.UTC)

func newTestService(repo Repository, learner Learners) *Service {
	s := NewService(repo, learner, "UTC", slog.New(slog.NewTextHandler(io.Discard, nil)))
	s.now = func() time.Time { return testNow }
	return s
}

func day(offset int) time.Time {
	return time.Date(2026, 9, 13, 0, 0, 0, 0, time.UTC).AddDate(0, 0, -offset)
}

func TestTheWeekCountsDistinctWordsNotAttempts(t *testing.T) {
	// Saying one word ten times is one word learned. A bar that fills anyway would be
	// lying about a goal expressed in words.
	repo := &fakeRepo{attempts: []RecentAttempt{
		{Word: "think", Score: 90, At: testNow},
		{Word: "think", Score: 92, At: testNow.Add(-time.Hour)},
		{Word: "world", Score: 80, At: testNow.Add(-2 * time.Hour)},
	}}

	got, err := newTestService(repo, fixedLearner{goal: 10, tz: "UTC"}).
		Summary(context.Background(), uuid.New())
	if err != nil {
		t.Fatalf("summary: %v", err)
	}

	today := got.Week[len(got.Week)-1]
	if today.Words != 2 {
		t.Errorf("today = %d words, want 2 distinct", today.Words)
	}
	if today.Goal != 10 {
		t.Errorf("goal = %d, want 10", today.Goal)
	}
	if len(got.Week) != 7 {
		t.Errorf("week has %d days, want 7", len(got.Week))
	}
}

func TestASecondDayIsNotReportedAsAHugeImprovement(t *testing.T) {
	// With nothing in the previous week, a naive subtraction would claim +85.
	repo := &fakeRepo{attempts: []RecentAttempt{{Word: "think", Score: 85, At: testNow}}}

	got, _ := newTestService(repo, fixedLearner{goal: 10, tz: "UTC"}).
		Summary(context.Background(), uuid.New())

	if got.OverallScore != 85 {
		t.Errorf("overall = %d, want 85", got.OverallScore)
	}
	if got.ScoreDelta != 0 {
		t.Errorf("delta = %d, want 0 when there is nothing to compare with", got.ScoreDelta)
	}
}

func TestImprovementIsMeasuredAgainstThePreviousWeek(t *testing.T) {
	repo := &fakeRepo{attempts: []RecentAttempt{
		{Word: "think", Score: 90, At: testNow},                    // this week
		{Word: "think", Score: 70, At: testNow.AddDate(0, 0, -10)}, // the week before
	}}

	got, _ := newTestService(repo, fixedLearner{goal: 10, tz: "UTC"}).
		Summary(context.Background(), uuid.New())

	if got.ScoreDelta != 20 {
		t.Errorf("delta = %d, want 20", got.ScoreDelta)
	}
}

func TestStreakSurvivesADayThatHasNotFinishedYet(t *testing.T) {
	// Practised yesterday and the day before, nothing yet today. The streak is alive
	// until the day ends; killing it at midnight would punish somebody who practises
	// in the evening.
	repo := &fakeRepo{days: []time.Time{day(1), day(2), day(3)}}

	got, _ := newTestService(repo, fixedLearner{goal: 10, tz: "UTC"}).
		Summary(context.Background(), uuid.New())

	if got.StreakDays != 3 {
		t.Errorf("streak = %d, want 3", got.StreakDays)
	}
}

func TestABrokenStreakIsZeroButTheBestIsRemembered(t *testing.T) {
	// Four days in a row, then a gap of a week.
	repo := &fakeRepo{days: []time.Time{day(8), day(9), day(10), day(11)}}

	got, _ := newTestService(repo, fixedLearner{goal: 10, tz: "UTC"}).
		Summary(context.Background(), uuid.New())

	if got.StreakDays != 0 {
		t.Errorf("current streak = %d, want 0", got.StreakDays)
	}
	if got.BestStreak != 4 {
		t.Errorf("best streak = %d, want 4", got.BestStreak)
	}
}

func TestANewAccountGetsADashboardRatherThanAnError(t *testing.T) {
	// No preferences row yet, and nothing practised. This is somebody's first minute in
	// the app; it must not be an error screen.
	got, err := newTestService(&fakeRepo{}, fixedLearner{err: context.DeadlineExceeded}).
		Summary(context.Background(), uuid.New())
	if err != nil {
		t.Fatalf("summary: %v", err)
	}

	if got.OverallScore != 0 || got.StreakDays != 0 || got.WordsPracticed != 0 {
		t.Errorf("empty account = %+v, want zeros", got)
	}
	if len(got.Week) != 7 {
		t.Errorf("week has %d days, want 7 even when empty", len(got.Week))
	}
	if got.Week[0].Goal != fallbackGoal {
		t.Errorf("goal = %d, want the schema default %d", got.Week[0].Goal, fallbackGoal)
	}
}

func TestWeakSoundsAskForSoundsThatAreActuallyWeak(t *testing.T) {
	// Found by reading a real response: without the accuracy ceiling the query returns
	// the lowest five sounds whatever they scored, so a learner with little history was
	// shown θ at 100 and ŋ at 100 under a heading that says "weak sounds".
	repo := &fakeRepo{}
	if _, err := newTestService(repo, fixedLearner{goal: 10, tz: "UTC"}).
		Summary(context.Background(), uuid.New()); err != nil {
		t.Fatalf("summary: %v", err)
	}

	if len(repo.weakArgs) != 3 {
		t.Fatal("weak sounds were never requested")
	}
	if got := repo.weakArgs[1]; got != weakSoundMaxAccuracy {
		t.Errorf("max accuracy = %d, want %d", got, weakSoundMaxAccuracy)
	}
	if got := repo.weakArgs[0]; got != weakSoundMinSamples {
		t.Errorf("min samples = %d, want %d", got, weakSoundMinSamples)
	}
}
