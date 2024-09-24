# syntax=docker/dockerfile:1.8
FROM cgr.dev/chainguard/wolfi-base:latest AS builder

RUN apk add curl

RUN mkdir -p /tmp/download/bedrock /tmp/download/mc-monitor

WORKDIR /tmp/download

COPY src/resources/bedrock-url.txt bedrock/
RUN cat bedrock/bedrock-url.txt && \
  cat bedrock/bedrock-url.txt | xargs -n 1 curl -L --no-clobber -o bedrock.zip && \
  unzip -d bedrock bedrock.zip

RUN curl -s -L "https://api.github.com/repos/itzg/mc-monitor/releases/latest" | grep -Eo 'https://[^"]+_linux_amd64.tar.gz' | head -n 1 > mc-monitor/mc-monitor-url.txt && \
  cat mc-monitor/mc-monitor-url.txt | xargs -n 1 curl -L --no-clobber -o mc-monitor.tar.gz && \
  tar -xzvf mc-monitor.tar.gz -C mc-monitor

FROM cgr.dev/chainguard/wolfi-base:latest AS runner

RUN apk add libstdc++ libcurl-openssl4

COPY --from=builder /tmp/download/mc-monitor/mc-monitor /usr/local/bin/

COPY --from=builder /tmp/download/bedrock/ /srv/app/

WORKDIR /srv/app

RUN \
  mv server.properties server.properties.new && \
  mv resource_packs resource_packs.new && \
  mv behavior_packs behavior_packs.new && \
  mv permissions.json permissions.json.new && \
  mv allowlist.json allowlist.json.new && \
  mv config config.new

RUN \
  ln -s /tmp/server.properties . && \
  ln -s /tmp/allowlist.json . && \
  ln -s /tmp/permissions.json . && \
  ln -s /tmp/config . && \
  ln -s /srv/data/resource_packs . && \
  ln -s /srv/data/behavior_packs . && \
  ln -s /srv/data/valid_known_packs.json . && \
  ln -s /srv/data/worlds .

COPY server.properties.add bedrock_server.sh .

USER nonroot

ENTRYPOINT ["./bedrock_server.sh"]

