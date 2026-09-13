// The lock, which is the whole feature.
//
// Two failures matter more than the rest. Letting somebody through who has not earned the
// day makes the lock decorative. And locking somebody out with no way back — the trap a
// strict "only today's set" rule falls into — turns a motivator into a dead end. Both are
// pinned here.

package practice

import (
	"context"
	"io"
	"log/slog"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/word"
)

var today = time.Date(2026, 9, 13, 10, 0, 0, 0, time.UTC)

type fakeRepo struct {
	last      *Session
	items     []Item
	created   []Session
	completed map[uuid.UUID]float64
	recent    []Session
	passedIDs []uuid.UUID
}

func (f *fakeRepo) LastDailySession(context.Context, uuid.UUID) (Session, error) {
	if f.last == nil {
		return Session{}, ErrNotFound
	}
	return *f.last, nil
}
func (f *fakeRepo) SessionByID(_ context.Context, id uuid.UUID) (Session, error) {
	if f.last != nil && f.last.ID == id {
		return *f.last, nil
	}
	return Session{}, ErrNotFound
}
func (f *fakeRepo) Items(context.Context, uuid.UUID) ([]Item, error) { return f.items, nil }
func (f *fakeRepo) CreateDailySession(
	_ context.Context, userID uuid.UUID, day time.Time, words []word.Word,
) (Session, error) {
	s := Session{ID: uuid.New(), UserID: userID, Type: TypeDaily,
		Status: StatusInProgress, ItemCount: len(words), PracticeDay: day}
	f.created = append(f.created, s)
	return s, nil
}
func (f *fakeRepo) PassedWordIDs(context.Context, uuid.UUID) ([]uuid.UUID, error) {
	return f.passedIDs, nil
}
func (f *fakeRepo) CompleteSession(_ context.Context, id uuid.UUID, avg float64) error {
	if f.completed == nil {
		f.completed = map[uuid.UUID]float64{}
	}
	f.completed[id] = avg
	return nil
}
func (f *fakeRepo) RecordItemResult(context.Context, uuid.UUID, string, uuid.UUID,
	float64, float64) error {
	return nil
}
func (f *fakeRepo) RecentDailySessions(context.Context, uuid.UUID, int) ([]Session, error) {
	return f.recent, nil
}

type fakeSelector struct{ n int }

func (f fakeSelector) Select(context.Context, uuid.UUID, Criteria) ([]word.Word, error) {
	out := make([]word.Word, f.n)
	for i := range out {
		out[i] = word.Word{ID: uuid.New(), Text: "word", CEFRLevel: "A1"}
	}
	return out, nil
}

type fakeLearners struct {
	level string
	goal  int
}

func (f fakeLearners) Settings(context.Context, uuid.UUID) (string, int, string, error) {
	return f.level, f.goal, "UTC", nil
}

func newService(repo Repository, sel Selector) *Service {
	s := NewService(repo, sel, fakeLearners{level: "A1", goal: 20}, 80, "UTC",
		slog.New(slog.NewTextHandler(io.Discard, nil)))
	s.now = func() time.Time { return today }
	return s
}

func score(v float64) *float64 { return &v }

func TestANewLearnerGetsDayOne(t *testing.T) {
	repo := &fakeRepo{}
	got, err := newService(repo, fakeSelector{n: 20}).Current(context.Background(), uuid.New())
	if err != nil {
		t.Fatalf("current: %v", err)
	}
	if len(repo.created) != 1 {
		t.Fatalf("created %d sessions, want 1", len(repo.created))
	}
	if got.ItemCount != 20 {
		t.Errorf("item count = %d, want the learner's daily goal of 20", got.ItemCount)
	}
}

func TestAFailedDayIsStillTheDayYouOwe(t *testing.T) {
	// The trap: if only "today's" set were practisable, yesterday's failed set could never
	// be cleared and the learner would be locked out for good.
	yesterday := Session{ID: uuid.New(), Type: TypeDaily, Status: StatusCompleted,
		AverageScore: score(65), PracticeDay: today.AddDate(0, 0, -1)}
	repo := &fakeRepo{last: &yesterday}

	got, err := newService(repo, fakeSelector{n: 20}).Current(context.Background(), uuid.New())
	if err != nil {
		t.Fatalf("current: %v", err)
	}
	if got.ID != yesterday.ID {
		t.Error("a new day was started before the previous one was passed")
	}
	if len(repo.created) != 0 {
		t.Errorf("created %d sessions, want none", len(repo.created))
	}
}

func TestPassingYesterdayOpensToday(t *testing.T) {
	yesterday := Session{ID: uuid.New(), Type: TypeDaily, Status: StatusCompleted,
		AverageScore: score(85), PracticeDay: today.AddDate(0, 0, -1)}
	repo := &fakeRepo{last: &yesterday}

	if _, err := newService(repo, fakeSelector{n: 20}).
		Current(context.Background(), uuid.New()); err != nil {
		t.Fatalf("current: %v", err)
	}
	if len(repo.created) != 1 {
		t.Fatalf("created %d sessions, want 1", len(repo.created))
	}
	if !repo.created[0].PracticeDay.Equal(today.Truncate(24*time.Hour)) &&
		repo.created[0].PracticeDay.Day() != today.Day() {
		t.Errorf("new session is for %v, want today", repo.created[0].PracticeDay)
	}
}

func TestTodayIsNotHandedOutTwice(t *testing.T) {
	done := Session{ID: uuid.New(), Type: TypeDaily, Status: StatusCompleted,
		AverageScore: score(90), PracticeDay: today}
	repo := &fakeRepo{last: &done}

	got, err := newService(repo, fakeSelector{n: 20}).Current(context.Background(), uuid.New())
	if err != nil {
		t.Fatalf("current: %v", err)
	}
	if len(repo.created) != 0 {
		t.Error("a second session was created for a day already finished")
	}
	if got.ID != done.ID {
		t.Error("the finished session was not returned")
	}
}

func TestWordsNeverSaidCountAsZero(t *testing.T) {
	// Otherwise: practise the two easiest words, average 95, unlock tomorrow having said
	// eighteen words never.
	session := Session{ID: uuid.New(), Type: TypeDaily, Status: StatusInProgress,
		ItemCount: 4, PracticeDay: today}
	repo := &fakeRepo{last: &session, items: []Item{
		{BestScore: score(100)}, {BestScore: score(100)}, {}, {},
	}}

	got, err := newService(repo, fakeSelector{n: 4}).
		Complete(context.Background(), session.UserID, session.ID)
	if err != nil {
		t.Fatalf("complete: %v", err)
	}
	if *got.AverageScore != 50 {
		t.Errorf("average = %v, want 50 — unattempted words are zeros", *got.AverageScore)
	}
	if got.Passed(80) {
		t.Error("a half-finished day unlocked the next one")
	}
}

func TestCompletingTwiceIsAConflict(t *testing.T) {
	session := Session{ID: uuid.New(), Type: TypeDaily, Status: StatusCompleted,
		AverageScore: score(90), PracticeDay: today}
	repo := &fakeRepo{last: &session}

	_, err := newService(repo, fakeSelector{n: 4}).
		Complete(context.Background(), session.UserID, session.ID)
	if err == nil {
		t.Fatal("completing an already finished session was allowed")
	}
}

func TestOnlyTheFirstDayOfTheWeekIsUnlocked(t *testing.T) {
	repo := &fakeRepo{}
	days, err := newService(repo, fakeSelector{n: 20}).Week(context.Background(), uuid.New())
	if err != nil {
		t.Fatalf("week: %v", err)
	}
	if len(days) != weekDays {
		t.Fatalf("week has %d days, want %d", len(days), weekDays)
	}
	if !days[0].Unlocked {
		t.Error("the first day is locked; a learner could never start")
	}
	for i, d := range days[1:] {
		if d.Unlocked {
			t.Errorf("day %d is unlocked; the plan is visible, the shortcut is not", i+2)
		}
	}
}
