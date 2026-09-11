// Package template holds the wording of every transactional email.
//
// It lives apart from the providers so the outbox a developer reads and the SMTP message
// a customer receives are byte-for-byte the same text. Two copies of a subject line drift
// apart the first time somebody fixes a typo in one of them.
//
// Rendering takes the provider-neutral auth.EmailMessage and returns plain text. There is
// no HTML: a six-digit code needs none, and a plain-text message cannot be broken by a
// mail client that strips styles.
package template

import (
	"fmt"
	"strings"

	"github.com/samandar-hodiev/voca/backend/internal/auth"
)

// Subject returns the subject line for a template.
func Subject(t auth.EmailTemplate) string {
	switch t {
	case auth.TemplateSignupCode:
		return "Voca tasdiqlash kodi"
	case auth.TemplatePasswordResetCode:
		return "Voca parolni tiklash kodi"
	case auth.TemplateAccountExists:
		return "Voca: bu pochta allaqachon ro'yxatdan o'tgan"
	default:
		return "Voca"
	}
}

// Body returns the plain-text body for a message.
func Body(msg auth.EmailMessage) string {
	code := msg.Params["code"]

	switch msg.Template {
	case auth.TemplateSignupCode:
		return join(
			"Salom!",
			"",
			"Voca'da ro'yxatdan o'tishni yakunlash uchun tasdiqlash kodingiz:",
			"",
			"    "+code,
			"",
			"Kod 10 daqiqa amal qiladi.",
			"",
			"Agar bu siz bo'lmasangiz, xabarni e'tiborsiz qoldiring.",
		)
	case auth.TemplatePasswordResetCode:
		return join(
			"Salom!",
			"",
			"Voca parolingizni tiklash uchun kodingiz:",
			"",
			"    "+code,
			"",
			"Kod 10 daqiqa amal qiladi.",
			"",
			"Agar parolni tiklashni so'ramagan bo'lsangiz, hech narsa qilish shart emas.",
			"Parolingiz o'zgarmaydi.",
		)
	case auth.TemplateAccountExists:
		// No code and no sign-in link. Whoever typed the address may not own it, so this
		// message must not let them in, only tell the real owner what happened.
		return join(
			"Salom!",
			"",
			"Kimdir shu pochta bilan Voca'da yangi akkaunt ochmoqchi bo'ldi.",
			"Bu manzilda akkaunt allaqachon mavjud, shuning uchun yangisi yaratilmadi.",
			"",
			"Agar bu siz bo'lsangiz, ilovada \"Kirish\" tugmasidan foydalaning.",
			"Parolni eslay olmasangiz, \"Parolni unutdingizmi?\" orqali tiklang.",
			"",
			"Agar bu siz bo'lmasangiz, hech narsa qilish shart emas.",
			"Akkauntingiz o'zgarmadi va hech kim unga kira olmadi.",
		)
	default:
		return fmt.Sprintf("Voca: %s", code)
	}
}

func join(lines ...string) string { return strings.Join(lines, "\n") }
