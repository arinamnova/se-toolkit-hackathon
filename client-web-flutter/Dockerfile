ARG REGISTRY_PREFIX_GHCR
ARG REGISTRY_PREFIX_DOCKER_HUB

FROM ${REGISTRY_PREFIX_GHCR:-ghcr.io/}cirruslabs/flutter:3.41.2 AS builder

WORKDIR /app

# Clear entire pub cache to avoid corruption from cached partial files.
RUN rm -rf /root/.pub-cache

COPY pubspec.yaml ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

FROM ${REGISTRY_PREFIX_DOCKER_HUB:-}alpine:3.21
RUN mkdir -p /output
COPY --from=builder /app/build/web /flutter-web
CMD ["cp", "-r", "/flutter-web/.", "/output/"]
