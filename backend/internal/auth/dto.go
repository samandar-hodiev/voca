// Request and response shapes for the auth API.
//
// Kept separate from domain models on purpose: the wire contract and the domain evolve
// independently. Field names are snake_case (ARCHITECTURE.md 11.1).
package auth

import "time"

type emailRequest struct {
	Email string `json:"email" binding:"required"`
}

type verifyCodeRequest struct {
	Email string `json:"email" binding:"required"`
	Code  string `json:"code" binding:"required"`
}

type registerRequest struct {
	Email     string  `json:"email" binding:"required"`
	Password  string  `json:"password" binding:"required"`
	FirstName string  `json:"first_name" binding:"required"`
	LastName  string  `json:"last_name" binding:"required"`
	Phone     *string `json:"phone"`
	AvatarURL *string `json:"avatar_url"`

	CEFRLevel      *string `json:"cefr_level"`
	LearningGoal   *string `json:"learning_goal"`
	DailyGoalWords *int    `json:"daily_goal_words"`
	Timezone       *string `json:"timezone"`
}

type loginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type guestRequest struct {
	CEFRLevel      *string `json:"cefr_level"`
	LearningGoal   *string `json:"learning_goal"`
	DailyGoalWords *int    `json:"daily_goal_words"`
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type resetPasswordRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type preferencesRequest struct {
	CEFRLevel      *string `json:"cefr_level"`
	LearningGoal   *string `json:"learning_goal"`
	DailyGoalWords *int    `json:"daily_goal_words"`
	Timezone       *string `json:"timezone"`
}

// userResponse is the public view of an account. It never carries a password hash, a
// token or an internal status field.
type userResponse struct {
	ID            string  `json:"id"`
	Email         *string `json:"email"`
	EmailVerified bool    `json:"email_verified"`
	Provider      string  `json:"provider"`
	IsGuest       bool    `json:"is_guest"`
}

type sessionResponse struct {
	User         userResponse `json:"user"`
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
	ExpiresIn    int          `json:"expires_in"`
}

type preferencesResponse struct {
	CEFRLevel             *string    `json:"cefr_level"`
	LearningGoal          *string    `json:"learning_goal"`
	DailyGoalWords        int        `json:"daily_goal_words"`
	UILanguage            string     `json:"ui_language"`
	LearningLanguage      string     `json:"learning_language"`
	Accent                string     `json:"accent"`
	Timezone              string     `json:"timezone"`
	OnboardingCompletedAt *time.Time `json:"onboarding_completed_at"`
}

func toUserResponse(u User) userResponse {
	return userResponse{
		ID:            u.ID.String(),
		Email:         u.Email,
		EmailVerified: u.EmailVerified,
		Provider:      string(u.Provider),
		IsGuest:       u.IsGuest(),
	}
}

func toSessionResponse(s Session) sessionResponse {
	return sessionResponse{
		User:         toUserResponse(s.User),
		AccessToken:  s.AccessToken,
		RefreshToken: s.RefreshToken,
		ExpiresIn:    s.ExpiresIn,
	}
}

func toPreferencesResponse(p Preferences) preferencesResponse {
	return preferencesResponse{
		CEFRLevel:             p.CEFRLevel,
		LearningGoal:          p.LearningGoal,
		DailyGoalWords:        p.DailyGoalWords,
		UILanguage:            p.UILanguage,
		LearningLanguage:      p.LearningLanguage,
		Accent:                p.Accent,
		Timezone:              p.Timezone,
		OnboardingCompletedAt: p.OnboardingCompletedAt,
	}
}
