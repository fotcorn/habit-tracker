#!/bin/bash
set -euo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" != "true" ] && exit 0

if [ -z "${HTTPS_PROXY:-}" ]; then
  echo "No HTTPS_PROXY set, skipping proxy configuration"
  exit 0
fi

# Parse proxy URL: http://user:pass@host:port
PROXY="${HTTPS_PROXY#http://}"
PROXY="${PROXY#https://}"

if [[ "$PROXY" == *@* ]]; then
  PROXY_AUTH="${PROXY%@*}"
  PROXY_HOST_PORT="${PROXY##*@}"
  PROXY_USER="${PROXY_AUTH%%:*}"
  PROXY_PASS="${PROXY_AUTH#*:}"
else
  PROXY_HOST_PORT="$PROXY"
  PROXY_USER=""
  PROXY_PASS=""
fi

PROXY_HOST="${PROXY_HOST_PORT%%:*}"
PROXY_PORT="${PROXY_HOST_PORT##*:}"
PROXY_PORT="${PROXY_PORT%%/*}"

mkdir -p ~/.gradle

# Gradle properties (for Gradle daemon)
cat > ~/.gradle/gradle.properties <<EOF
systemProp.http.proxyHost=$PROXY_HOST
systemProp.http.proxyPort=$PROXY_PORT
systemProp.https.proxyHost=$PROXY_HOST
systemProp.https.proxyPort=$PROXY_PORT
EOF

if [ -n "$PROXY_USER" ]; then
  cat >> ~/.gradle/gradle.properties <<EOF
systemProp.http.proxyUser=$PROXY_USER
systemProp.http.proxyPassword=$PROXY_PASS
systemProp.https.proxyUser=$PROXY_USER
systemProp.https.proxyPassword=$PROXY_PASS
EOF
fi

# GRADLE_OPTS for wrapper (runs before gradle.properties is read)
OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT -Djdk.http.auth.tunneling.disabledSchemes="
[ -n "$PROXY_USER" ] && OPTS="$OPTS -Dhttp.proxyUser=$PROXY_USER -Dhttp.proxyPassword=$PROXY_PASS -Dhttps.proxyUser=$PROXY_USER -Dhttps.proxyPassword=$PROXY_PASS"

echo "export GRADLE_OPTS=\"$OPTS\"" > ~/.gradle/proxy-env.sh

echo "Gradle proxy configured: $PROXY_HOST:$PROXY_PORT"
