ARG DISTRO_IMAGE=ubuntu
ARG DISTRO_VERSION=24.04

FROM docker.io/${DISTRO_IMAGE}:${DISTRO_VERSION}

ARG USERNAME=any
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG DOTFILES_DIR=.dotfiles

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    USER_NAME=${USERNAME} \
    USER_UID=${USER_UID} \
    USER_GID=${USER_GID}
ENV HOMEBREW_FORCE_BREWED_CURL=0 \
    HOMEBREW_NO_SSL=1 \
    CURLOPT_SSL_VERIFYPEER=0 \
    CURLOPT_SSL_VERIFYHOST=0 \
    HOMEBREW_INSTALL_FROM_API=1 \
    HOMEBREW_CURLRC=1

# locale install: en, ru
RUN apt update && \
    apt install -y locales && \
    locale-gen en_US.UTF-8 ru_RU.UTF-8 && \
    update-locale LANG=ru_RU.UTF-8 LC_MESSAGES=POSIX && \
    rm -rf /var/lib/apt/lists/*

# deps
RUN apt update
RUN apt-get autoremove && apt-get clean
RUN apt-get install -y \
        # Основные утилиты
        systemd dbus \
        sudo \
        curl \
        wget \
        gnupg \
        apt-transport-https \
        ca-certificates \
        xz-utils \
        unzip \
        zip \
        iputils-ping \
        # Git, CLI
        git \
        gh \
        glab \
        # Python
        python3 \
        python3-pip \
        python3-venv \
        # Текст и поиск
        nano \
        less \
        bash \
        make \
        gcc \
        cargo \
        bc \
        ed \
        gawk \
        findutils \
        diffutils \
        coreutils \
        # Инструменты
        fd-find \
        ripgrep \
        zoxide \
        jq \
        yq \
        poppler-utils \
        imagemagick \
        ffmpeg \
        ffmpegthumbnailer \
        p7zip-full \
        atool \
        watch \
        bc \
        --no-install-recommends
RUN apt install -y \
        btop \
        htop \
        thefuck \
        stow \
        eza \
        fzf
RUN apt install -y \
        zsh \
        zsh-antigen \
        zsh-syntax-highlighting \
        zsh-autosuggestions
RUN apt install -y \
        golang-go \
        zsh-antigen \
        nodejs \
        npm
RUN ln -sf /usr/bin/fd   /usr/local/bin/fd && \
    ln -sf /usr/bin/grep /usr/bin/ggrep && \
    ln -sf /usr/bin/sed  /usr/bin/gsed && \
    ln -sf /usr/bin/tar  /usr/bin/gtar
RUN rm -rf /var/lib/apt/lists/* && update-ca-certificates --fresh

# current user (add docker group, implement docker group, create current user, setting sudo)
RUN \
    if ! getent group docker >/dev/null; then \
        groupadd -g 999 docker; \
    fi; \
    \
    if getent group ${USER_GID} >/dev/null; then \
        existing_group=$(getent group ${USER_GID} | cut -d: -f1); \
        if [ "${existing_group}" != "${USERNAME}" ]; then \
            groupmod -n ${USERNAME} ${existing_group}; \
        fi; \
    else \
        groupadd --gid ${USER_GID} ${USERNAME}; \
    fi; \
    \
    if getent passwd ${USER_UID} >/dev/null; then \
        userdel $(getent passwd ${USER_UID} | cut -d: -f1); \
    fi; \
    \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/zsh ${USERNAME}; \
    \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
    \
    usermod -aG sudo ${USERNAME}; \
    usermod -aG docker ${USERNAME}; \
    \
    echo "User created: $(getent passwd ${USERNAME})"; \
    echo "Groups: $(groups ${USERNAME})"

USER $USERNAME
WORKDIR /home/$USERNAME

# dots
RUN cd ~/  \
    && git clone https://github.com/ZeiZel/dotfiles.git ~/${DOTFILES_DIR}
WORKDIR /home/$USERNAME/${DOTFILES_DIR}
RUN curl -kfsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash \
    && echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc \
    && { [ -f ~/${DOTFILES_DIR}/.zshrc ] && rm -rf ~/.zshrc && ln -sf ~/${DOTFILES_DIR}/.zshrc ~/.zshrc || true; } \
    && { [ -f ~/${DOTFILES_DIR}/.gitconfig ] && rm -rf ~/.gitconfig && ln -sf ~/${DOTFILES_DIR}/.gitconfig ~/.gitconfig || true; }
RUN git clone https://github.com/zsh-users/antigen.git ~/antigen
RUN /bin/zsh -c 'source ~/antigen/antigen.zsh'
RUN \
    cd ~/${DOTFILES_DIR} \
    && mkdir -p ~/.config \
    && rm ~/.zshrc \
    && ln -s ~/${DOTFILES_DIR}/zshrc/.zshrc ~/.zshrc \
    && stow .

# binary
WORKDIR /home/$USERNAME

RUN echo "insecure" > ~/.curlrc
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -kfsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
RUN echo >> /home/lvovvv/.zshrc \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/lvovvv/.zshrc \
    && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
RUN source ~/.zshrc || true
RUN cd ~/.config && brew bundle || true

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# docker
RUN curl -o- https://get.docker.com | bash
# RUN sudo systemctl docker start
# RUN sudo systemctl docker status

# tmux
RUN if [ ! -d ~/.tmux ]; then mkdir -p ~/.tmux; fi
RUN cd ~/.tmux || exit 1
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

RUN source $HOME/.local/bin/env || true
RUN source $HOME/.zshrc || true

RUN echo "Install ended! :)"

# tech
WORKDIR /mnt
CMD ["zsh"]