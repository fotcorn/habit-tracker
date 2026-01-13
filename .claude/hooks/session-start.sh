#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web (remote environment)
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo "Configuring Maven and Gradle for Claude Code remote environment..."

# Create config directories
mkdir -p ~/.m2
mkdir -p ~/.gradle

# Extract proxy host and port from HTTPS_PROXY environment variable
# Expected format: http://user:pass@host:port or http://host:port
if [ -n "${HTTPS_PROXY:-}" ]; then
  # Parse the proxy URL to extract components
  # Remove protocol prefix
  PROXY_WITHOUT_PROTOCOL=$(echo "$HTTPS_PROXY" | sed -E 's|https?://||')

  # Check if there's authentication (contains @)
  if [[ "$PROXY_WITHOUT_PROTOCOL" == *"@"* ]]; then
    # Extract credentials (everything before the last @)
    PROXY_CREDS=$(echo "$PROXY_WITHOUT_PROTOCOL" | sed -E 's|(.*)@[^@]+$|\1|')
    # Extract host:port (everything after the last @)
    PROXY_HOST_PORT=$(echo "$PROXY_WITHOUT_PROTOCOL" | sed -E 's|.*@([^@]+)$|\1|')
    # Split credentials into user and password
    PROXY_USER=$(echo "$PROXY_CREDS" | cut -d':' -f1)
    PROXY_PASS=$(echo "$PROXY_CREDS" | cut -d':' -f2-)
  else
    PROXY_HOST_PORT="$PROXY_WITHOUT_PROTOCOL"
    PROXY_USER=""
    PROXY_PASS=""
  fi

  # Extract host and port
  PROXY_HOST=$(echo "$PROXY_HOST_PORT" | cut -d':' -f1)
  PROXY_PORT=$(echo "$PROXY_HOST_PORT" | cut -d':' -f2 | cut -d'/' -f1)

  echo "Detected proxy: $PROXY_HOST:$PROXY_PORT"

  # Get no_proxy list
  NO_PROXY_HOSTS="${NO_PROXY:-localhost|127.0.0.1}"
  # Convert comma-separated to pipe-separated for Maven
  NO_PROXY_MAVEN=$(echo "$NO_PROXY_HOSTS" | tr ',' '|')

  # Create Maven settings.xml with proxy configuration
  cat > ~/.m2/settings.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
          http://maven.apache.org/xsd/settings-1.0.0.xsd">
    <proxies>
        <proxy>
            <id>http-proxy</id>
            <active>true</active>
            <protocol>http</protocol>
            <host>${PROXY_HOST}</host>
            <port>${PROXY_PORT}</port>
            <nonProxyHosts>${NO_PROXY_MAVEN}</nonProxyHosts>
        </proxy>
        <proxy>
            <id>https-proxy</id>
            <active>true</active>
            <protocol>https</protocol>
            <host>${PROXY_HOST}</host>
            <port>${PROXY_PORT}</port>
            <nonProxyHosts>${NO_PROXY_MAVEN}</nonProxyHosts>
        </proxy>
    </proxies>
</settings>
EOF
  echo "Maven settings.xml created with proxy configuration"

  # Create Gradle properties with proxy configuration
  # Convert comma-separated NO_PROXY to pipe-separated for Gradle
  NO_PROXY_GRADLE=$(echo "$NO_PROXY_HOSTS" | tr ',' '|')

  cat > ~/.gradle/gradle.properties <<EOF
# Proxy configuration for Claude Code remote environment
systemProp.http.proxyHost=${PROXY_HOST}
systemProp.http.proxyPort=${PROXY_PORT}
systemProp.http.nonProxyHosts=${NO_PROXY_GRADLE}
systemProp.https.proxyHost=${PROXY_HOST}
systemProp.https.proxyPort=${PROXY_PORT}
systemProp.https.nonProxyHosts=${NO_PROXY_GRADLE}
EOF

  # Add authentication if credentials are present
  if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASS" ]; then
    cat >> ~/.gradle/gradle.properties <<EOF
systemProp.http.proxyUser=${PROXY_USER}
systemProp.http.proxyPassword=${PROXY_PASS}
systemProp.https.proxyUser=${PROXY_USER}
systemProp.https.proxyPassword=${PROXY_PASS}
EOF
  fi

  echo "Gradle gradle.properties created with proxy configuration"

  # Create env file for GRADLE_OPTS that build scripts can source
  # This is needed because the Gradle wrapper doesn't read gradle.properties
  # until after it downloads itself
  # Note: jdk.http.auth.tunneling.disabledSchemes must be empty to allow basic auth for HTTPS tunneling
  GRADLE_PROXY_OPTS="-Dhttp.proxyHost=${PROXY_HOST} -Dhttp.proxyPort=${PROXY_PORT} -Dhttps.proxyHost=${PROXY_HOST} -Dhttps.proxyPort=${PROXY_PORT} -Djdk.http.auth.tunneling.disabledSchemes= -Djdk.http.auth.proxying.disabledSchemes="
  if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASS" ]; then
    GRADLE_PROXY_OPTS="${GRADLE_PROXY_OPTS} -Dhttp.proxyUser=${PROXY_USER} -Dhttp.proxyPassword=${PROXY_PASS} -Dhttps.proxyUser=${PROXY_USER} -Dhttps.proxyPassword=${PROXY_PASS}"
  fi

  # Write to a well-known location that scripts can source
  cat > ~/.gradle/proxy-env.sh <<EOF
# Proxy configuration for Gradle wrapper (auto-generated)
export GRADLE_OPTS="${GRADLE_PROXY_OPTS}"
EOF
  chmod +x ~/.gradle/proxy-env.sh
  echo "Gradle proxy-env.sh created for wrapper configuration"
else
  echo "No HTTPS_PROXY environment variable found, skipping proxy configuration"
fi

# Note about Android development limitations:
# Android builds require access to Google Maven (dl.google.com or maven.google.com).
# If these hosts are not in the proxy's allowed list, builds will fail.
# Check the proxy's allowed hosts if builds fail with "could not resolve plugin artifact".

echo "Session start hook completed successfully"
