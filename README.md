# Claude Code Dev Container — Node.js

A ready-to-use [Development Container](https://containers.dev/) template for Node.js projects with full [Claude Code](https://docs.anthropic.com/en/docs/claude-code) integration. Designed specifically for teams working behind a **corporate proxy**, with built-in CA certificate support, network firewall, and a pre-configured shell environment.

---

## Features

- **Claude Code** — pre-installed CLI and VS Code extension
- **Corporate proxy support** — pass-through proxy variables and custom CA certificate installation
- **Network firewall** — whitelist-only outbound access (GitHub, npm, Anthropic API, VS Code)
- **Node.js 24** on Debian Trixie (trixie)
- **Zsh + Oh My Zsh** with Powerline10k theme and fzf fuzzy finder
- **Persistent shell history** across container rebuilds
- **GitHub CLI** (`gh`), **Git Delta**, **Python 3**, and other developer tools
- **Non-root user** (`node`) with passwordless sudo for firewall management

---

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Docker Compose)
- [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

---

## Quick Start

### 1. Clone as a New Project

This repository is a **template** — clone it into a fresh directory for your own project. The commands below grab the files without carrying over this repo's git history.

**Using `degit` (recommended):**

```bash
npx degit <repo-url> my-project
cd my-project
git init
```

**Using `git clone` + strip history:**

```bash
git clone --depth=1 <repo-url> my-project
cd my-project
rm -rf .git
git init
```

Replace `my-project` with whatever directory name you want.

### 2. Configure the Dev Container

Copy the example configuration and update it with your details:

```bash
cp .devcontainer/devcontainer.json.example .devcontainer/devcontainer.json
```

Open `.devcontainer/devcontainer.json` and update:

```jsonc
"GIT_CONFIG_EMAIL": "your-email@example.com",
"GIT_CONFIG_NAME": "Your Name"
```

### 3. (Optional) Add Corporate CA Certificates

If you work behind a corporate proxy that performs TLS inspection, place your CA certificate files (`.crt`) in the `ca-certificates/` directory. They will be automatically installed into the container's trust store at build time.

```
ca-certificates/
├── your-corporate-ca.crt
└── your-proxy.crt
```

> Certificate files are excluded from git via `.gitignore` — only the `.gitkeep` placeholder is tracked.

### 4. Set Proxy Environment Variables (if needed)

Export your proxy settings in your host shell before opening the container. The devcontainer will inherit them automatically:

```bash
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
export NO_PROXY=localhost,127.0.0.1
```

### 5. Open in VS Code

```bash
code .
```

When prompted, click **Reopen in Container**. The first build takes a few minutes; subsequent opens are fast.

---

## Project Structure

```
claude-code-devcontainer-nodejs/
├── .devcontainer/
│   ├── Dockerfile                # Container image definition
│   ├── devcontainer.json         # Active configuration (git-ignored)
│   ├── devcontainer.json.example # Template — commit this, not the active one
│   └── init-firewall.sh          # Optional network firewall script
├── ca-certificates/              # Place corporate CA certs here (git-ignored)
│   └── .gitkeep
└── .gitignore
```

---

## Configuration Reference

### Build Arguments

| Argument              | Default          | Description                                  |
|-----------------------|------------------|----------------------------------------------|
| `NODE_VERSION`        | `24`             | Node.js version                              |
| `INSTALL_CLAUDE_CLI`  | `true`           | Install `@anthropic-ai/claude-code` globally |
| `GIT_CONFIG_EMAIL`    | —                | Git commit email                             |
| `GIT_CONFIG_NAME`     | —                | Git commit author name                       |
| `TZ`                  | `Asia/Bangkok`   | Container timezone                           |
| `HTTP_PROXY`          | *(from host)*    | HTTP proxy URL                               |
| `HTTPS_PROXY`         | *(from host)*    | HTTPS proxy URL                              |
| `NO_PROXY`            | *(from host)*    | Comma-separated no-proxy list                |

### Runtime Environment Variables

| Variable                              | Value                                  | Description                            |
|---------------------------------------|----------------------------------------|----------------------------------------|
| `NODE_OPTIONS`                        | `--max-old-space-size=4096`            | 4 GB Node.js heap                      |
| `CLAUDE_CONFIG_DIR`                   | `/home/node/.claude`                   | Claude Code config directory           |
| `NODE_EXTRA_CA_CERTS`                 | `/etc/ssl/certs/ca-certificates.crt`   | CA bundle for Node.js HTTPS            |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`| `0`                                    | Enable experimental Agent Teams (`1`)  |

### Forwarded Ports

| Port   | Service                     |
|--------|-----------------------------|
| `5173` | Frontend dev server (Vite)  |

Additional ports (3000, 3306, 6379, 80, 443, 22) can be uncommented in `devcontainer.json` as needed.

---

## Network Firewall

The container ships with an optional firewall script that locks down outbound traffic to a whitelist of known-good domains. This is useful when you want to ensure no unintended network calls leave the container.

**To enable the firewall**, run inside the container:

```bash
sudo /usr/local/bin/init-firewall.sh
```

**Allowed destinations:**

| Domain / Service              | Purpose                          |
|-------------------------------|----------------------------------|
| `api.github.com` + GitHub IPs | Git operations, GitHub CLI       |
| `registry.npmjs.org`          | npm package installs             |
| `api.anthropic.com`           | Claude API                       |
| `statsig.anthropic.com`       | Claude Code feature flags        |
| `marketplace.visualstudio.com`| VS Code extension installs       |
| `sentry.io`                   | Error reporting                  |
| DNS (UDP 53) + SSH (TCP 22)   | Core infrastructure              |

Everything else is **dropped** by default. The script verifies the setup by testing that `example.com` is blocked and GitHub is reachable.

> The firewall is **not** initialized automatically — it must be run manually when desired.

---

## Claude Code

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) is installed globally in the container and available as `claude`. The `ccusage` utility is also installed for tracking API usage.

The Claude configuration directory (`~/.claude` on your host) is bind-mounted into the container, so your existing Claude Code session, settings, and credentials are available immediately without re-authentication.

To enable the experimental **Agent Teams** feature:

```jsonc
// .devcontainer/devcontainer.json
"containerEnv": {
  "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
}
```

---

## Installed VS Code Extensions

| Extension   | Purpose                   |
|-------------|---------------------------|
| ESLint      | JavaScript/TypeScript lint |
| Prettier    | Code formatting           |
| GitLens     | Git history & blame       |
| Claude Code | AI-assisted development   |

---

## Customization Tips

- **Change Node version** — update `NODE_VERSION` build arg in `devcontainer.json`
- **Add npm packages** — uncomment `postCreateCommand` and add your `npm install` command
- **Different timezone** — set `TZ` build arg or use `${localEnv:TZ}` to inherit from host
- **Additional ports** — uncomment entries in the `forwardPorts` array

---

## Troubleshooting

**Proxy / SSL errors during build**
- Ensure `HTTP_PROXY` / `HTTPS_PROXY` are exported in your host shell before opening VS Code
- Add your proxy's CA certificate to `ca-certificates/` and rebuild the container

**`Invalid IP address: undefined` in firewall script**
- The script handles Docker DNS (`127.0.0.11`) automatically — this error is resolved in the current version

**Claude Code login fails**
- If running the firewall, confirm `api.anthropic.com` resolves and is reachable: `curl -v https://api.anthropic.com`
- Check `NO_PROXY` does not accidentally block Anthropic endpoints

**Container name conflicts**
- The container is named `devcon-<workspace-folder-name>`. Remove the old container via Docker Desktop or `docker rm` before rebuilding.
