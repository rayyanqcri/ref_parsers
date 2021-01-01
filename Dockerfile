ARG tag=2.3.8-jessie
FROM ruby:$tag

LABEL maintainer="Hossam Hammady <github@hammady.net>"

ENV RACK_ENV test
ENV BUNDLE_GITHUB__HTTPS true
ENV BUNDLE_JOBS 4

WORKDIR /home
COPY / /home/
RUN bundle install

CMD ["bundle", "exec", "rake"]
