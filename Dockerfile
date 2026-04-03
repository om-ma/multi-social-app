# Build stage
ARG ELIXIR_VERSION=1.16.0
ARG OTP_VERSION=26.2
ARG ALPINE_VERSION=3.20.0

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION} AS builder

# Install build dependencies
RUN apk add --no-cache build-base git nodejs npm

# Set build environment
ENV MIX_ENV=prod

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy dependency files
COPY mix.exs mix.lock ./
COPY config config

# Install dependencies
RUN mix deps.get --only $MIX_ENV

# Compile dependencies
RUN mix deps.compile

# Copy application code
COPY priv priv
COPY lib lib
COPY rel rel
COPY assets assets

# Compile application
RUN mix compile

# Build assets
RUN mix assets.deploy

# Build release
RUN mix release

# Runtime stage
FROM alpine:${ALPINE_VERSION} AS runner

# Install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs postgresql-client

ENV MIX_ENV=prod
ENV PHX_SERVER=true

WORKDIR /app

# Create non-root user
RUN addgroup -g 1000 elixir && \
    adduser -u 1000 -G elixir -s /bin/sh -D elixir

# Copy release from builder
COPY --from=builder --chown=elixir:elixir /app/_build/prod/rel/social_app ./

USER elixir

EXPOSE 4003

# Start server
CMD ["/app/bin/social_app", "start"]
