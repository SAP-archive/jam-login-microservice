FROM elixir:1.4.2

ENV PHOENIX_VERSION 1.2.1

RUN mkdir -p /app/current
WORKDIR /app/current

RUN adduser --disabled-password --gecos '' elixir && \
  chown -R elixir:elixir /app/current && \
  chmod g+w -R /app/current && \
  chown -R elixir:elixir /home/elixir && \
  wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 && chmod +x /usr/local/bin/dumb-init 

USER elixir
RUN mix local.hex --force && mix local.rebar --force && mix archive.install https://github.com/phoenixframework/archives/raw/master/phoenix_new-$PHOENIX_VERSION.ez 

ARG MIX_ENV
ARG TEST_REPORT

COPY phoenix/config /app/current/config
COPY phoenix/mix.* /app/current/
RUN rebar3 update && mix deps.get && mix deps.compile

COPY phoenix/lib /app/current/lib
COPY phoenix/priv /app/current/priv
COPY phoenix/test /app/current/test
COPY phoenix/web /app/current/web
COPY phoenix/coveralls.json /app/current/
COPY phoenix/*.pem /app/current/

USER root
RUN chown -R elixir:elixir /app/current 
USER elixir
RUN mix compile
  
EXPOSE 4000
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["mix", "phoenix.server"]