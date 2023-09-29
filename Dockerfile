FROM cgr.dev/chainguard/wolfi-base:latest AS builder

RUN apk add curl

RUN mkdir -p /root/download/extracted

WORKDIR /root/download

# We can't use the authorative url to check for new versions because they block non-browser User-Agents
# This service always seems to return the current version download url
ADD --chmod=644 https://mc-bds-helper.vercel.app/api/latest current-version.txt

# We don't actually download the prior url because we don't control that service - but it's an effective cache-buster
RUN mkdir -p /home/nonroot/Download && curl -s -L -A 'Edge/10000' 'https://www.minecraft.net/en-us/download/server/bedrock' |\
  grep -i 'href=' | grep -i linux | grep -Eo 'https?:[^\"]+.zip' | grep -vi preview | xargs -n 1 curl -L --no-clobber -o bedrock.zip

RUN unzip -d extracted bedrock.zip

FROM cgr.dev/chainguard/wolfi-base:latest AS runner

RUN \
  apk add libstdc++ libcurl-openssl4 curl

COPY --from=builder --chown=root:root /root/download/extracted/ /srv/app/

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

