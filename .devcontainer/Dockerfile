FROM ruby:3.4.7

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libyaml-dev \
      postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /workspace
