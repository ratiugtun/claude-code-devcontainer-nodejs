ARG NODE_VERSION=latest
# node based on debian bookworm
FROM node:${NODE_VERSION}

ARG TZ
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

ENV TZ="$TZ"
ENV http_proxy="$HTTP_PROXY"
ENV https_proxy="$HTTPS_PROXY"
ENV HTTP_PROXY="$HTTP_PROXY"
ENV HTTPS_PROXY="$HTTPS_PROXY"
ENV no_proxy="$NO_PROXY"
ENV NO_PROXY="$NO_PROXY"

###########################################################################
# Add Certificate Authorities
###########################################################################
# Copy CA certificates from workspace if they exist
COPY ca-certificates /tmp/ca-certificates-source
RUN if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ]; then \
    find /tmp/ca-certificates-source -name "*.crt" -exec cp {} /usr/local/share/ca-certificates/ \; 2>/dev/null || true && \
    find /usr/local/share/ca-certificates/ -name "*.crt" -exec chmod 644 {} \; 2>/dev/null || true && \
    update-ca-certificates; \
  fi && \
  rm -rf /tmp/ca-certificates-source
# Add the cert to the NODE_EXTRA_CA_CERTS environment variable
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

# Install basic development tools and iptables/ipset
RUN apt update && apt install -y less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  tree \
  && rm -rf /var/lib/apt/lists/*

# Try to install python3-full and python3-pip
RUN apt-get update && apt-get install -y --fix-missing python3-full python3-pip || true \
    && rm -rf /var/lib/apt/lists/*

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_0.18.2_${ARCH}.deb" && \
  rm "git-delta_0.18.2_${ARCH}.deb"

# Set up non-root user
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Default powerline10k theme
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.0/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# Install Claude Code CLI via npm if `INSTALL_CLAUDE_CLI` is set to "true"
# Fix the claude-code version @2.0.47 to avoid MacOS proxy issue
# Ref: https://github.com/anthropics/claude-code/issues/12081#issuecomment-3565017433
ARG INSTALL_CLAUDE_CLI=false
RUN if [ "$INSTALL_CLAUDE_CLI" = "true" ]; then \
  npm install -g @anthropic-ai/claude-code@2.0.47; \
  npm install -g ccusage@latest; \
  fi

# Copy and set up firewall script
COPY .devcontainer/init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall
USER node

ARG GIT_CONFIG_EMAIL
ARG GIT_CONFIG_NAME
# Configure git for the node user
RUN git config --global user.email "$GIT_CONFIG_EMAIL" && \
    git config --global user.name "$GIT_CONFIG_NAME"