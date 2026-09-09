# GitHub push notifications in Telegram

Pushes to this repository are announced in Telegram by **GitPulse**, a separate service
living at `~/Desktop/gitpulse/gitpulse`. It is not part of the Voca backend.

## The chain

```
git push
  GitHub
  GitHub webhook delivery
  public tunnel URL
  localhost:8080
  gitpulse
  Telegram bot
```

Every link must be running at the moment of the push. If the laptop is asleep, the tunnel
is down, or gitpulse is not running, the delivery fails and no message arrives.

## Starting it

```
cd ~/Desktop/gitpulse/gitpulse && go run main.go   # listens on 8080
ngrok http 8080                                    # public URL
```

Check both:

```
curl http://localhost:8080/health
curl -H "ngrok-skip-browser-warning: true" https://<ngrok-url>/health
```

Both must answer `GitPulse is running`.

## GitHub webhook settings

Repository Settings, then Webhooks:

| Field | Value |
|-------|-------|
| Payload URL | `https://<current ngrok url>/webhook/github` |
| Content type | `application/json` |
| Secret | must equal `GITHUB_WEBHOOK_SECRET` in gitpulse's `.env` |
| Events | Just the push event |

## The recurring gotcha

On the ngrok free tier the public URL **changes every time ngrok restarts**. The webhook
in GitHub then points at a dead address and notifications stop silently.

After restarting ngrok, always copy the new URL into the webhook settings.

To diagnose a missing notification, open Settings, Webhooks, Recent Deliveries. A failed
delivery can be resent from there with Redeliver.

## Three mistakes that cost time here

**1. The Voca backend is not part of this flow.**
GitPulse is a separate program on port 8080. Voca's own backend on 8082 has nothing to do
with Telegram notifications. You do not need to start Voca to receive push messages.

**2. `go run ./cmd/server` does not exist.**
Voca's entrypoint is `cmd/api`. Use `make run` from `backend/`, or `go run ./cmd/api`.
Again: not needed for notifications at all.

**3. `ERR_NGROK_334: endpoint is already online` means ngrok is ALREADY RUNNING.**
It is not a failure to fix. Starting a second tunnel to the same port is unnecessary.
Check what is already up instead of starting another:

```
pgrep -fl ngrok
curl -s http://localhost:4040/api/tunnels | python3 -m json.tool | grep public_url
```

Do not reach for `--pooling-enabled` here. It exists to load balance two endpoints, which
is not the problem, and it risks disturbing tunnels belonging to other projects.

## Checking why a notification did not arrive

Work down the chain in this order. The first failing step is the cause.

```
pgrep -fl ngrok                                   # tunnel up?
curl -s http://localhost:8080/health              # gitpulse up?
curl -s http://localhost:4040/api/tunnels         # current public URL
```

Then compare that URL against the webhook in GitHub, and read GitHub's own verdict under
Settings, Webhooks, Recent Deliveries:

| GitHub says | Meaning |
|-------------|---------|
| `502 failed to connect to host` | The Payload URL is wrong or the tunnel is down |
| `401` | The tunnel and gitpulse are fine; the secret does not match |
| `200` | Delivered. If Telegram is still silent, the problem is the bot token or chat ID |

`last_response` on the webhook only updates when a new delivery happens. After correcting
the URL it keeps showing the old failure until the next push, which looks alarming and is
not.

## Making it permanent

Two ways to stop depending on a running laptop:

- Deploy gitpulse to a host. No tunnel, no laptop, and a stable URL.
- Replace it with a GitHub Actions workflow that posts to Telegram directly. GitHub runs
  it on its own machines, so no server and no tunnel are involved at all.

## Note on Voca's own webhook endpoint

The Voca backend also has `POST /api/v1/webhooks/github` (`internal/devhook`), which does
the same job on port 8082. Only one of the two should be wired to the repository at a
time. Currently gitpulse is the one in use.
