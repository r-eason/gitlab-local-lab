# Standalone Local GitLab Testing Laboratory

This project initializes a completely user-space, zero-sudo local laboratory consisting of an HTTPS-secured GitLab CE Server and an isolated GitLab Runner executing on version **19.1.x** tracks [19.1]. It automates self-signed certificate generation and extracts your user-defined bridge network gateway on the fly, completely protecting your host machine's system trust stores from pollution.

---

## 🚀 Key Features

* **Pure User-Space Operation:** Runs entirely without root privileges or `sudo` requirements.
* **Automated Trust Boundary Mapping:** The runner container automatically mounts and updates your self-signed Root CA dynamically into its underlying trust databases on boot [19.1].
* **No Host Trust Pollution:** Bypasses your host workstation's global system trust stores entirely, keeping corporate laptop security configurations pristine.
* **Port-Shift Automation:** Bypasses privileged port checking by automatically translating traffic metrics over to unprivileged ports (`8443` for HTTPS and `8080` for HTTP).
* **Hot-Reloading Configuration:** Integrates a non-destructive inline editing engine (`sed -i`) that avoids breaking active API authentication tokens, allowing the runner's native file-watcher to hot-reload settings in real time [19.1].

---

## 📂 Project Architecture

```text
gitlab-local-lab/
├── .gitignore                 # Excludes raw data/ volumes, configuration states, and signed keys
├── README.md                  # Comprehensive user-space laboratory onboarding guide
├── certs/                     # Output destination for signed cryptographic assets
│   ├── lab-ca.crt             # (Auto-generated) Local Root CA anchor certificate
│   ├── gitlab.local.crt       # (Auto-generated) GitLab Server TLS certificate
│   └── gitlab.local.key       # (Auto-generated) GitLab Server TLS private key
├── runner/
│   └── config.toml            # Hardened, hot-reloading execution configuration map
└── scripts/
    ├── generate-certs.sh      # Path-protected certificate generator (Zero Sudo)
    ├── start-lab.sh           # Dynamic gateway capture, loopback secure setup, and server lifecycles
    └── register-runner.sh     # Modern glrt- authentication script using non-destructive inline injection
```

---

## 🛠 Prerequisites

Before starting the laboratory cluster, ensure your local laptop user context initializes the following background engine services:

```bash
# Enable the systemd user service for your user account (No sudo required)
systemctl --user enable --now podman.socket

# Verify the rootless socket is running cleanly in memory
systemctl --user status podman.socket
```
This maps your authoritative rootless Podman execution stream directly to `/run/user/$(id -u)/podman/podman.sock`.

---

## 💻 Laboratory Step-by-Step Setup

Ensure all script tools are flagged with execution authorization bits before running:
```bash
chmod +x scripts/*.sh
```

### 1. Initialize the Environment Stack
Run the central startup automation script. This script flushes legacy memory blocks, creates localized folders, provisions your TLS certificates automatically, and spins up the cluster containers on a shared user-defined network bridge (`gitlab-net`):

```bash
./scripts/start-lab.sh
```

### 2. Retrieve the Root Administrative Password
Because GitLab generates a randomized 32-character password for the `root` profile on initial boot, extract the string directly out of your mapped persistent config path:

```bash
podman exec -it gitlab.local grep 'Password:' /etc/gitlab/initial_root_password
```
*Note: This security document is automatically purged by the GitLab omnibus engine 24 hours after container creation.*

### 3. Authenticate and Connect the Runner Agent
Navigate your laptop browser to `https://gitlab.local:8443` (Bypass the self-signed warning or import `certs/lab-ca.crt` directly into your browser's dedicated user-space trust manager). 

Log in as `root`, go to **Admin Area > CI/CD > Runners**, click **New Instance Runner**, provide the tag **`podman-executor`**, and click **Create runner**. Copy the resulting authentication token string (starts with `glrt-`) and trigger the connector script:

```bash
./scripts/register-runner.sh
```

---

## 🔐 Interacting With the Registry From Other Projects

To log in, push compiled automation image layers, or pull runtime assets to this local registry from your primary Ansible playbook directory or external projects, pass the certificate path inline using standard container CLI arguments:

```bash
podman login --tls-verify --cert-dir /absolute/path/to/gitlab-local-lab/certs -u root gitlab.local:8443
```

---

## 🚨 Emergency Administrative Passphrase Resets

If your generated password document expires before you complete initial onboarding, you can drop straight into the database rails subsystem via your terminal shell to forcefully assign new administrative credentials:

```bash
# 1. Open the interactive rails console inside the running container boundary
podman exec -it gitlab.local gitlab-rails console -e production

# 2. Once the ruby prompt initializes, execute these database override hooks:
user = User.find_by_username('root')
user.password = 'YourNewSecurePassword123!'
user.password_confirmation = 'YourNewSecurePassword123!'
user.save!

# 3. Close the rails console session
exit
```

