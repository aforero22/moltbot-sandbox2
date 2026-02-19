FROM docker.io/cloudflare/sandbox:0.7.0

# Install Node.js 22, rclone, pnpm + OpenClaw in a single layer to reduce image size
# Cleanup apt cache and npm cache at the end to minimize layer size
ENV NODE_VERSION=22.13.1
RUN ARCH="$(dpkg --print-architecture)" \
    && case "${ARCH}" in \
         amd64) NODE_ARCH="x64" ;; \
         arm64) NODE_ARCH="arm64" ;; \
         *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
       esac \
    && apt-get update && apt-get install -y --no-install-recommends xz-utils ca-certificates rclone \
    && curl -fsSLk https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.xz \
    && npm install -g pnpm openclaw@2026.2.3 \
    && openclaw --version \
    && apt-get purge -y xz-utils && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /root/.npm

# Create OpenClaw directories in a single layer
RUN mkdir -p /root/.openclaw /root/clawd/skills

# Copy startup script + skills (combined for fewer layers)
# Build cache bust: 2026-02-19-v31-optimized
COPY start-openclaw.sh /usr/local/bin/start-openclaw.sh
RUN chmod +x /usr/local/bin/start-openclaw.sh
COPY skills/ /root/clawd/skills/

WORKDIR /root/clawd
EXPOSE 18789
