FROM ruby:3.2-slim-bullseye as base
RUN gem install bundler \
  && apt-get update \
  && apt-get upgrade --yes \
  && apt-get install --yes --no-install-recommends \
  libpq5 libxml2 libxslt1.1 libvips \
  curl gnupg graphviz nodejs \
  && echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
  && curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && apt-get update \
  && apt-get install --yes --no-install-recommends postgresql-client-15 \
  && rm -rf /var/lib/apt/lists/* /var/lib/apt/archives/*.deb
ENV TZ='Europe/London'
ENV RUBYOPT='-W:no-deprecated -W:no-experimental'

# Here we build all our ruby gems, node modules etc, for copying into our slimmer image.
FROM base AS builder
WORKDIR /app
RUN apt-get update \
  && apt-get install --yes --no-install-recommends \
  build-essential libpq-dev libxml2-dev libxslt1-dev git libyaml-dev \
  firefox-esr python2-dev \
  && rm -rf /var/lib/apt/lists/* /var/lib/apt/archives/*.deb
COPY Gemfile Gemfile.lock /app/
RUN bundle install --jobs 4 \
  && bundle binstubs --all --path /usr/local/bundle/bin \
  && bundle binstubs bundler --force

# Dev container image
FROM builder AS dev-container
RUN apt-get update \
  && apt-get install --yes --no-install-recommends sudo git vim zsh ssh curl less
RUN sh -c "$(curl -L https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
    -t robbyrussell \
    -p git -p docker-compose -p yarn \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    # -p https://github.com/marlonrichert/zsh-autocomplete \
    -p https://github.com/unixorn/fzf-zsh-plugin
RUN chsh -s $(which zsh) ${USER}

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
