// progress: business logic / use cases. Daily progress, streaks, improvement measurement, weak sounds.
//
// Responsibility: all business rules for this module, resource-ownership checks,
// orchestration across repositories and provider ports, and transaction boundaries.
//
// This is the module's PUBLIC SURFACE. Other modules may call this service interface and
// nothing else — never this module's repository, models, or tables (ARCHITECTURE.md 5.5).
//
// MUST NOT import: gin, pgx or sql types, or any vendor SDK.
//
// See ARCHITECTURE.md 14, 5.3, 5.5.

package progress

import (
	"context"
	"log/slog"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
)

// Learners is the consumer-owned port for the two facts this module needs about a person:
// how many words a day they signed up for, and which midnight is theirs.
//
// Declared here rather than importing the auth module, for the same reason SpeechProvider
// is declared by pronunciation: the dependency points inward, and the composition root is
// where the two meet (ARCHITECTURE.md 5.5, 7.1).
type Learners interface {
	DailyGoal(ctx context.Context, userID uuid.UUID) (goal int, timezone string, err error)
}

const (
	// weekDays is the width of the chart, and half the comparison window.
	weekDays = 7

	// fallbackGoal matches the schema default, used when a learner has no preferences
	// row yet. A brand-new account should see a dashboard, not an error.
	fallbackGoal = 10

	weakSoundMinSamples = 3

	// weakSoundMaxAccuracy is the bar below which a sound counts as weak. The same 80 the
	// analyzer uses, so the dashboard and the advice cannot disagree about which sounds
	// are a problem.
	weakSoundMaxAccuracy = 80

	weakSoundLimit = 5
	recentLimit    = 10
)

type Service struct {
	repo            Repository
	learners        Learners
	defaultTimezone string
	now             func() time.Time
	log             *slog.Logger
}

func NewService(
	repo Repository, learners Learners, defaultTimezone string, log *slog.Logger,
) *Service {
	return &Service{
		repo:            repo,
		learners:        learners,
		defaultTimezone: defaultTimezone,
		now:             time.Now,
		log:             log,
	}
}

// Summary builds the dashboard from what the learner has actually done.
//
// Everything here is derived, nothing is stored: there is no progress table to fall out of
// step with the attempts it summarises. If that becomes too slow it becomes a cached read,
// which is a change of one method rather than of the truth.
func (s *Service) Summary(ctx context.Context, userID uuid.UUID) (Summary, error) {
	goal, loc := s.learnerSettings(ctx, userID)

	now := s.now().In(loc)
	today := startOfDay(now)

	// Two weeks: one to draw, one to compare against.
	since := today.AddDate(0, 0, -(weekDays*2 - 1))

	attempts, err := s.repo.AttemptsSince(ctx, userID, since)
	if err != nil {
		return Summary{}, apperr.Internal(err)
	}

	week := s.buildWeek(attempts, today, goal, loc)
	overall, delta := s.scoreTrend(attempts, today, loc)

	words, err := s.repo.DistinctWords(ctx, userID)
	if err != nil {
		return Summary{}, apperr.Internal(err)
	}

	days, err := s.repo.PracticeDays(ctx, userID, loc.String(), 0)
	if err != nil {
		return Summary{}, apperr.Internal(err)
	}
	current, best := streaks(days, today)

	weak, err := s.repo.WeakSounds(ctx, userID,
		weakSoundMinSamples, weakSoundMaxAccuracy, weakSoundLimit)
	if err != nil {
		return Summary{}, apperr.Internal(err)
	}

	recent, err := s.repo.RecentAttempts(ctx, userID, recentLimit)
	if err != nil {
		return Summary{}, apperr.Internal(err)
	}

	return Summary{
		OverallScore:   overall,
		ScoreDelta:     delta,
		WordsPracticed: words,
		StreakDays:     current,
		BestStreak:     best,
		Week:           week,
		WeakSounds:     weak,
		Recent:         recent,
	}, nil
}

// learnerSettings resolves the daily goal and the timezone, never failing the dashboard
// over either. A missing preferences row is an ordinary state for a new account.
func (s *Service) learnerSettings(ctx context.Context, userID uuid.UUID) (int, *time.Location) {
	goal, timezone := fallbackGoal, s.defaultTimezone

	if s.learners != nil {
		g, tz, err := s.learners.DailyGoal(ctx, userID)
		switch {
		case err != nil:
			s.log.Warn("progress_preferences_unavailable",
				slog.String("user_id", userID.String()), slog.String("error", err.Error()))
		default:
			if g > 0 {
				goal = g
			}
			if strings.TrimSpace(tz) != "" {
				timezone = tz
			}
		}
	}

	loc, err := time.LoadLocation(timezone)
	if err != nil {
		loc = time.UTC
	}
	return goal, loc
}

// buildWeek counts DISTINCT words per day, oldest first.
//
// Distinct rather than attempts: a goal of ten words means ten words, and saying one word
// ten times should not fill the bar.
func (s *Service) buildWeek(
	attempts []RecentAttempt, today time.Time, goal int, loc *time.Location,
) []DailyCount {
	perDay := make(map[string]map[string]struct{}, weekDays)
	for _, a := range attempts {
		key := dayKey(a.At.In(loc))
		if perDay[key] == nil {
			perDay[key] = make(map[string]struct{})
		}
		perDay[key][strings.ToLower(strings.TrimSpace(a.Word))] = struct{}{}
	}

	week := make([]DailyCount, 0, weekDays)
	for i := weekDays - 1; i >= 0; i-- {
		day := today.AddDate(0, 0, -i)
		week = append(week, DailyCount{
			Day:   day,
			Words: len(perDay[dayKey(day)]),
			Goal:  goal,
		})
	}
	return week
}

// scoreTrend averages the last seven days and compares them with the seven before.
//
// Both halves are averaged over ATTEMPTS, not over days: a day with one lucky attempt
// should not weigh the same as a day with twenty.
func (s *Service) scoreTrend(
	attempts []RecentAttempt, today time.Time, loc *time.Location,
) (overall, delta int) {
	previousStart := today.AddDate(0, 0, -(weekDays*2 - 1))
	currentStart := today.AddDate(0, 0, -(weekDays - 1))

	var currentSum, previousSum, currentN, previousN int
	for _, a := range attempts {
		day := startOfDay(a.At.In(loc))
		switch {
		case !day.Before(currentStart):
			currentSum += a.Score
			currentN++
		case !day.Before(previousStart):
			previousSum += a.Score
			previousN++
		}
	}

	if currentN == 0 {
		return 0, 0
	}
	overall = currentSum / currentN
	if previousN == 0 {
		// Nothing to compare against is not an improvement of +overall, which is what a
		// naive subtraction would claim on somebody's second day.
		return overall, 0
	}
	return overall, overall - previousSum/previousN
}

// streaks returns the current run of consecutive practice days and the longest ever.
//
// A streak survives today being empty — it is still alive until the day ends — so the run
// may start at today or at yesterday. Anything older means it has been broken.
func streaks(days []time.Time, today time.Time) (current, best int) {
	if len(days) == 0 {
		return 0, 0
	}

	// Normalise to plain dates so comparisons cannot trip over clocks or zones.
	seen := make([]time.Time, 0, len(days))
	for _, d := range days {
		seen = append(seen, time.Date(d.Year(), d.Month(), d.Day(), 0, 0, 0, 0, time.UTC))
	}

	todayUTC := time.Date(today.Year(), today.Month(), today.Day(), 0, 0, 0, 0, time.UTC)

	run := 1
	best = 1
	for i := 1; i < len(seen); i++ {
		if seen[i-1].AddDate(0, 0, -1).Equal(seen[i]) {
			run++
		} else {
			run = 1
		}
		if run > best {
			best = run
		}
	}

	// The current run only counts if it reaches today or yesterday.
	if seen[0].Equal(todayUTC) || seen[0].Equal(todayUTC.AddDate(0, 0, -1)) {
		current = 1
		for i := 1; i < len(seen); i++ {
			if !seen[i-1].AddDate(0, 0, -1).Equal(seen[i]) {
				break
			}
			current++
		}
	}
	return current, best
}

func startOfDay(t time.Time) time.Time {
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, t.Location())
}

func dayKey(t time.Time) string { return t.Format("2006-01-02") }
