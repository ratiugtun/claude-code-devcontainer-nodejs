# DevContainer for My Profile App with Claude Code

This repository is the **DevContainer overlay** for bootstrapping the application workspace. It contains
only the development-environment configuration — it is **not** the application source itself. The app
(Svelte 5 frontend + Laravel 12 / PHP backend + MySQL / Redis / Nginx) lives in separate repositories
that are cloned into the same `/workspace` folder; this repo supplies the container definition that the
whole stack is developed in.

Repository contents:

- `.devcontainer/` — the DevContainer definition (Dockerfile, `devcontainer.json`, entrypoint and init scripts, baked-in agent list)
- `ca-certificates/` — corporate / self-signed CA certificates to trust inside the container

## Features

- **Claude Code CLI**: Pre-installed and ready to use (optional via build arg)
- **Pre-installed Claude Code Agents**: A curated agent set baked into the image and synced into the workspace at startup
- **Scheduler plugin**: Optional Claude Code scheduler plugin for cron-style tasks
- **GitLab CLI (`glab`)**: Pre-installed and auto-configured at startup
- **GitHub CLI (`gh`)**: Pre-installed
- **Docker CLI**: Pre-installed; can drive the host Docker daemon when the socket is mounted which useful for Claude Code agents to work with containers
- **Proxy Support**: Propagates `http_proxy`, `https_proxy`, and `no_proxy` to the build and runtime
- **CA Certificates**: Automatically installs CA certificates from the `ca-certificates/` directory for corporate proxies
- **Node.js Environment**: Node.js 24 (configurable)
- **PHP / Laravel Tooling**: VS Code extensions for Intelephense, Xdebug (PHP Debug), and Laravel snippets
- **Development Tools**: Git, zsh + Powerlevel10k, fzf, git-delta, jq, tree, the MySQL client, and more
- **Network Firewall**: Optional domain-allowlist firewall, applied only when a proxy is configured

## Prerequisites

- Docker
- VS Code with the Dev Containers (Remote - Containers) extension

## First-Time Setup

> **Important:** The committed `.devcontainer/devcontainer.json` is the maintainer's working copy and
> contains a specific person's Git name/email and project-specific build args. The sanitized template is
> `.devcontainer/devcontainer.json.example`. New users should start from the example.

1. **Copy the example config and make it your own:**

   ```bash
   cp .devcontainer/devcontainer.json.example .devcontainer/devcontainer.json
   ```

2. **Set your Git identity.** Edit the `build.args` block in your `devcontainer.json` and fill in your
   own values:

   ```jsonc
   "GIT_CONFIG_NAME": "Your Name",
   "GIT_CONFIG_EMAIL": "you@example.com",
   ```

   These are passed as build args and used to run `git config --global user.name/user.email` for the
   `node` user inside the image.

3. **(Optional) Set proxy environment variables on the host** if you are behind a corporate proxy:

   ```bash
   export http_proxy=http://your-proxy:port
   export https_proxy=http://your-proxy:port
   export no_proxy=localhost,127.0.0.1,.local
   ```

4. **(Optional) Set your GitLab credentials on the host** (see [GitLab Authentication](#gitlab-authentication)):

   ```bash
   export GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
   export GITLAB_HOST=gitlab.com   # optional; see below for the real default
   ```

5. **(Optional) Place CA certificates** (`.crt` files) into the `ca-certificates/` directory (see
   [CA Certificates](#ca-certificates)).

6. **(Optional) Enable Docker-in-container** by adding the docker socket mount (see
   [Docker Inside the Container](#docker-inside-the-container)).

7. Open the workspace in VS Code and choose **"Reopen in Container"**.

## Build Arguments

All build args are set in the `build.args` block of `devcontainer.json`. The defaults shown are those in
the committed config.

| Build Arg                    | Default                | Purpose                                                                       |
| ---------------------------- | ---------------------- | ----------------------------------------------------------------------------- |
| `NODE_VERSION`               | `24`                   | Node.js major version (image base is `node:${NODE_VERSION}-trixie`)           |
| `PHP_VERSION`                | `8.4`                  | PHP version target for backend tooling                                        |
| `INSTALL_CLAUDE_CLI`         | `true`                 | Install the Claude Code CLI (`@anthropic-ai/claude-code`) and `ccusage`       |
| `INSTALL_SCHEDULER_PLUGIN`   | `true`                 | Install the Claude Code scheduler plugin (requires `INSTALL_CLAUDE_CLI=true`) |
| `INSTALL_CLAUDE_CODE_AGENTS` | `true`                 | Bake in the agents listed in `.devcontainer/claude-code-agents`               |
| `GIT_CONFIG_NAME`            | _(maintainer's name)_  | Value for `git config --global user.name` — **change this**                   |
| `GIT_CONFIG_EMAIL`           | _(maintainer's email)_ | Value for `git config --global user.email` — **change this**                  |
| `TZ`                         | `Asia/Bangkok`         | Container timezone (from `${localEnv:TZ:Asia/Bangkok}`)                       |

Proxy build args (`http_proxy`, `https_proxy`, `no_proxy` and their upper-case variants) are also wired
through from the host's local environment so that image build steps work behind a proxy.

> The sanitized `.example` ships with `INSTALL_SCHEDULER_PLUGIN=false` and
> `INSTALL_CLAUDE_CODE_AGENTS=false` so a fresh setup is lightweight; enable them as needed.

## Pre-Installed Claude Code Agents

When `INSTALL_CLAUDE_CODE_AGENTS=true`, the image bakes in the agents listed in
`.devcontainer/claude-code-agents` (one per line; blank lines and `#` comments are skipped). The current
list includes:

- `development-tools/context-manager`
- `development-team/ui-ux-designer`
- `development-team/frontend-developer`
- `development-team/fullstack-developer`
- `database/database-architect`
- `development-tools/code-reviewer`
- `development-tools/test-engineer`
- `security/security-auditor`
- `expert-advisors/documentation-expert`
- `documentation/api-documenter`
- `development-team/devops-engineer`
- `devops-infrastructure/deployment-engineer`

During the build these are fetched via `claude-code-templates` into the image. At **container startup**,
the entrypoint (`devcontainer-entrypoint.sh`) syncs the baked-in agents from
`/tmp/claude-code/.claude/agents` into `/workspace/.claude/agents`. The sync uses `cp -an`
(**no-clobber**), so it **never overwrites your local edits** — existing agent files in the workspace are
left untouched, and only missing ones are added.

To change the baked-in set, edit `.devcontainer/claude-code-agents` and rebuild the container.

## Scheduler Plugin & Agent Teams

- **Scheduler plugin** — When `INSTALL_SCHEDULER_PLUGIN=true` (and `INSTALL_CLAUDE_CLI=true`), the build
  adds the [`ai-launchpad-marketplace`](https://github.com/kenneth-liao/ai-launchpad-marketplace)
  marketplace and installs the `scheduler` plugin, enabling cron-style scheduled Claude Code tasks.

- **Experimental agent teams** — The `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable controls
  multi-agent team features. It defaults to **`0`** (off) and is wired via `remoteEnv` from
  `${localEnv:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:0}`. To turn it on, set it on the host before reopening
  the container:

  ```bash
  export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
  ```

## GitLab Authentication

`glab` is auto-configured at container startup by the entrypoint. It reads two variables:

| Variable       | Default (in code) | Purpose                                                                |
| -------------- | ----------------- | ---------------------------------------------------------------------- |
| `GITLAB_TOKEN` | _(none)_          | GitLab Personal Access Token — needs `api` + `write_repository` scopes |
| `GITLAB_HOST`  | **`gitlab.com`**  | GitLab instance hostname                                               |

The entrypoint script resolves the host with `GITLAB_HOST="${GITLAB_HOST:-gitlab.com}"`, so the **real
default is `gitlab.com`** (not `gitlab.yourdomain.com`). If `GITLAB_TOKEN` is set, the entrypoint writes
`~/.config/glab-cli/config.yml` with `skip_tls_verify: "true"` (so self-signed on-premise instances work)
and `chmod 600`.

> **Note:** This config file is rewritten on **every** container start — manual edits to
> `~/.config/glab-cli/config.yml` will be overwritten on restart.

### How the two config variants differ

- **Committed `devcontainer.json`** has **no `containerEnv` block**. It passes only `GITLAB_TOKEN` through
  `remoteEnv` (`"GITLAB_TOKEN": "${localEnv:GITLAB_TOKEN}"`). It does **not** forward `GITLAB_HOST`, so the
  entrypoint falls back to the `gitlab.com` default unless you add it yourself.

- **`devcontainer.json.example`** adds a `containerEnv` block **and** `remoteEnv` entries for
  `GITLAB_HOST` (`"${localEnv:GITLAB_HOST:gitlab.com}"`) and `GITLAB_TOKEN`. The `containerEnv` block is
  what makes `GITLAB_HOST` visible to the container entrypoint (which runs `glab` config), while
  `remoteEnv` exposes it to VS Code terminals and Claude Code.

To use a self-hosted GitLab, either start from the `.example` (recommended) or add the same `containerEnv`
entry to your `devcontainer.json`, then export `GITLAB_HOST` on the host:

```jsonc
"containerEnv": {
  "GITLAB_HOST": "${localEnv:GITLAB_HOST:gitlab.com}",
  "GITLAB_TOKEN": "${localEnv:GITLAB_TOKEN}"
}
```

### Verifying GitLab Authentication

After the container starts:

```bash
glab auth status          # should show your configured host as authenticated
glab issue list           # list issues in the current repo
glab mr list              # list merge requests
```

## Docker Inside the Container

The Docker **CLI** is pre-installed in the image, but to drive the **host** Docker daemon you must mount
the host's Docker socket into the container.

- The socket mount is present in `devcontainer.json.example`:

  ```jsonc
  "mounts": [
    // ...
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ]
  ```

- It is **not** present in the committed `devcontainer.json`. To enable docker-in-container, add the mount
  line above to your `mounts` array (or start from the `.example`), then rebuild/reopen.

On startup, the entrypoint runs `init-docker-socket.sh` (via `sudo`) to fix permissions: it reads the
GID of `/var/run/docker.sock`, creates or reuses a container group with that GID, and adds the `node`
user to it. This lets the non-root `node` user talk to the socket. If the socket is not mounted, the
script simply logs a message and exits cleanly.

## Network Firewall

A domain-allowlist firewall (`init-firewall.sh`) can lock down outbound traffic. It is **opt-in by
proxy**:

- The entrypoint runs the firewall **only when** a proxy variable is set (`http_proxy`, `https_proxy`,
  `HTTP_PROXY`, or `HTTPS_PROXY`). With no proxy set, firewall setup is skipped.
- It requires the `NET_ADMIN` and `NET_RAW` Linux capabilities, which are granted via `runArgs`
  (`--cap-add=NET_ADMIN`, `--cap-add=NET_RAW`) in `devcontainer.json`.

When it runs, the script:

1. Flushes existing iptables rules (while preserving internal Docker DNS resolution).
2. Allows DNS, SSH, and localhost traffic.
3. Builds an `allowed-domains` ipset from:
   - GitHub's published IP ranges (fetched from `https://api.github.com/meta`).
   - A resolved list of hostnames: `registry.npmjs.org`, `api.anthropic.com`, `sentry.io`,
     `statsig.anthropic.com`, `statsig.com`, `marketplace.visualstudio.com`,
     `vscode.blob.core.windows.net`, `update.code.visualstudio.com`.
   - The detected host network (`/24` of the default route).
4. Sets default `INPUT`/`FORWARD`/`OUTPUT` policies to `DROP`, allows established connections, allows the
   `allowed-domains` set, and **rejects** everything else.
5. Verifies the policy by confirming `https://example.com` is blocked and `https://api.github.com` is
   reachable (the script exits non-zero if these checks fail).

### Adding an allowed domain

Edit `.devcontainer/init-firewall.sh` and add the hostname to the `for domain in \` list (around the
`registry.npmjs.org` entries), then rebuild the container so the updated script is copied into the image:

```sh
for domain in \
    "registry.npmjs.org" \
    "api.anthropic.com" \
    "your-new-domain.example.com" \
    ...; do
```

For IP ranges you can add CIDRs directly to the `allowed-domains` ipset following the GitHub-range
example in the script.

## CA Certificates

Place corporate or self-signed CA certificates as `.crt` files anywhere under the `ca-certificates/`
directory — **subdirectories are supported**. During the image build, the Dockerfile:

1. Copies the entire `ca-certificates/` tree into the image.
2. Recursively finds every `*.crt` file (`find ... -name "*.crt"`), so certs nested in subdirectories are
   picked up.
3. Copies them into `/usr/local/share/ca-certificates/`, sets mode `644`, and runs `update-ca-certificates`.

The image also sets `NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt` so Node.js trusts the same
bundle. If no `.crt` files are found, the cert-install step is skipped entirely.

## What Gets Mounted

- **Workspace**: The local workspace folder is bind-mounted to `/workspace`
- **Claude Config**: Host `~/.claude` is bind-mounted to `/home/node/.claude` for persistent Claude Code config
- **Command History**: Persistent bash history via a Docker volume (`claude-code-bashhistory-*`)
- **Docker socket** _(optional)_: `/var/run/docker.sock` — only in the `.example`; see [Docker Inside the Container](#docker-inside-the-container)

## Environment Variables

| Variable                                  | Where set                                                 | Default                     | Purpose                                                   |
| ----------------------------------------- | --------------------------------------------------------- | --------------------------- | --------------------------------------------------------- |
| `GITLAB_TOKEN`                            | Host shell → `remoteEnv`                                  | _(none)_                    | GitLab Personal Access Token (`api` + `write_repository`) |
| `GITLAB_HOST`                             | Host shell → `containerEnv`/`remoteEnv` (`.example` only) | `gitlab.com`                | GitLab instance hostname                                  |
| `http_proxy` / `https_proxy` / `no_proxy` | Host shell → build args + `remoteEnv`                     | _(none)_                    | Corporate proxy (also gates the firewall)                 |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`    | Host shell → `remoteEnv`                                  | `0`                         | Toggle experimental agent-team features                   |
| `TZ`                                      | Host shell → build arg                                    | `Asia/Bangkok`              | Container timezone                                        |
| `NODE_OPTIONS`                            | `remoteEnv`                                               | `--max-old-space-size=4096` | Node heap size                                            |

## Ports

The following ports are automatically forwarded:

- `3000`: Backend API
- `5173`: Frontend Dev Server
- `3306`: MySQL (silent)
- `6379`: Redis (silent)
- `80`: Nginx HTTP
- `443`: Nginx HTTPS

## Troubleshooting

- **Build or network failures behind a proxy** — Ensure `http_proxy`/`https_proxy`/`no_proxy` are
  exported on the host _before_ building, so they propagate into both the image build (build args) and
  the running container (`remoteEnv`). When a proxy is set, the firewall is also applied; if a tool can't
  reach a host, the domain may need to be added to the allowlist (see [Network Firewall](#network-firewall)).

- **TLS / certificate errors** — Make sure your corporate CA `.crt` files are in `ca-certificates/`
  (subdirectories are fine) and **rebuild** the container; certificates are installed at build time, not
  at startup. Verify with `openssl x509 -in your-cert.crt -noout -subject` and check that the cert appears
  in `/etc/ssl/certs/ca-certificates.crt`.

- **`glab` TLS errors against a self-hosted GitLab** — The entrypoint writes `skip_tls_verify: "true"`
  into `~/.config/glab-cli/config.yml`, which handles self-signed certs. Remember this file is regenerated
  on every container start, so re-run `glab auth status` after a restart rather than hand-editing it. If
  `glab` reports the wrong host, confirm `GITLAB_HOST` is exposed via `containerEnv` (it is missing from
  the committed `devcontainer.json`).

- **`docker` permission denied / "Cannot connect to the Docker daemon"** — Confirm the socket mount is
  present (`/var/run/docker.sock`, only in the `.example`). If it is mounted but you still get permission
  errors, the GID fix from `init-docker-socket.sh` adds `node` to the socket's group at startup — open a
  **new** shell (or restart the container) so the updated group membership takes effect.

## Notes

- The container runs as the `node` user (non-root); `init-firewall.sh` and `init-docker-socket.sh` run via passwordless `sudo`.
- Git is pre-configured from the `GIT_CONFIG_NAME` / `GIT_CONFIG_EMAIL` build args.
- The default shell is `zsh` with the Powerlevel10k theme.
- `glab` config is written to `~/.config/glab-cli/config.yml` on every container start; manual edits to that file will be overwritten on restart.
