# ADR-017: Transactional email is sent from a domain Voca owns

- **Status:** Accepted
- **Date:** 2026-09-11
- **Related:** [ADR-006](ADR-006-ports-and-adapters.md)

## Context

Signup and password reset both send a six-digit code. Every person who signs up types
their own address, and each one has to receive their own code at that address. With ten
thousand learners that is ten thousand different recipients.

Two facts shape how this can be done.

**The first is that mail providers do not let anybody send to arbitrary recipients until
the sender proves they control the sending domain.** This is the anti-spam rule that the
whole email system rests on, and it is not a tier or a price. On a free plan with no
verified domain:

- Resend delivers only to the address that owns the Resend account, from its shared
  `onboarding@resend.dev` sender. This was confirmed against a live key rather than read
  from documentation. Sending to the account owner succeeded; sending to any other
  recipient was refused with:

  > You can only send testing emails to your own email address. To send emails to other
  > recipients, please verify a domain at resend.com/domains, and change the `from`
  > address to an email using this domain.

  The refusal arrives as HTTP 403 before any delivery is attempted, so a project
  configured this way appears to work for whoever owns the account and fails for
  everybody else.
- Brevo delivers to anyone, but only from a verified sender ADDRESS, which in practice
  means sending as `something@gmail.com` through Brevo's servers. Gmail's own DMARC policy
  then fails to align, and a large share of those messages land in spam or are rejected
  outright.

Neither is a foundation for a product. The first cannot reach a customer at all; the
second reaches them unreliably and damages the sender's reputation while it does.

**The second is that outbound SMTP is unreachable from the development network.** Ports
587, 465 and 2525 were tested against Gmail, Brevo, SendGrid and Mailgun and every one
timed out, while 22 and 443 were open. That is an ISP-level block and no SMTP
configuration can work around it.

## Decision

Transactional email is delivered over **HTTPS through a mail API**, from a **domain Voca
owns and has verified**, with SPF, DKIM and DMARC records published for that domain.

The provider stays behind the existing `EmailProvider` port, so it is an adapter choice
and not an architectural one. Four adapters exist: Brevo and Resend over HTTPS, SMTP for
environments where the ports are open, and a local outbox for development.

Sending address: `no-reply@<voca-domain>`, with a display name of `Voca`.

## Consequences

**A domain is a prerequisite for launch, not a nice-to-have.** Until one is verified, the
product can be developed and tested but cannot send a code to a stranger. This is the
single item standing between the current build and a real signup by a real person.

**Deliverability becomes an operational concern.** SPF, DKIM and DMARC are what keep the
messages out of spam. A new domain also has no sending reputation, so volume should climb
over the first weeks rather than starting at full rate.

**Cost is small and fixed.** A domain is roughly ten dollars a year. Provider free tiers
cover early volume: Resend allows 3,000 messages a month, Brevo 300 a day. At ten thousand
signups a month the cost is still in the tens of dollars.

**Bounces and complaints have to be handled.** Repeatedly mailing an address that does not
exist is what gets a sender blocked, so hard bounces should eventually suppress an address
rather than being retried.

## Alternatives considered

**Send from a personal Gmail through Brevo.** Works today with no domain, but fails DMARC
alignment for `gmail.com`, so delivery is unreliable and the messages look like spoofing.
Rejected: an unreliable verification code is worse than an obviously missing one, because
the person blames the product rather than the setup.

**Send codes over Telegram.** Works on this network and reaches the phone in seconds, but
it is not the product's flow: a learner types an email address and expects the code there.
Implemented as a development channel, then removed once it became clear it was being
mistaken for the real path.

**Wait for the ISP block to lift and use SMTP.** Not a decision anybody controls, and the
same domain verification would still be required.
