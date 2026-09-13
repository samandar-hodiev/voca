// practice: business logic / use cases. Practice sessions and items, selection strategy, session completion.
//
// This is the module's PUBLIC SURFACE. Other modules may call this service interface and
// nothing else — never this module's repository, models, or tables (ARCHITECTURE.md 5.5).
//
// MUST NOT import: gin, pgx or sql types, or any vendor SDK.
//
// See ARCHITECTURE.md 13, 5.3, 5.5.

package practice

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/samandar-hodiev/voca/backend/internal/shared/apperr"
)

const (
	weekDays     = 7
	fallbackGoal = 10
	// fallbackLevel is where somebody who has not told us their level starts. The easiest
	// one: being handed words that are too hard is a worse first minute than words that
	// are too easy.
	fallbackLevel = "A1"
)

// Learners is the consumer-owned port for what this module needs to know about a person:
// their level, how many words a day they chose, and which midnight is theirs.
type Learners interface {
	Settings(ctx context.Context, userID uuid.UUID) (level string, dailyGoal int,
		timezone string, err error)
}

type Service struct {
	repo      Repository
	selector  Selector
	learners  Learners
	passScore float64

	defaultTimezone string
	now             func() time.Time
	log             *slog.Logger
}

func NewService(
	repo Repository, selector Selector, learners Learners,
	passScore float64, defaultTimezone string, log *slog.Logger,
) *Service {
	return &Service{
		repo: repo, selector: selector, learners: learners,
		passScore: passScore, defaultTimezone: defaultTimezone,
		now: time.Now, log: log,
	}
}

// Current returns the set the learner should be practising now, creating today's if they
// have earned it.
//
// The rule, and the trap it avoids. Tomorrow is locked until today's average clears the
// bar — that is the point of the feature. But if "only today's set is practisable" were
// taken literally, a set failed yesterday could never be finished, and the learner would
// be locked out permanently with no way back. So the current set is the OLDEST UNPASSED
// daily session: they carry on with what they owe. Only when everything is passed does a
// new day begin, and only once per day.
func (s *Service) Current(ctx context.Context, userID uuid.UUID) (Session, error) {
	level, goal, loc := s.settings(ctx, userID)
	today := startOfDay(s.now().In(loc))

	last, err := s.repo.LastDailySession(ctx, userID)
	switch {
	case err != nil && !errors.Is(err, ErrNotFound):
		return Session{}, apperr.Internal(err)

	case err == nil && !last.Passed(s.passScore):
		// Unfinished, or finished below the bar. Either way it is still theirs to clear.
		return s.withItems(ctx, last)

	case err == nil && !last.PracticeDay.Before(today):
		// Today is already done. Returned rather than refused, so the app can show the
		// set they completed instead of an empty screen.
		return s.withItems(ctx, last)
	}

	return s.startDay(ctx, userID, level, goal, today)
}

func (s *Service) startDay(
	ctx context.Context, userID uuid.UUID, level string, goal int, day time.Time,
) (Session, error) {
	passed, err := s.repo.PassedWordIDs(ctx, userID)
	if err != nil {
		return Session{}, apperr.Internal(err)
	}

	words, err := s.selector.Select(ctx, userID, Criteria{
		CEFRLevel: level, Count: goal, Day: day, Exclude: passed,
	})
	if err != nil {
		return Session{}, err
	}
	if len(words) == 0 {
		// Every word at this level has been passed. A real end state, and saying so beats
		// handing back an empty set that looks broken.
		return Session{}, apperr.New(apperr.CodeNotFound, http.StatusNotFound,
			"Bu daraja uchun yangi so‘z qolmadi. Keyingi darajaga o‘ting.")
	}

	session, err := s.repo.CreateDailySession(ctx, userID, day, words)
	if err != nil {
		return Session{}, apperr.Internal(err)
	}
	return s.withItems(ctx, session)
}

// Complete closes the session and works out whether it opened the next day.
//
// Items never attempted count as ZERO rather than being skipped. Averaging only what was
// attempted would let somebody practise their two easiest words, complete the day at 95,
// and unlock tomorrow having said eighteen words never.
func (s *Service) Complete(
	ctx context.Context, userID, sessionID uuid.UUID,
) (Session, error) {
	session, err := s.repo.SessionByID(ctx, sessionID)
	if errors.Is(err, ErrNotFound) {
		return Session{}, apperr.NotFound("Bunday mashq topilmadi.")
	}
	if err != nil {
		return Session{}, apperr.Internal(err)
	}
	if session.UserID != userID {
		// Not "forbidden": whose session it is, is not something a stranger should learn.
		return Session{}, apperr.NotFound("Bunday mashq topilmadi.")
	}
	if session.Status == StatusCompleted {
		return Session{}, apperr.Conflict("Bu mashq allaqachon yakunlangan.")
	}

	items, err := s.repo.Items(ctx, sessionID)
	if err != nil {
		return Session{}, apperr.Internal(err)
	}

	var total float64
	for _, it := range items {
		if it.BestScore != nil {
			total += *it.BestScore
		}
	}
	average := 0.0
	if len(items) > 0 {
		average = total / float64(len(items))
	}

	if err := s.repo.CompleteSession(ctx, sessionID, average); err != nil {
		return Session{}, apperr.Internal(err)
	}

	session.Status = StatusCompleted
	session.AverageScore = &average
	session.Items = items
	return session, nil
}

// Week is what the learner sees before opening anything: today, and the days after it.
//
// Only the first entry can ever be unlocked. Showing the rest greyed out is the whole
// point — the plan is visible, the shortcut is not.
func (s *Service) Week(ctx context.Context, userID uuid.UUID) ([]Day, error) {
	_, _, loc := s.settings(ctx, userID)
	today := startOfDay(s.now().In(loc))

	sessions, err := s.repo.RecentDailySessions(ctx, userID, weekDays*2)
	if err != nil {
		return nil, apperr.Internal(err)
	}

	byDay := make(map[string]Session, len(sessions))
	for _, x := range sessions {
		byDay[x.PracticeDay.Format("2006-01-02")] = x
	}

	// The current day is where the learner actually is: the oldest unpassed session, or
	// today if they are up to date.
	current := today
	for i := len(sessions) - 1; i >= 0; i-- {
		if !sessions[i].Passed(s.passScore) {
			current = startOfDay(sessions[i].PracticeDay)
			break
		}
	}

	out := make([]Day, 0, weekDays)
	for i := 0; i < weekDays; i++ {
		day := current.AddDate(0, 0, i)
		entry := Day{Day: day, Status: DayLocked}

		if session, ok := byDay[day.Format("2006-01-02")]; ok {
			entry.WordCount = session.ItemCount
			entry.CompletedCount = session.CompletedItemCount
			entry.AverageScore = session.AverageScore
			switch {
			case session.Passed(s.passScore):
				entry.Status = DayPassed
			case session.Status == StatusCompleted:
				entry.Status = DayFailed
			default:
				entry.Status = DayInProgress
			}
		} else if i == 0 {
			entry.Status = DayAvailable
		}

		entry.Unlocked = i == 0 && entry.Status != DayPassed
		out = append(out, entry)
	}
	return out, nil
}

// RecordResult is how the pronunciation module reports an attempt back. Nothing happens if
// the word is not in an open session: practising a word outside the daily set is allowed,
// it simply does not advance the day.
func (s *Service) RecordResult(
	ctx context.Context, userID uuid.UUID, wordText string,
	attemptID uuid.UUID, score float64,
) error {
	if err := s.repo.RecordItemResult(ctx, userID, wordText, attemptID,
		score, s.passScore); err != nil {
		return apperr.Internal(err)
	}
	return nil
}

// PassScore is the bar a day has to clear, exposed so the app can say what it is rather
// than hardcoding the same number in a second place.
func (s *Service) PassScore() float64 { return s.passScore }

func (s *Service) withItems(ctx context.Context, session Session) (Session, error) {
	items, err := s.repo.Items(ctx, session.ID)
	if err != nil {
		return Session{}, apperr.Internal(err)
	}
	session.Items = items
	return session, nil
}

func (s *Service) settings(
	ctx context.Context, userID uuid.UUID,
) (level string, goal int, loc *time.Location) {
	level, goal, timezone := fallbackLevel, fallbackGoal, s.defaultTimezone

	if s.learners != nil {
		l, g, tz, err := s.learners.Settings(ctx, userID)
		if err != nil {
			// A missing preferences row is ordinary for a new account, and no reason to
			// refuse them a first day of practice.
			s.log.Warn("practice_preferences_unavailable",
				slog.String("user_id", userID.String()), slog.String("error", err.Error()))
		} else {
			if strings.TrimSpace(l) != "" {
				level = strings.ToUpper(strings.TrimSpace(l))
			}
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
	return level, goal, loc
}

func startOfDay(t time.Time) time.Time {
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, t.Location())
}
