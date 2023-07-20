FROM ruby:3.2-slim-bullseye as base
RUN gem install bundler \
  && apt-get update \
  && apt-get upgrade --yes \
  && rm -rf /var/lib/apt/lists/* /var/lib/apt/archives/*.deb
RUN apt-get update && apt-get install -y sudo curl wget vim git zsh docker.io
RUN sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
ENV TZ='Europe/London'
ENV RUBYOPT='-W:no-deprecated -W:no-experimental'

# Here we build all our ruby gems, node modules etc, for copying into our slimmer image.
FROM base AS builder
WORKDIR /app
RUN apt-get update \
  && apt-get install --yes --no-install-recommends \
    build-essential libpq-dev libxml2-dev libxslt1-dev git \
  && rm -rf /var/lib/apt/lists/* /var/lib/apt/archives/*.deb
COPY Gemfile Gemfile.lock /app/
RUN bundle install --jobs 4 \
  && bundle binstubs --all --path /usr/local/bundle/bin

# Slim application image without development dependencies
FROM base AS app
WORKDIR /app
COPY . /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /node_modules /node_modules
COPY --from=builder Gemfile Gemfile.lock package.json yarn.lock .yarnrc /app/
CMD ["rails", "server", "-b", "0.0.0.0"]
EXPOSE 3009

# TODO: Sort out a production container with compiled assets etc.
