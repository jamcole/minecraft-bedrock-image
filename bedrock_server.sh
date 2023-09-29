#!/bin/sh

set -e

echo "Updating base files in storage..."

if [ ! -L server.properties ]; then
  ln -s $(mktemp) server.properties
fi
if [ ! -L allowlist.json ]; then
  ln -s $(mktemp) allowlist.json
fi
if [ ! -L permissions.json ]; then
  ln -s $(mktemp) permissions.json
fi
if [ -d config.new ]; then
  mkdir -p "$(readlink config)"
  cp -R config.new/* "$(readlink config)"
fi
if [ -d resource_packs.new ]; then
  mkdir -p "$(readlink resource_packs)"
  cp -R resource_packs.new/* "$(readlink resource_packs)"
fi
if [ -d behavior_packs.new ]; then
  mkdir -p "$(readlink behavior_packs)"
  cp -R behavior_packs.new/* "$(readlink behavior_packs)"
fi
if [ -L valid_known_packs.json ] && [ ! -f "$(readlink valid_known_packs.json)" ]; then
  echo "[]" > "$(readlink valid_known_packs.json)"
fi
if [ -L worlds ] && [ ! -f "$(readlink worlds)" ]; then
  mkdir -p "$(readlink worlds)"
fi

echo "Updating 'server.properties' (* indicates a detected environment variable)..."

cp server.properties.new "$(readlink server.properties)"
cat server.properties.add >> "$(readlink server.properties)"

IFS=$'\n'
set +e
for i in $(grep -E '^[^#]+=' server.properties); do
  k=$(echo $i | cut -d '=' -f 1)
  v=$(echo $i | cut -d '=' -f 2)
  e=$(echo $k | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  
  o=$(set -o pipefail; export|grep -E "^export ${e}=" 2>/dev/null|cut -d '=' -f 2|xargs)
  
  if [ $? -eq 0 ]; then
    echo "  *$k=$o ($e)"
    sed -E -i "s/^$k=.+\$/$k=$o/" "$(readlink server.properties)"
  else
    echo "  $k=$v ($e)"
    # The initial cp makes it so we don't need to update this
    # sed -E -i "s/^$k=.+\$/$k=$v/" "$(readlink server.properties)"
  fi
done
set -e

echo "[" > "$(readlink allowlist.json)"
echo "Checking for player usernames in PLAYERS_ALLOWLIST to add to allowlist.json..."
if [ ! -z "${PLAYERS_ALLOWLIST}" ]; then
  IFS=$'\n'
  A_FIRST=true
  for u in $(echo ${PLAYERS_ALLOWLIST}|tr ',' '\n'|tr -d ' '); do
    if [ $A_FIRST = true ]; then
      A_FIRST=false
    else
      echo "," >> "$(readlink allowlist.json)"
    fi
    echo -n "{\"name\": \"$u\"}" >> "$(readlink allowlist.json)"
    echo "  Added Player By Username $u"
  done
fi
echo -e '\n]' >> "$(readlink allowlist.json)"

echo "[" > "$(readlink permissions.json)"
echo "Checking for player xuids in XUIDS_OPS to add to permissions.json..."
if [ ! -z "${XUIDS_OPS}" ]; then
  IFS=$'\n'
  P_FIRST=true
  for u in $(echo ${XUIDS_OPS}|tr ',' '\n'|tr -d ' '); do
    if [ $P_FIRST = true ]; then
      P_FIRST=false
    else
      echo "," >> "$(readlink permissions.json)"
    fi
    echo -n "{\"permission\": \"operator\",\"xuid\": \"$u\"}" >> "$(readlink permissions.json)"
    echo "  Added Player By XUID $u with operator permission"
  done
fi
echo "Checking for player xuids in XUIDS_MEMBERS to add to permissions.json..."
if [ ! -z "${XUIDS_MEMBERS}" ]; then
  IFS=$'\n'
  for u in $(echo ${XUIDS_MEMBERS}|tr ',' '\n'|tr -d ' '); do
    if [ $P_FIRST  = true ]; then
      P_FIRST=false
    else
      echo "," >> "$(readlink permissions.json)"
    fi
    echo -n "{\"permission\": \"member\",\"xuid\": \"$u\"}" >> "$(readlink permissions.json)"
    echo "  Added Player By XUID $u with member permission"
  done
fi
echo "Checking for player xuids in XUIDS_VISITORS to add to permissions.json..."
if [ ! -z "${XUIDS_VISITORS}" ]; then
  IFS=$'\n'
  for u in $(echo ${XUIDS_VISITORS}|tr ',' '\n'|tr -d ' '); do
    if [ $P_FIRST = true ]; then
      P_FIRST=false
    else
      echo "," >> "$(readlink permissions.json)"
    fi
    echo -n "{\"permission\": \"visitor\",\"xuid\": \"$u\"}" >> "$(readlink permissions.json)"
    echo "  Added Player By XUID $u with visitor permissions"
  done
fi
echo -e '\n]' >> "$(readlink permissions.json)"

echo Starting bedrock_server...
exec ./bedrock_server $@

