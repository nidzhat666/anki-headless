FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      anki \
      xvfb \
      dbus-x11 \
      libxcb-cursor0 \
      libnss3 \
      libxkbcommon0 \
      libxcomposite1 \
      libxdamage1 \
      libxrandr2 \
      libasound2t64 \
      libegl1 \
      ca-certificates \
      curl \
      unzip \
      python3 \
      python3-pip \
    && rm -rf /var/lib/apt/lists/*

# AnkiMCP addon — download latest release and unpack into a staging dir.
# We *cannot* bake it under /root/.local/share/Anki2 because that path is
# meant to be bind-mounted from the host (the Anki user profile lives there
# too). A bind-mount would mask whatever we baked. Instead the entrypoint
# copies this staged copy into the real addons21 dir on every start.
RUN mkdir -p /opt/ankimcp-addon \
 && curl -L -o /tmp/anki_mcp_server.ankiaddon \
      https://github.com/ankimcp/anki-mcp-server-addon/releases/latest/download/anki_mcp_server.ankiaddon \
 && unzip -o /tmp/anki_mcp_server.ankiaddon -d /opt/ankimcp-addon \
 && rm /tmp/anki_mcp_server.ankiaddon

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3141
ENTRYPOINT ["/entrypoint.sh"]
