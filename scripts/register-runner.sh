#!/usr/bin/env bash
# ==============================================================================
# AGENT REGISTRATION ROUTER (DIRECT FLAG INJECTION METHOD - ALIGNED PARADIGMS)
# ==============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

# Dynamically sample your running gitlab-net gateway IP address
LAB_GATEWAY_IP=$(podman network inspect gitlab-net -f '{{range .Subnets}}{{.Gateway}}{{end}}')

echo "=============================================================================="
echo "🔒 MODERN RUNNER ARCHITECTURE INSTRUCTIONS"
echo "=============================================================================="
echo "1. Log into https://gitlab.local:8443 as admin."
echo "2. Navigate to: Admin Area > CI/CD > Runners."
echo "3. Click 'New Instance Runner'. Provide tags: podman-executor."
echo "4. Click 'Create runner' and COPY the authentication token (starts with glrt-)."
echo "=============================================================================="
echo ""

read -rp "Enter your GitLab Runner Authentication Token (glrt-): " AUTH_TOKEN

echo "=== Executing TLS-Hardened Runner Authentication via Bridge ==="

# Passing your target options explicitly completely replaces the template placeholders
podman exec -it gitlab-runner \
  gitlab-runner register \
    --non-interactive \
    --url "https://gitlab.local:8443" \
    --token "${AUTH_TOKEN}" \
    --template-config "/etc/gitlab-runner/config.toml" \
    --tls-ca-file "/etc/gitlab-runner/certs/gitlab.local.crt" \
    --executor "docker" \
    --docker-image "quay.io/podman/stable:latest" \
    --docker-host "unix:///var/run/docker.sock" \
    --docker-volumes "/cache" \
    --docker-volumes "/var/run/docker.sock:/var/run/docker.sock:ro" \
    --docker-volumes "/etc/gitlab-runner/certs/gitlab.local.crt:/etc/pki/ca-trust/source/anchors/lab-ca.crt:ro,Z" \
    --docker-extra-hosts "gitlab.local:${LAB_GATEWAY_IP}" \
    --description "Local User Space Verified TLS Podman Runner"

echo "=== Runner Registered and Authenticated Natively via TLS ==="

