#!/usr/bin/env bash
P_USER=${P_USER:-"root"}
P_PASS=${P_PASS:-"rootroot"}
P_URL=${P_URL:-"http://portainer.com"}
P_PRUNE=${P_PRUNE:-"false"}

if [ -z ${1+x} ]; then
  echo "Parameter #1 missing: stack name "
  exit 1
fi
TARGET="$1"

if [ -z ${2+x} ]; then
  echo "Parameter #2 missing: update image tag"
  exit
fi
TARGET_VERSION="$2"

echo "Updating $TARGET to version $TARGET_VERSION"

echo "Logging in..."
P_TOKEN=$(curl -s -X POST -H "Content-Type: application/json;charset=UTF-8" -d "{\"username\":\"$P_USER\",\"password\":\"$P_PASS\"}" "$P_URL/api/auth")
if [[ $P_TOKEN = *"jwt"* ]]; then
  echo " ... success"
else
  echo "Result: failed to login"
  exit 1
fi
T=$(echo $P_TOKEN | awk -F '"' '{print $4}')
echo "Token: $T"

echo "Getting stacks..."
STACKS=$(curl -s -H "Authorization: Bearer $T" "$P_URL/api/stacks")

echo "/---" && echo $STACKS && echo "\\---"

found=0
stack=$(echo "$STACKS"|jq --arg TARGET "$TARGET" -jc '.[]| select(.Name == $TARGET)')

if [ -z "$stack" ];then
  echo "Result: Stack not found."
  exit 1
fi
sid="$(echo "$stack" |jq -j ".Id")"
eid="$(echo "$stack" |jq -j ".EndpointId")"
name=$(echo "$stack" |jq -j ".Name")

found=1
echo "Identified stack: $sid / $name"

echo "Get exist stack file"
STACKFILE=$(curl -s -H "Authorization: Bearer $T" $P_URL/api/stacks/$sid/file | jq .StackFileContent) 

existing_env_json="$(echo -n "$stack"|jq ".Env" -jc)"

echo "$existing_env_json"

echo "Update env tag"
# online js demo https://jqplay.org/
existing_env_json="$(echo -n "$existing_env_json" | jq -r --arg VERSION "$TARGET_VERSION" '. | map(if .name =="IMG_TAG" then (.value = $VERSION) else . end)' -jc)"
echo "$existing_env_json"

echo "\---------------------"
data_prefix="{\"StackFileContent\":"$STACKFILE","
data_suffix="\"Env\":"$existing_env_json",\"Prune\":$P_PRUNE}"
sep="'"
echo "/~~~~CONVERTED_JSON~~~~~~"
echo "$data_prefix$data_suffix" > json.tmp

echo "Updating stack..."
UPDATE=$(curl -s \
"$P_URL/api/stacks/$sid?endpointId=$eid" \
-X PUT \
-H "Authorization: Bearer $T" \
-H "Content-Type: application/json;charset=UTF-8" \
            -H 'Cache-Control: no-cache'  \
            --data-binary "@json.tmp"
        )
rm json.tmp
echo "Got response: $UPDATE"
if [ -z ${UPDATE+x} ]; then
  echo "Result: failure  to update"
  exit 1
else
  echo "Result: successfully updated"
  exit 0
fi


if [ "$found" == "1" ]; then
  echo "Result: found stack but failed to process"
  exit 1
else
  echo "Result: fail"
  exit 1
fi

