# Build stage: install latest stable Flutter on Ubuntu to match Dart SDK constraints
FROM ubuntu:22.04 AS build

WORKDIR /app

# Install required packages for Flutter and web build
RUN apt-get update && apt-get install -y --no-install-recommends \
  git \
  curl \
  unzip \
  xz-utils \
  zip \
  wget \
  ca-certificates \
  libglu1-mesa \
  openjdk-11-jre-headless \
  && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK (latest stable branch) into /usr/local/flutter
RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git /usr/local/flutter \
  && /usr/local/flutter/bin/flutter --version

ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
# Prevent tar from trying to restore ownership when extracting archives (fixes rootless/docker tar errors)
ENV TAR_OPTIONS="--no-same-owner"

# Cache pubspec dependencies before copying full source
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the project and build the web release
COPY . .
RUN flutter build web --release

# Runtime stage: serve built web app with nginx
FROM nginx:alpine

# Remove default nginx content and copy built web output
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
