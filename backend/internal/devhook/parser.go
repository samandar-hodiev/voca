// GitHub push payload parsing.
//
// The structs here are UNEXPORTED and mirror GitHub's JSON exactly. Go's visibility rules
// then make it impossible for any other package to depend on GitHub's field names, so the
// coupling cannot leak by accident (ARCHITECTURE.md 7.4).
package devhook

import (
	"encoding/json"
	"fmt"
	"strings"
)

type githubPushPayload struct {
	Ref        string `json:"ref"`
	Compare    string `json:"compare"`
	Repository struct {
		FullName string `json:"full_name"`
		Name     string `json:"name"`
	} `json:"repository"`
	Pusher struct {
		Name string `json:"name"`
	} `json:"pusher"`
	Sender struct {
		Login string `json:"login"`
	} `json:"sender"`
	Commits []struct {
		Message string `json:"message"`
		URL     string `json:"url"`
	} `json:"commits"`
	HeadCommit *struct {
		Message string `json:"message"`
		URL     string `json:"url"`
	} `json:"head_commit"`
}

// ParsePushEvent converts a raw GitHub push body into our normalized PushEvent.
func ParsePushEvent(body []byte) (PushEvent, error) {
	var p githubPushPayload
	if err := json.Unmarshal(body, &p); err != nil {
		return PushEvent{}, fmt.Errorf("devhook: malformed push payload: %w", err)
	}

	repo := p.Repository.FullName
	if repo == "" {
		repo = p.Repository.Name
	}
	if repo == "" {
		return PushEvent{}, fmt.Errorf("devhook: push payload has no repository")
	}

	ev := PushEvent{
		Repository:  repo,
		Branch:      branchFromRef(p.Ref),
		Pusher:      firstNonEmpty(p.Pusher.Name, p.Sender.Login, "unknown"),
		CommitCount: len(p.Commits),
		CompareURL:  p.Compare,
	}

	// head_commit is absent for branch deletions and for some tag pushes, so fall back to
	// the last entry in commits rather than assuming it is present.
	switch {
	case p.HeadCommit != nil:
		ev.LatestMessage = firstLine(p.HeadCommit.Message)
		ev.LatestURL = p.HeadCommit.URL
	case len(p.Commits) > 0:
		last := p.Commits[len(p.Commits)-1]
		ev.LatestMessage = firstLine(last.Message)
		ev.LatestURL = last.URL
	}

	return ev, nil
}

func branchFromRef(ref string) string {
	switch {
	case strings.HasPrefix(ref, "refs/heads/"):
		return strings.TrimPrefix(ref, "refs/heads/")
	case strings.HasPrefix(ref, "refs/tags/"):
		return "tag: " + strings.TrimPrefix(ref, "refs/tags/")
	case ref == "":
		return "unknown"
	default:
		return ref
	}
}

// firstLine keeps notifications short: a commit body can be arbitrarily long, and only
// the subject line is useful in a chat message.
func firstLine(s string) string {
	s = strings.TrimSpace(s)
	if i := strings.IndexByte(s, '\n'); i >= 0 {
		s = s[:i]
	}
	const max = 200
	if len(s) > max {
		return s[:max] + "..."
	}
	return s
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}
