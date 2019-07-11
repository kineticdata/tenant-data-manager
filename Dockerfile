FROM ruby:2.5-alpine
RUN apk --no-cache add \
    alpine-sdk \
    bash \
    curl \
    git \
    openssl

# install helm
RUN curl -LO https://raw.githubusercontent.com/helm/helm/master/scripts/get \
        && bash get
# install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
        && chmod +x ./kubectl \
        && mv ./kubectl /usr/local/bin/kubectl

COPY . /app

WORKDIR /app
RUN bundle install && bundle clean

EXPOSE 4567

ENTRYPOINT ["puma"]
CMD ["config.ru", "-C", "puma.rb"]