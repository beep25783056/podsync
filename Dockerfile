# Step 1: Build Podsync using Go 1.23
FROM golang:1.23-alpine AS builder

# Set the working directory inside the container
WORKDIR /build

# Copy all files from the current directory to the container
COPY . .

# Download dependencies
RUN go mod tidy

# Build the Podsync binary from the source code
RUN go build -o podsync ./cmd/podsync

# Step 2: Create the runtime image
FROM alpine:3.21

# Set the working directory inside the container
WORKDIR /app

# Install required packages (ffmpeg for audio/video processing)
RUN apk --no-cache add ca-certificates ffmpeg tzdata python3 py3-pip libc6-compat

# Copy the Podsync binary from the build stage
COPY --from=builder /build/podsync /app/podsync

# Copy your Podsync config file into the container
COPY config.toml /app/config.toml

# Copy yt-dlp to download YouTube videos
RUN wget -O /usr/local/bin/yt-dlp https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
    && chmod a+rx /usr/local/bin/yt-dlp

# Run Podsync with the provided config
ENTRYPOINT ["/app/podsync", "--config", "/app/config.toml"]
