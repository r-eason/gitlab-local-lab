# Standalone Local GitLab Testing Laboratory

This project initializes a user-space, zero-sudo local laboratory consisting of a GitLab Server and an isolated GitLab Runner executing on version **19.1.x** tracks [19.1]. It handles self-signed certificate pathing dynamically, shifting ports automatically to run cleanly within rootless environment spaces.

## 🚀 Execution Instructions

### 1. Enable your Local Workstation Podman Socket
Ensure your user space engine socket service is active on your laptop before running initialization modules:
```bash
systemctl --user enable --now podman.socket
```

### 2. Run the Startup Module
```bash
chmod +x scripts/*.sh
./scripts/start-lab.sh
```

### 3. Retrieve Root Password & Register Agent
Navigate your laptop browser to `https://gitlab.local:8443`. Log in using user `root` and the password string printed via:
```bash
podman exec -it gitlab.local grep 'Password:' /etc/gitlab/initial_root_password
```
Go to **Admin Area > Runners**, grab your instance token, and establish the agent binding:
```bash
./scripts/register-runner.sh
```

### 🔐 Connecting External Playbook Repositories
Because the CA certificate is kept entirely within this workspace, external projects can log in and push constructed automation containers directly to this registry using localized path references:

```bash
podman login --tls-verify --cert-dir /absolute/path/to/gitlab-local-lab/certs -u root gitlab.local:8443
```

