#!/usr/bin/env bash
#
# Create a new Codespace for this repo using the Codespaces dev container config,
# then wait until the full stack is healthy. Intended for programmatic / agentic
# spin-up — run it on your machine or in CI (NOT inside a Codespace).
#
# Requires: gh CLI authenticated with the `codespace` scope
#   (gh auth login / gh auth refresh -h github.com -s codespace).
#
# Keycloak is kept PRIVATE by the nginx TLS sidecar, so there are no manual
# post-create steps — backend, API, ROPC and interactive web login all work
# without exposing any public port.
#
# Usage:
#   .devcontainer/codespaces/new-codespace.sh [display-name]
# Env overrides:
#   REPO     (default: IQGeo/utils-project-template)
#   BRANCH   (default: current branch, else dev)
#   MACHINE  (default: premiumLinux  — 8-core/16GB; see `gh api .../machines`)
#   IDLE     (idle-timeout, default: 30m)
set -euo pipefail

REPO="${REPO:-IQGeo/utils-project-template}"
BRANCH="${BRANCH:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo dev)}"
MACHINE="${MACHINE:-premiumLinux}"
IDLE="${IDLE:-30m}"
CONFIG=".devcontainer/codespaces/devcontainer.json"
DISPLAY_NAME="${1:-}"

command -v gh >/dev/null || { echo "ERROR: gh CLI not found." >&2; exit 1; }

args=(--repo "$REPO" --branch "$BRANCH" --devcontainer-path "$CONFIG"
      --machine "$MACHINE" --idle-timeout "$IDLE")
[ -n "$DISPLAY_NAME" ] && args+=(--display-name "$DISPLAY_NAME")

echo "Creating codespace: repo=$REPO branch=$BRANCH machine=$MACHINE config=$CONFIG" >&2
CS="$(gh codespace create "${args[@]}")"
echo "Created codespace: $CS" >&2

echo "Waiting for the stack to become healthy (app + postgis)..." >&2
gh codespace ssh -c "$CS" -- \
  'until curl -sf http://localhost:8080 >/dev/null 2>&1 && pg_isready -h postgis -q 2>/dev/null; do sleep 5; done; echo READY' \
  >&2

echo "Codespace ready." >&2
# Print the codespace name on stdout so callers can capture it:
#   CS=$(.devcontainer/codespaces/new-codespace.sh agent-001)
echo "$CS"
