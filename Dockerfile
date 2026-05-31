FROM node:18-bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    imagemagick \
    cabextract \
    wget \
    fontconfig \
    python3 \
    python3-pip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install yt-dlp
RUN pip3 install --no-cache-dir --break-system-packages -U yt-dlp

# Install Arial font
RUN mkdir -p /tmp/fonts && \
    wget -O /tmp/fonts/webfonts.tar.gz \
    https://www.freedesktop.org/software/fontconfig/webfonts/webfonts.tar.gz && \
    tar -xzf /tmp/fonts/webfonts.tar.gz -C /tmp/fonts && \
    cabextract /tmp/fonts/msfonts/arial32.exe -d /tmp/fonts && \
    install -D -m644 /tmp/fonts/Arial.TTF /usr/share/fonts/truetype/Arial.TTF && \
    fc-cache -f && \
    rm -rf /tmp/fonts

# Create app/data dirs
RUN mkdir -p /yt2009 /data && \
    chmod -R 777 /data

WORKDIR /yt2009

# Copy package files first for better caching
COPY package*.json ./

# Install npm deps
RUN npm install

# Copy project
COPY . .

# Create runtime dirs
RUN mkdir -p \
    cache \
    temp \
    assets \
    back/cache_dir

# Symlinks
RUN ln -sf /data/androiddata.json back/androiddata.json && \
    ln -sf /data/tvdata.json back/tvdata.json && \
    ln -sf /data/config.json back/config.json && \
    ln -sf /data/mobilehelper_userdata.json back/mobilehelper_userdata.json && \
    ln -sf /data/comments.json back/cache_dir/comments.json && \
    ln -sf /data/accessdata back/accessdata && \
    ln -sf /data/cert.crt cert.crt && \
    ln -sf /data/cert.key cert.key

# Default config
RUN echo "{\"env\":\"dev\"}" > back/config.json && \
    node post_config_setup.js || true

# Render uses dynamic PORT
ENV PORT=10000

# YT2009 config
ENV YT2009_PORT=10000 \
    YT2009_ENV=prod \
    YT2009_IP=0.0.0.0 \
    YT2009_SSL=false \
    YT2009_SSLPORT=443 \
    YT2009_SSLPATH=/yt2009/cert.crt \
    YT2009_SSLKEY=/yt2009/cert.key \
    YT2009_AUTO_MAINTAIN=true \
    YT2009_MAINTAIN_MAX_SIZE=10 \
    YT2009_MAINTAIN_MAX_CACHE_SIZE=15 \
    YT2009_FALLBACK=false \
    YT2009_DISABLEMASTER=false \
    YT2009_RATELIMIT=false \
    YT2009_AC=false \
    YT2009_GDATA_AUTH=false

EXPOSE 10000

# Ensure startup script executable
RUN chmod +x docker-entrypoint.sh

ENTRYPOINT ["sh", "docker-entrypoint.sh"]

CMD ["node", "backend.js"]
