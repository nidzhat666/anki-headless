# anki-headless

Headless Anki Desktop in a container, with the
[ankimcp](https://github.com/ankimcp/anki-mcp-server-addon) addon baked in.
Runs full Anki inside `Xvfb` and exposes the collection over HTTP MCP on
port 3141, so AI agents (e.g. Hermes) can read and write your cards.

Pulls down your collection from a sync hub on startup (AnkiWeb by default,
or a self-hosted Anki sync server if you set `SYNC_ENDPOINT`).

## image

`ghcr.io/nidzhat666/anki-headless:latest`

Built by `.github/workflows/ghcr-build.yml` on every push to `main`.

## environment variables

| var | purpose |
|---|---|
| `ANKIWEB_EMAIL` | AnkiWeb email (or your sync-server username) |
| `ANKIWEB_PASSWORD` | AnkiWeb password (or your sync-server password) |
| `ANKIMCP_HTTP_HOST` | bind address for the MCP server (default `0.0.0.0`) |
| `ANKIMCP_HTTP_PORT` | port for the MCP server (default `3141`) |
| `SYNC_ENDPOINT` | optional, point at a self-hosted sync server instead of AnkiWeb |

## quick run

```sh
docker run --rm -it \
  -e ANKIWEB_EMAIL=you@example.com \
  -e ANKIWEB_PASSWORD=secret \
  -v $(pwd)/data:/root/.local/share/Anki2 \
  -p 3141:3141 \
  ghcr.io/nidzhat666/anki-headless:latest
```

Then connect any MCP client to `http://localhost:3141/`.

## what's inside

- Ubuntu 24.04
- Anki Desktop (apt package)
- Xvfb + Qt deps so Anki runs without a display
- `ankimcp` addon downloaded from upstream releases at build time
- entrypoint that renders the addon's `meta.json` from env vars, starts
  `Xvfb :99`, then `exec anki`
