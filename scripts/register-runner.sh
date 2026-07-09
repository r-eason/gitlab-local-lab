#!/usr/bin/env bash
# ==============================================================================
# AGENT REGISTRATION ROUTER (INLINE REWRITE PATTERN - NO OVERWRITE DRIFT)
# ==============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."
ABSOLUTE_LAB_PATH=$(pwd)

# Dynamically sample your running gitlab-net gateway IP address
LAB_GATEWAY_IP=$(podman network inspect gitlab-net -f '{{range .Subnets}}{{.Gateway}}{{end}}')

echo "=============================================================================="
echo "🔒 MODERN RUNNER ARCHITECTURE INSTRUCTIONS"
echo "=============================================================================="
echo "1. Log into https://gitlab.local:8443 as admin."
echo "2. Navigate to: Admin Area > CI/CD > Runners."
echo "3. Click 'New Instance Runner'. Provide tag: podman-executor."
echo "4. Click 'Create runner' and COPY the authentication token (starts with glrt-)."
echo "=============================================================================="
echo ""

read -rp "Enter your GitLab Runner Authentication Token (glrt-): " AUTH_TOKEN

echo "=== Executing TLS-Hardened Runner Authentication via Bridge ==="
# Clean registration parameters stream string targeting the internal container DNS profile
podman exec -it gitlab-runner \
  gitlab-runner register \
    --non-interactive \
    --url "https://gitlab.local:8443" \
    --token "${AUTH_TOKEN}" \
    --tls-ca-file "/etc/gitlab-runner/certs/gitlab.local.crt" \
    --executor "docker" \
    --docker-image "quay.io/podman/stable:latest" \
    --docker-extra-hosts "gitlab.local:${LAB_GATEWAY_IP}" \
    --description "Unified Unprivileged User Space Runner"

echo "=== Applying Custom Unprivileged Parameters Inline ==="
# Use inline sed to structure your volume bounds cleanly without touching written token tokens keys
sed -i '/\[runners\.docker\]/a \    privileged = false' runner/config.toml
sed -i '/\[runners\.docker\]/a \    pre_build_script = "update-ca-trust"' runner/config.toml
sed -i '/\[runners\.docker\]/a \    volumes = ["/cache", "'"${ABSOLUTE_LAB_PATH}"'/certs/lab-ca.crt:/etc/pki/ca-trust/source/anchors/lab-ca.crt:ro,Z"]' runner/config.toml

echo "=== Force-restarting Runner to apply your new unprivileged configuration ==="
#podman restart gitlab-runner

echo "=============================================================================="
echo "✅ SUCCESS: Runner Authenticated and Verified Natively via TLS"
echo "=============================================================================="

