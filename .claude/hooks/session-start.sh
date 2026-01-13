#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web (remote environment)
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo "Configuring Maven for Claude Code remote environment..."

# Create Maven config directory
mkdir -p ~/.m2

# Extract proxy host and port from HTTPS_PROXY environment variable
# Expected format: http://user:pass@host:port or http://host:port
if [ -n "${HTTPS_PROXY:-}" ]; then
  # Check if proxy URL contains authentication
  if [[ "$HTTPS_PROXY" =~ @ ]]; then
    # Extract username and password
    PROXY_USER=$(echo "$HTTPS_PROXY" | sed -E 's|https?://([^:]+):.*@.*|\1|')
    PROXY_PASS=$(echo "$HTTPS_PROXY" | sed -E 's|https?://[^:]+:([^@]+)@.*|\1|')
    # Extract host and port (after @)
    PROXY_HOST=$(echo "$HTTPS_PROXY" | sed -E 's|https?://[^@]+@([^:]+):.*|\1|')
    PROXY_PORT=$(echo "$HTTPS_PROXY" | sed -E 's|https?://[^@]+@[^:]+:([0-9]+).*|\1|')
  else
    # No authentication
    PROXY_USER=""
    PROXY_PASS=""
    PROXY_HOST=$(echo "$HTTPS_PROXY" | sed -E 's|https?://||' | cut -d':' -f1)
    PROXY_PORT=$(echo "$HTTPS_PROXY" | sed -E 's|https?://||' | cut -d':' -f2 | cut -d'/' -f1)
  fi

  echo "Detected proxy: $PROXY_HOST:$PROXY_PORT"

  # Get no_proxy list
  NO_PROXY_HOSTS="${NO_PROXY:-localhost|127.0.0.1}"

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
            <nonProxyHosts>${NO_PROXY_HOSTS}</nonProxyHosts>
        </proxy>
        <proxy>
            <id>https-proxy</id>
            <active>true</active>
            <protocol>https</protocol>
            <host>${PROXY_HOST}</host>
            <port>${PROXY_PORT}</port>
            <nonProxyHosts>${NO_PROXY_HOSTS}</nonProxyHosts>
        </proxy>
    </proxies>
</settings>
EOF

  echo "✅ Maven settings.xml created with proxy configuration"

  # Configure Gradle proxy settings
  echo "Configuring Gradle for Claude Code remote environment..."
  mkdir -p ~/.gradle

  # Build Gradle properties with or without authentication
  # Add Google domains to nonProxyHosts to attempt direct access
  EXTENDED_NO_PROXY="${NO_PROXY_HOSTS}|dl.google.com|maven.google.com|*.googleapis.com"

  if [ -n "${PROXY_USER}" ] && [ -n "${PROXY_PASS}" ]; then
    cat > ~/.gradle/gradle.properties <<EOF
# Proxy configuration for Claude Code remote environment
systemProp.http.proxyHost=${PROXY_HOST}
systemProp.http.proxyPort=${PROXY_PORT}
systemProp.http.proxyUser=${PROXY_USER}
systemProp.http.proxyPassword=${PROXY_PASS}
systemProp.https.proxyHost=${PROXY_HOST}
systemProp.https.proxyPort=${PROXY_PORT}
systemProp.https.proxyUser=${PROXY_USER}
systemProp.https.proxyPassword=${PROXY_PASS}
systemProp.http.nonProxyHosts=${EXTENDED_NO_PROXY}
systemProp.https.nonProxyHosts=${EXTENDED_NO_PROXY}

# Gradle daemon configuration
org.gradle.daemon=true
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
EOF
  else
    cat > ~/.gradle/gradle.properties <<EOF
# Proxy configuration for Claude Code remote environment
systemProp.http.proxyHost=${PROXY_HOST}
systemProp.http.proxyPort=${PROXY_PORT}
systemProp.https.proxyHost=${PROXY_HOST}
systemProp.https.proxyPort=${PROXY_PORT}
systemProp.http.nonProxyHosts=${EXTENDED_NO_PROXY}
systemProp.https.nonProxyHosts=${EXTENDED_NO_PROXY}

# Gradle daemon configuration
org.gradle.daemon=true
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
EOF
  fi

  echo "✅ Gradle properties created with proxy configuration"
else
  echo "⚠️  No HTTPS_PROXY environment variable found, skipping proxy configuration"
fi

echo "Session start hook completed successfully"
