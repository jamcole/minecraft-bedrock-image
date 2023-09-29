FROM cgr.dev/chainguard/wolfi-base:latest AS builder

RUN apk add curl

RUN mkdir -p /root/download/bedrock /root/download/mc-monitor

WORKDIR /root/download

# We can't use the authorative url to check for new versions because they block non-browser User-Agents
# This service always seems to return the current version download url
ADD --chmod=644 https://mc-bds-helper.vercel.app/api/latest bedrock-version.txt

# We don't need to user the the prior url - but it's an effective cache-buster
#RUN curl -s -L -A 'Edge/10000' 'https://www.minecraft.net/en-us/download/server/bedrock' |\
#  grep -i 'href=' | grep -i linux | grep -Eo 'https?:[^\"]+.zip' | grep -vi preview | head -n 1 | xargs -n 1 curl -L --no-clobber -o bedrock.zip

RUN cat bedrock-version.txt | head -n 1 | xargs -n 1 curl -L --no-clobber -o bedrock.zip

RUN unzip -d bedrock bedrock.zip

#ADD --chmod=644 https://api.github.com/repos/itzg/mc-monitor/releases/latest mc-monitor-version.json

#RUN cat mc-monitor-version.json | grep -Eo 'https://[^"]+_linux_amd64.tar.gz' | head -n 1 | xargs -n 1 curl -L --no-clobber -o mc-monitor.tar.gz

ADD https://github.com/itzg/mc-monitor/releases/download/0.12.2/mc-monitor_0.12.2_linux_amd64.tar.gz mc-monitor.tar.gz

RUN tar -xzvf mc-monitor.tar.gz -C mc-monitor

FROM cgr.dev/chainguard/wolfi-base:latest AS runner

RUN \
  apk add libstdc++ curl

COPY --from=builder --chown=root:root /root/download/mc-monitor/mc-monitor /usr/local/bin/

COPY --from=builder --chown=root:root /root/download/bedrock/ /srv/app/

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

