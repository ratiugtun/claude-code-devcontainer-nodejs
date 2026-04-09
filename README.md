# DevContainer for My Profile App with Claude Code

This DevContainer configuration provides a development environment for the My Profile application with Claude Code CLI pre-installed.

## Features

- **Claude Code CLI**: Pre-installed and ready to use
- **GitLab CLI (`glab`)**: Pre-installed and auto-configured for the on-premise GitLab instance
- **Proxy Support**: Automatically detects and configures `http_proxy`, `https_proxy`, and `no_proxy` environment variables
- **CA Certificates**: Automatically installs CA certificates from `ca-certificates/` directory for corporate proxies
- **Node.js Environment**: Node.js 24 with all project dependencies
- **Development Tools**: Git, zsh, fzf, and other essential development tools
- **VS Code Extensions**: Pre-configured with ESLint, Prettier, GitLens, Tailwind CSS, and Svelte support

## Prerequisites

- Docker
- VS Code with Remote-Containers extension

## Setup

1. Ensure your proxy environment variables are set on the host:
   ```bash
   export http_proxy=http://your-proxy:port
   export https_proxy=https://your-proxy:port
   export no_proxy=localhost,127.0.0.1,.local
   ```

2. Set your GitLab credentials on the host (required for `glab` and Claude Code GitLab integration):
   ```bash
   export GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx  # Personal Access Token (api + write_repository scopes)
   export GITLAB_HOST=gitlab.yourdomain.com       # Optional: defaults to gitlab.yourdomain.com
   ```

   On container startup, `glab` is automatically configured with these credentials. TLS verification is
   skipped for the on-premise instance (self-signed certificate).

3. Place any required CA certificates (`.crt` files) in the `ca-certificates/` directory

4. Open the workspace in VS Code and select "Reopen in Container"

## What Gets Mounted

- **Workspace**: Current workspace is mounted to `/workspace`
- **Claude Config**: Host `~/.claude` directory is bound to container `~/.claude` for persistent Claude Code configuration
- **Command History**: Persistent bash history via Docker volume

## Environment Variables

| Variable | Where set | Default | Purpose |
|---|---|---|---|
| `GITLAB_TOKEN` | Host shell | *(none)* | GitLab Personal Access Token (needs `api` + `write_repository` scopes) |
| `GITLAB_HOST` | Host shell | `gitlab.yourdomain.com` | GitLab instance hostname |
| `http_proxy` / `https_proxy` | Host shell | *(none)* | Corporate proxy (also controls firewall rules) |

`GITLAB_TOKEN` and `GITLAB_HOST` are injected via `containerEnv` (available to the container entrypoint)
and `remoteEnv` (available to VS Code terminals and Claude Code).

## Verifying GitLab Authentication

After the container starts:
```bash
glab auth status          # should show gitlab.yourdomain.com as authenticated
glab issue list           # list issues in the current repo
glab mr list              # list merge requests
```

## Ports

The following ports are automatically forwarded:

- `3000`: Backend API
- `5173`: Frontend Dev Server  
- `3306`: MySQL (silent)
- `6379`: Redis (silent)
- `80`: Nginx HTTP
- `443`: Nginx HTTPS

## Notes

- The container runs as the `node` user (non-root)
- Git is pre-configured with the user details from CLAUDE.md
- Both frontend and backend dependencies are installed during container creation
- Network firewall is configured for security
- `glab` config is written to `~/.config/glab-cli/config.yml` on every container start; manual edits to that file will be overwritten on restart