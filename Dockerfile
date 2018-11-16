FROM ruby:2.4.5
MAINTAINER "Christoph Fabianek" christoph@ownyourdata.eu

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN echo "deb http://deb.debian.org/debian stretch-backports main" >> /etc/apt/sources.list && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		build-essential \
		libsodium-dev=1.0.16-2~bpo9+1 \
		libpq-dev \
		nodejs \
		postgresql-client && \
	rm -rf /var/lib/apt/lists/*

ENV RAILS_ROOT $WORKDIR
RUN mkdir -p $RAILS_ROOT/tmp/pids
COPY Gemfile /usr/src/app/

RUN bundle install
RUN gem install bundler

COPY . .

RUN  bundle update

CMD ["rails", "server", "-b", "0.0.0.0"]

EXPOSE 587 3000
