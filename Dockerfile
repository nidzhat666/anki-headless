FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Runtime deps for the bundled Qt6 Anki + Xvfb headless display.
# We do NOT install the ubuntu `anki` package — it ships 2.1.15 from 2019,
# which is way too old for modern addons like ankimcp.
RUN apt-get update && apt-get install -y --no-install-recommends \
      xvfb dbus-x11 \
      libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
      libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-sync1 \
      libxcb-xfixes0 libxcb-xkb1 libxkbcommon-x11-0 libxkbfile1 \
      libnss3 libegl1 libgl1 libgssapi-krb5-2 libfontconfig1 \
      libdbus-1-3 libasound2t64 \
      ca-certificates curl unzip zstd \
      python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Anki 25.02.7 is the last release with a full bundled linux-qt6 tarball
# (~138MB). Later 25.07+ releases moved to a tiny launcher that downloads
# the runtime on first start — bad for ephemeral / headless containers.
ARG ANKI_VERSION=25.02.7
RUN curl -L -o /tmp/anki.tar.zst \
      https://github.com/ankitects/anki/releases/download/${ANKI_VERSION}/anki-${ANKI_VERSION}-linux-qt6.tar.zst \
 && mkdir -p /opt/anki \
 && tar --use-compress-program=unzstd -xf /tmp/anki.tar.zst -C /opt/anki --strip-components=1 \
 && rm /tmp/anki.tar.zst \
 && /opt/anki/install.sh

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
