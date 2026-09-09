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

## Making it permanent

Two ways to stop depending on a running laptop:

- Deploy gitpulse to a host. No tunnel, no laptop, and a stable URL.
- Replace it with a GitHub Actions workflow that posts to Telegram directly. GitHub runs
  it on its own machines, so no server and no tunnel are involved at all.

## Note on Voca's own webhook endpoint

The Voca backend also has `POST /api/v1/webhooks/github` (`internal/devhook`), which does
the same job on port 8082. Only one of the two should be wired to the repository at a
time. Currently gitpulse is the one in use.
