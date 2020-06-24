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

ENTRYPOINT ["puma"]
CMD ["config.ru", "-C", "puma.rb"]
