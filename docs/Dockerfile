FROM ruby:2.7.4-alpine

ENV RUNTIME_DEPS ""
ENV BUILD_DEPS build-base curl-dev git

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

ENV APP_HOME /app/
WORKDIR $APP_HOME/

# Add user
ARG USER=docker
ARG UID=1000
ARG GID=1000

RUN addgroup -g $GID $USER
RUN adduser -D -u $UID -G $USER -h $APP_HOME/ $USER

# Install system dependencies
RUN apk add --no-cache $BUILD_DEPS $RUNTIME_DEPS

# Install Bundler
RUN gem install bundler -v 2.4.22

# Install Gem dependencies
ADD Gemfile $APP_HOME/
ADD Gemfile.lock $APP_HOME/

RUN bundle install

# Add application
ADD . $APP_HOME/

RUN chown -R $UID:$GID $APP_HOME/

# Change user
USER $USER

CMD ["jekyll", "serve", "--host", "0.0.0.0"]
