# Build stage
ARG ELIXIR_VERSION=1.16.3
ARG OTP_VERSION=26.2.5.3
ARG DEBIAN_VERSION=bullseye-20260316-slim

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION} AS builder

# Install build dependencies
RUN apt-get update -y && \
    apt-get install -y build-essential git nodejs npm && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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
FROM debian:${DEBIAN_VERSION} AS runner

# Install runtime dependencies
RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8

ENV MIX_ENV=prod
ENV PHX_SERVER=true

WORKDIR /app

# Create non-root user
RUN groupadd -g 1000 elixir && \
    useradd -u 1000 -g elixir -s /bin/sh -m elixir

# Copy release from builder
COPY --from=builder --chown=elixir:elixir /app/_build/prod/rel/social_app ./

USER elixir

EXPOSE 4003

# Start server
CMD ["/app/bin/social_app", "start"]
