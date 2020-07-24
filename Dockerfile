FROM ruby:2.5-alpine
RUN apk --no-cache add \
  alpine-sdk \
  bash \
  curl \
  git \
  openssl

COPY . /app

WORKDIR /app
RUN bundle install

EXPOSE 4567

RUN adduser -D -h /home/kineticdata -u 55101 kineticdata kineticdata && \
  chown -R kineticdata:kineticdata /app && \
  chmod g+s /app

USER kineticdata

ENTRYPOINT ["puma"]
CMD ["config.ru", "-C", "puma.rb"]
