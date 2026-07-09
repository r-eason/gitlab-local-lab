#!/usr/bin/env bash
# ==============================================================================
# AUTOMATED TLS LOCAL TRUST ANCHOR GENERATOR (ROBUST PATH PROTECTION)
# ==============================================================================
set -euo pipefail

# Safely check for and instantiate the target output folder if missing
TARGET_CERT_DIR="$(dirname "$0")/../certs"
if [ ! -d "${TARGET_CERT_DIR}" ]; then
    echo "--- Creating certs output container boundary folder ---"
    mkdir -p "${TARGET_CERT_DIR}"
fi

# Lock execution bounds inside this clean directory path context
cd "${TARGET_CERT_DIR}"

echo "=== Generating Local Isolation CA ==="
openssl req -x509 -nodes -days 365 -newkey rsa:4040 \
  -keyout lab-ca.key -out lab-ca.crt \
  -subj "/CN=GitLab Local Lab CA/O=Enterprise DevOps/C=US"

echo "=== Generating Server TLS Request and Signing via CA ==="
openssl req -nodes -newkey rsa:2048 -keyout gitlab.local.key -out gitlab.local.csr \
  -subj "/CN=gitlab.local/O=Enterprise DevOps/C=US"

# Build Subject Alternative Name (SAN) extension sheet to prevent modern Go client rejections
cat <<EOF > v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = gitlab.local
IP.1 = 127.0.0.1
EOF

openssl x509 -req -in gitlab.local.csr -CA lab-ca.crt -CAkey lab-ca.key \
  -CAcreateserial -out gitlab.local.crt -days 365 -extfile v3.ext

echo "=== Certificates Provisioned Successfully inside gitlab-local-lab/certs/ ==="

