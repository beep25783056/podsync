# Build stage
FROM golang:1.20-alpine AS builder

WORKDIR /build

COPY . .

RUN make build

# Copy config file
COPY config.toml /build/config.toml

# Download yt-dlp
RUN wget -O /usr/bin/yt-dlp https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp && \
    chmod a+rwx /usr/bin/yt-dlp

# Final stage
# Alpine 3.21 will go EOL on 2026-11-01
FROM alpine:3.21

WORKDIR /app

RUN apk --no-cache add ca-certificates python3 py3-pip ffmpeg tzdata \
    libc6-compat && \
    ln -s /lib/libc.so.6 /usr/lib/libresolv.so.2

COPY --from=builder /usr/bin/yt-dlp /usr/local/bin/youtube-dl
COPY --from=builder /build/bin/podsync /app/podsync
COPY --from=builder /build/html/index.html /app/html/index.html
COPY --from=builder /build/config.toml /build/config.toml

ENTRYPOINT ["/app/podsync", "--config", "/build/config.toml"]
CMD ["--no-banner"]
