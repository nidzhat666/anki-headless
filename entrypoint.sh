#!/bin/sh
set -e

# Anki 25.x refuses to start without a UTF-8 locale.
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Clean stale Xvfb lock from prior runs (container restart leaves /tmp intact
# because it's the same writable layer until --force-recreate).
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

ANKI_DATA="/root/.local/share/Anki2"
ADDON_DIR="${ANKI_DATA}/addons21/anki_mcp_server"
ADDON_STAGED="/opt/ankimcp-addon"

# Make sure the addons21 dir exists (the bind-mounted profile dir may be empty
# on first boot), then drop the addon in if not already present. We do this
# every start so a wiped profile dir self-heals on next restart.
mkdir -p "${ANKI_DATA}/addons21"
if [ ! -f "${ADDON_DIR}/__init__.py" ]; then
  rm -rf "${ADDON_DIR}"
  cp -r "${ADDON_STAGED}" "${ADDON_DIR}"
fi

# Render ankimcp config from env vars on every start so the addon
# binds to 0.0.0.0 (reachable from hermes via docker DNS) instead of
# the default 127.0.0.1.
cat > "${ADDON_DIR}/meta.json" <<EOF
{
  "config": {
    "mode": "http",
    "http_port": ${ANKIMCP_HTTP_PORT:-3141},
    "http_host": "${ANKIMCP_HTTP_HOST:-0.0.0.0}",
    "http_path": "",
    "cors_origins": [],
    "cors_expose_headers": ["mcp-protocol-version"],
    "auto_connect_on_startup": true,
    "disabled_tools": [],
    "media_import_dir": "",
    "media_allowed_types": [],
    "media_allowed_hosts": []
  },
  "disabled": false
}
EOF

# Anki Desktop reads SYNC_USER / SYNC_PASSWORD for the sync handshake.
# Without SYNC_ENDPOINT it talks to AnkiWeb (the default), which is what
# we want: all clients (Mac, AnkiDroid, iOS, and this headless one) share
# the same collection through your AnkiWeb account.
export SYNC_USER="${ANKIWEB_EMAIL}"
export SYNC_PASSWORD="${ANKIWEB_PASSWORD}"

# Headless display for Qt
Xvfb :99 -screen 0 1024x768x16 -nolisten tcp &

# Wait for Xvfb to come up
sleep 1

# Pick / create a stable profile so Anki skips the profile picker dialog.
# Without -p, Anki shows a GUI picker that we can't dismiss in headless mode.
PROFILE_NAME="${ANKI_PROFILE:-Default}"
mkdir -p "${ANKI_DATA}/${PROFILE_NAME}"

# Run Anki against the chosen profile. The ankimcp addon boots an HTTP MCP
# server on $ANKIMCP_HTTP_PORT inside this process. Hermes reaches it via
# docker DNS (anki-headless:3141).
exec anki -p "${PROFILE_NAME}"
