#!/usr/bin/env bash
# ==============================================================================
# SYSTEM LAB ENGINE LIFECYCLE MANAGEMENT UNIT (DYNAMIC RE-ENTRY & GATEWAYS)
# ==============================================================================
set -euo pipefail

# Standardize path routing directly to the isolated laboratory root folder
cd "$(dirname "$0")/.."

# Capture the definitive absolute local workstation path dynamically
ABSOLUTE_LAB_PATH=$(pwd)
USER_UID=$(id -u)

# Define the authoritative rootless Podman socket path location
PODMAN_SOCKET_PATH="/run/user/${USER_UID}/podman/podman.sock"

echo "=== Verification: Checking local user-space socket path ==="
if [ ! -S "${PODMAN_SOCKET_PATH}" ]; then
    echo "❌ ERROR: Socket file not found at ${PODMAN_SOCKET_PATH}."
    echo "--> Please enable your user-space background socket daemon first by running:"
    echo "    systemctl --user enable --now podman.socket"
    exit 1
fi

echo "=== Cleaning up legacy or conflicting laboratory containers ==="
podman rm -f gitlab.local gitlab-runner 2>/dev/null || true
podman network rm gitlab-net 2>/dev/null || true

# Map standard persistent data structures locally
mkdir -p data/gitlab/{config,logs,data} data/runner certs

# Create isolated container network bridge first to establish gateway bounds
podman network create gitlab-net || true

# DYNAMIC CAPTURE: Extract the real live gateway IP address on the fly
LAB_GATEWAY_IP=$(podman network inspect gitlab-net -f '{{range .Subnets}}{{.Gateway}}{{end}}')
echo "=== Detected Active Podman Bridge Gateway IP: ${LAB_GATEWAY_IP} ==="

# 1. Run Certificate Provisioner automatically if missing
if [ ! -f certs/gitlab.local.crt ]; then
    ./scripts/generate-certs.sh
    cd "${ABSOLUTE_LAB_PATH}"
fi

# 2. Compile the Template using both your absolute path AND your live gateway IP
echo "=== Compiling dynamic runner configuration paths ==="
sed -e "s|__HOST_PROJECT_PATH__|${ABSOLUTE_LAB_PATH}|g" \
    -e "s|__LAB_GATEWAY_IP__|${LAB_GATEWAY_IP}|g" \
    runner/config.toml.template > runner/config.toml

# 3. Local DNS Loopback Verification Check
if ! grep -q "gitlab.local" /etc/hosts; then
    echo "--- Modifying /etc/hosts for resolution (Requires authorization) ---"
    echo "127.0.0.1 gitlab.local" | sudo tee -a /etc/hosts
fi

# ==============================================================================
# ENGINE START: GITLAB SERVER
# ==============================================================================
echo "=== Spinning Up GitLab Server Container on Unprivileged Ports ==="
cp certs/gitlab.local.crt data/gitlab/config/gitlab.local.crt
cp certs/gitlab.local.key data/gitlab/config/gitlab.local.key

podman run -d \
  --name gitlab.local \
  --hostname gitlab.local \
  --network gitlab-net \
  -p 8443:8443 -p 8080:8080 -p 2222:22 \
  -v "${ABSOLUTE_LAB_PATH}/data/gitlab/config:/etc/gitlab:Z" \
  -v "${ABSOLUTE_LAB_PATH}/data/gitlab/logs:/var/log/gitlab:Z" \
  -v "${ABSOLUTE_LAB_PATH}/data/gitlab/data:/var/opt/gitlab:Z" \
  --env GITLAB_OMNIBUS_CONFIG="
    external_url 'https://gitlab.local:8443';
    prometheus_monitoring['enable'] = false;
    sidekiq['metrics_enabled'] = false;
    nginx['redirect_http_to_https'] = true;
    nginx['listen_port'] = 8443;
    nginx['ssl_certificate'] = '/etc/gitlab/gitlab.local.crt';
    nginx['ssl_certificate_key'] = '/etc/gitlab/gitlab.local.key';
  " \
  docker.io/gitlab/gitlab-ce:latest

# ==============================================================================
# ENGINE START: GITLAB RUNNER (SOCKET REASSIGNMENT AND USERNS ACTIVE)
# ==============================================================================
echo "=== Spinning Up Secure Local GitLab Runner ==="
podman run -d \
  --name gitlab-runner \
  --network gitlab-net \
  --userns=keep-id:uid=0,gid=0 \
  --security-opt label=disable \
  -v "${PODMAN_SOCKET_PATH}:/var/run/docker.sock:ro" \
  -v "${ABSOLUTE_LAB_PATH}/runner/config.toml:/etc/gitlab-runner/config.toml:Z" \
  -v "${ABSOLUTE_LAB_PATH}/certs/lab-ca.crt:/etc/gitlab-runner/certs/gitlab.local.crt:ro,Z" \
  docker.io/gitlab/gitlab-runner:latest

echo "=== Injecting CA Trust Anchor into Runner's Native Ubuntu DB ==="
sleep 2 # Brief pause to allow the container filesystem mapping to initialize
podman cp "${ABSOLUTE_LAB_PATH}/certs/lab-ca.crt" gitlab-runner:/usr/local/share/ca-certificates/gitlab.local.crt
podman exec -u root gitlab-runner update-ca-certificates

# ==============================================================================
# 📋 POST-EXECUTION CONSOLE LOG INFORMATION OUTPUTS
# ==============================================================================
echo ""
echo "=============================================================================="
echo "✅ SUCCESS: Lab Environment Initialized and Hardened via User Space Socket"
echo "=============================================================================="
echo "--> Open browser: https://gitlab.local:8443"
echo "--> Run to fetch password: podman exec -it gitlab.local grep 'Password:' /etc/gitlab/initial_root_password"
echo "--> Connect runner: ./scripts/register-runner.sh"
echo "=============================================================================="

