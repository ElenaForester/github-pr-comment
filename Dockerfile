FROM ruby:2.6.5-alpine

RUN apk add --update --upgrade --no-cache bash
RUN gem install bundler:2.1.4
RUN bundle --version
# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

ADD assets /opt/resource
RUN chmod +x /opt/resource/*

ENTRYPOINT ["/bin/bash"]
