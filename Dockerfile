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

# AnkiMCP addon — download latest release and unpack into Anki addons dir.
# The .ankiaddon file is a ZIP, contents must live under addons21/<addon_id>/.
RUN mkdir -p /root/.local/share/Anki2/addons21/anki_mcp_server \
 && curl -L -o /tmp/anki_mcp_server.ankiaddon \
      https://github.com/ankimcp/anki-mcp-server-addon/releases/latest/download/anki_mcp_server.ankiaddon \
 && unzip -o /tmp/anki_mcp_server.ankiaddon \
      -d /root/.local/share/Anki2/addons21/anki_mcp_server \
 && rm /tmp/anki_mcp_server.ankiaddon

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3141
ENTRYPOINT ["/entrypoint.sh"]
