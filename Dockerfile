FROM ruby:2.7-alpine
RUN apk --no-cache add \
  alpine-sdk \
  bash \
  curl \
  git \
  openssl
RUN gem install bundler:1.16.2

COPY . /app

WORKDIR /app
RUN bundle install

EXPOSE 4567

RUN adduser -D -h /home/kineticdata -u 55101 kineticdata kineticdata && \
  chown -R kineticdata:kineticdata /app && \
  chmod g+s /app && \
  chown -R kineticdata:kineticdata /usr/local/bundle && \
  chmod g+s /usr/local/bundle

USER kineticdata

ENTRYPOINT ["puma"]
CMD ["config.ru", "-C", "puma.rb"]
