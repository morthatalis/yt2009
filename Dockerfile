FROM node:18-bookworm-slim

# Install system packages
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
RUN pip3 install --no-cache-dir -U yt-dlp

# Install Arial font
RUN mkdir -p /tmp/fonts && \
    wget -O /tmp/fonts/webfonts.tar.gz \
    https://www.freedesktop.org/software/fontconfig/webfonts/webfonts.tar.gz && \
    tar -xzf /tmp/fonts/webfonts.tar.gz -C /tmp/fonts && \
    cabextract /tmp/fonts/msfonts/arial32.exe -d /tmp/fonts && \
    install -D -m644 /tmp/fonts/Arial.TTF /usr/share/fonts/truetype/Arial.TTF && \
    fc-cache -f && \
    rm -rf /tmp/fonts

# App dirs
RUN mkdir -p /yt2009 /data

WORKDIR /yt2009

# Copy package files
COPY package.json ./

# Install dependencies
RUN npm install

# Copy rest of app
COPY . .

# Create dirs
RUN mkdir -p cache temp assets back/cache_dir

# Symlinks
RUN ln -sf /data/androiddata.json back/androiddata.json && \
    ln -sf /data/tvdata.json back/tvdata.json && \
    ln -sf /data/config.json back/config.json && \
    ln -sf /data/mobilehelper_userdata.json back/mobilehelper_userdata.json && \
    ln -sf /data/comments.json back/cache_dir/comments.json && \
    ln -sf /data/accessdata back/accessdata

# Default config
RUN echo "{\"env\":\"prod\"}" > back/config.json

ENV PORT=10000
ENV YT2009_PORT=10000
ENV YT2009_IP=0.0.0.0
ENV YT2009_ENV=prod

EXPOSE 10000

RUN chmod +x docker-entrypoint.sh

ENTRYPOINT ["sh", "docker-entrypoint.sh"]

CMD ["node", "backend.js"]
