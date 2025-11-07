ARG DISTRO_IMAGE=ubuntu
ARG DISTRO_VERSION=24.04
ARG USERNAME=any
ARG USER_PASSWORD=1234
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG USE_INSECURE_REQ=1

FROM docker.io/${DISTRO_IMAGE}:${DISTRO_VERSION} AS base
FROM base AS config

ENV \
    DEBIAN_FRONTEND=noninteractive \
    container=docker \
    \
    TZ=UTC \
    LC_ALL=C \
    \
    USER_NAME=${USERNAME} \
    USER_UID=${USER_UID} \
    USER_GID=${USER_GID} \
    \
    CURLOPT_SSL_VERIFYPEER=${HOMEBREW_SSL_FLAG} \
    CURLOPT_SSL_VERIFYHOST=${HOMEBREW_SSL_FLAG}

COPY ./scripts/system/setup-locale.sh /usr/local/bin/setup-locale.sh
RUN chmod +x /usr/local/bin/setup-locale.sh
RUN /usr/local/bin/setup-locale.sh

ENV \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en

FROM config AS deps

ARG USERNAME

COPY ./scripts/system/install-deps.sh /usr/local/bin/install-deps.sh
RUN chmod +x /usr/local/bin/install-deps.sh

RUN /usr/local/bin/install-deps.sh

FROM deps AS user

ARG USERNAME
ARG USER_UID
ARG USER_GID
ARG USER_PASSWORD

COPY ./scripts/system/generate-user.sh /usr/local/bin/generate-user.sh
RUN chmod +x /usr/local/bin/generate-user.sh
RUN /usr/local/bin/generate-user.sh "${USERNAME}" "${USER_UID}" "${USER_GID}" "${USER_PASSWORD}"

FROM user AS systemd

RUN apt-get update && \
    apt-get install -y systemd systemd-sysv dbus tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# delete unused units systemd for container performance
RUN (cd /lib/systemd/system/sysinit.target.wants/; \
    for i in *; do [ $i = systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*

FROM systemd AS dots

ARG DOTFILES_DIR=.dotfiles
ARG CUSTOM_DOTS_URL=https://github.com/ZeiZel/dotfiles.git
ARG USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

RUN rm -rf /home/$USERNAME/$DOTFILES_DIR
RUN git clone $CUSTOM_DOTS_URL /home/$USERNAME/$DOTFILES_DIR
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME/$DOTFILES_DIR

FROM dots AS zsh

ARG USERNAME
ARG DOTFILES_DIR=.dotfiles

USER $USERNAME
WORKDIR /home/$USERNAME/$DOTFILES_DIR

RUN curl -kfsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/$USERNAME/$DOTFILES_DIR/zshrc/.zshrc
RUN ln -sf /home/$USERNAME/$DOTFILES_DIR/zshrc/.zshrc /home/$USERNAME/.zshrc \
    && ln -sf /home/$USERNAME/$DOTFILES_DIR/.gitconfig /home/$USERNAME/.gitconfig
RUN git clone https://github.com/zsh-users/antigen.git ~/antigen
RUN /bin/zsh -c 'source ~/antigen/antigen.zsh'
RUN mkdir -p ~/.config && stow .

# set zsh as default
RUN chsh -s /bin/zsh root || true
RUN chsh -s /bin/zsh $USERNAME || true
RUN echo "SHELL=/bin/zsh" >> /etc/default/useradd || true
RUN grep -qxF '/bin/zsh' /etc/shells || echo '/bin/zsh' >> /etc/shells

FROM zsh AS brew

ARG USE_INSECURE_REQ=1
ARG PROXY_URL
ARG PROXY_PORT
ARG USERNAME
ARG DOTFILES_DIR=.dotfiles

WORKDIR /home/$USERNAME

USER root

COPY ./scripts/brew/setup-env.sh    /usr/local/bin/setup-brew-env.sh
COPY ./scripts/proxy/setup-proxy.sh /usr/local/bin/setup-proxy.sh

RUN chmod +x /usr/local/bin/setup-brew-env.sh /usr/local/bin/setup-proxy.sh

RUN /usr/local/bin/setup-proxy.sh "${PROXY_URL}" "${PROXY_PORT}" "/tmp/proxy.env"
RUN /usr/local/bin/setup-brew-env.sh "${USE_INSECURE_REQ}" "/tmp/brew_env"
RUN mkdir -p /run && touch /run/.containerenv
RUN echo "USE_INSECURE_REQ=${USE_INSECURE_REQ}" >> /etc/environment

USER $USERNAME

RUN cp /tmp/brew_env ~/.brew_env && chmod 644 ~/.brew_env

RUN if [ "${USE_INSECURE_REQ}" = "1" ]; then \
      echo "insecure" > ~/.curlrc; \
    fi

RUN if [ -f /tmp/proxy.env ]; then \
      cat /tmp/proxy.env >> ~/.brew_env; \
    fi

RUN \
    set -a && \
    . ~/.brew_env && \
    set +a && \
    /bin/bash -c "$(curl -kfsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

RUN \
    REAL_ZSHRC=$(readlink -f ~/.zshrc || echo ~/.zshrc) \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$REAL_ZSHRC" \
    && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

RUN /bin/zsh -c ". /etc/profile.d/homebrew-env.sh && source /home/$USERNAME/.zshrc"

FROM brew AS brew-deps

ARG USERNAME
WORKDIR /home/$USERNAME
USER $USERNAME

RUN /bin/zsh -c '. ~/.zshrc && \
    set -a && \
    . ~/.brew_env && \
    set +a && \
    brew bundle --file=~/.config/Brewfile || true'

RUN /bin/zsh -c '. ~/.zshrc && \
    set -a && \
    . ~/.brew_env && \
    set +a && \
    brew install nvm || true'

FROM brew-deps AS tpm

ARG USERNAME

USER $USERNAME

RUN if [ ! -d ~/.tmux ]; then mkdir -p ~/.tmux; fi
RUN cd ~/.tmux || exit 1
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

RUN source $HOME/.local/bin/env || true
RUN source $HOME/.zshrc || true

RUN echo "Install ended! :)"

FROM tpm AS docker

ARG USERNAME

USER $USERNAME

RUN curl -o- https://get.docker.com | bash

USER root

COPY ./scripts/systemd/post-boot.sh /usr/local/bin/post-boot.sh
RUN \
    chmod +x /usr/local/bin/post-boot.sh && \
    chown root:root /usr/local/bin/post-boot.sh && \
    printf "[Unit]\nDescription=Post-Boot Initialization Script\nAfter=multi-user.target\n\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/post-boot.sh\nRemainAfterExit=yes\n\n[Install]\nWantedBy=multi-user.target\n" > /etc/systemd/system/post-boot.service && \
    systemctl enable post-boot.service

FROM docker AS final

ARG USERNAME

USER root

COPY ./scripts/systemd/post-boot.sh /usr/local/bin/post-boot.sh
COPY ./scripts/systemd/setup-systemd.sh /usr/local/bin/setup-systemd.sh

RUN chmod +x /usr/local/bin/post-boot.sh /usr/local/bin/setup-systemd.sh && \
    chown root:root /usr/local/bin/post-boot.sh /usr/local/bin/setup-systemd.sh

RUN /usr/local/bin/setup-systemd.sh "${USERNAME}" "/usr/local/bin/post-boot.sh"

ENV USERNAME=${USERNAME}
VOLUME ["/sys/fs/cgroup"]
WORKDIR /home/${USERNAME}
CMD ["/sbin/init"]
