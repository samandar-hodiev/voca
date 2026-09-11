# The signed-in app

What a person sees after signing in: four tabs over one still background, with a floating glass
navigation bar.

## Structure

```
StatefulShellRoute.indexedStack      lib/routing/app_router.dart
  AppShell                           lib/routing/app_shell.dart
    LiquidBackground                 one still background, painted once for every tab
    LiquidBottomBar                  Home, Practice, Progress, Profile (rightmost)
    branch 0  /home       HomePage
    branch 1  /practice   PracticePage
    branch 2  /progress   ProgressPage
    branch 3  /profile    ProfilePage
/settings                            opens over the shell, not inside a tab
```

Each tab is its own branch, so switching keeps its scroll position and the data it already
loaded. Tapping the open tab again returns it to its first screen.

There is one Scaffold, in the shell. Every tab renders into `TabScaffold`, which is a
scrolling column with a header, the page width limit, pull to refresh and clearance for the
floating bar. It is deliberately not a Scaffold: a Scaffold per tab would paint its own
background over the liquid field and hide it.

## Where glass is used, and where it is not

Glass marks the thing that floats. A page where everything is glass has no hierarchy and
turns into frosted noise, so it is used in exactly these places:

| Surface | Why |
|---|---|
| The navigation bar | It floats over scrolling content on every tab |
| The Home hero | The day's goal and the one thing to do next |
| The Profile identity card | Who is signed in |
| The word practice sheet | A modal that sits above the page |

Stat cards, lists and the Progress page are solid. Progress in particular is read rather
than acted on, and translucent panes would compete with the numbers it exists to show.

## Data: what is real and what is a mock

| Screen | Source |
|---|---|
| Greeting name, avatar, email, level, goal, daily goal | **real**, `GET /api/v1/users/me` |
| Home dashboard numbers | mock, `MockHomeRepository` |
| Practice word set | mock, `MockPracticeRepository` |
| Progress dashboard | mock, `MockProgressRepository` |
| Subscription | fixed "free plan" until payments exist |

Every mock sits behind the repository interface its feature's domain layer owns. Replacing
one with a real endpoint is a new implementation of that interface and a one-line change to
its provider in the feature's controller file. No widget changes.

Home sizes its daily goal from the person's own preference in the profile. If the profile
fails to load, the dashboard falls back to the default goal instead of failing with it.

`GET /api/v1/users/me` is the one backend addition. The session only carries an ID after a
restart, and nothing else exposed the name or picture, so the greeting and the Profile tab
had no other source. It returns the account, the profile and the preferences in one answer
because every screen that shows one of them shows the others.

## Motion

- Cards fade and lift in once, staggered by position (`Reveal`). Nothing loops.
- Tappable cards shrink slightly on press (`PressScale`).
- Progress rings and bars animate from zero the first time they appear.
- The bar is a capsule of clear glass, after the iOS tab bar. The selected destination
  gets a lighter, see-through glass pill that slides to a new one, stretching a little and settling
  with a slight overshoot.
- With reduced motion, all of it is skipped: content simply appears and the lens moves in
  one step.

The background is still. Nothing on these screens loops.

## Accessibility

- No state relies on colour alone. Pronunciation status is a label and an icon, score
  changes carry a sign and an arrow, and a met daily goal has a check mark.
- Charts, rings and stat cards announce a spoken summary instead of their parts.
- IPA symbols are announced as "θ tovushi" rather than spelled out character by character.
- Touch targets are at least 44 points; bar items are over 70 and list rows are 56.
- The active destination is marked three ways: the glass pill, a filled icon and a bold
  label.

## Signing out

Profile and Settings share one sign-out button, and it always asks first. A guest, who
has no mailbox, is then signed out, after a warning that their results stay behind.
Anyone else types their account's address, receives a six-digit code there, and is
signed out only once the server accepts it. The server checks both the address and the
code and revokes the session before the app clears anything. Closing the dialog or the
sheet at any point leaves the person signed in.

## Test anchors

Stable keys rather than labels, so a test does not break when a word is translated:

| Key | Meaning |
|---|---|
| `home-dashboard` | the signed-in person reached the product |
| `practice-page`, `progress-page`, `profile-page` | that tab is showing |
| `liquid-nav-0` to `liquid-nav-3` | a bar destination, by position |

## Not built in this task

- Recording and pronunciation scoring. The practice sheet shows the control disabled and
  says so, and `AttemptPhase` defines the state machine the assessment will drive.
- Subscriptions and payments.
- Recommendation logic. The recommended sets are fixed mock data.
