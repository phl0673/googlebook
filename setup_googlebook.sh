#! /usr/bin/env bash

set -e
set -o pipefail

# ==========================================================
# Fonctions communes
# ==========================================================

# Fonctions d'affichage

if [[ -t 1 ]]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    ORANGE=$(tput setaf 208)
    BLUE=$(tput setaf 67)
    GRAY=$(tput setaf 244)
    RESET=$(tput sgr0)
else
    RED="" GREEN="" ORANGE="" BLUE="" GRAY="" RESET="" 
fi

log_box() {
    local title="  $1"
    local color="${2:-$BLUE}"
    local fd="${3:-1}"
    local inner_width=78
    local pad_len=$(( inner_width - ${#title} ))
    local border pad
    printf -v border '%*s' "$inner_width" ''
    border=${border// /─}
    printf -v pad '%*s' "$pad_len" ''

    printf "\n%s┌%s┐\n│%s%s│\n└%s┘%s\n\n" "$color" "$border" "$title" "$pad" "$border" "$RESET" >&"$fd"
}

log_banner() {
    local title=" $1 "
    local color="${2:-$BLUE}"
    local width=80
    local line
    printf -v line '%*s' "$width" ''
    line=${line// /═}

    printf "\n%s%s\n  %s\n%s%s\n\n" "$color" "$line" "$title" "$line" "$RESET"
}

log_green() {
  printf "%s%b%s\n" "$GREEN" "$*" "$RESET" ;
}
 
# shellcheck disable=SC2317
log_orange() {
  printf "%s%b%s\n" "$ORANGE" "$*" "$RESET" >&2;
}

# shellcheck disable=SC2317
log_red() {
  printf "%s%b%s\n" "$RED" "$*" "$RESET" >&2;
}

log_blue() {
  printf "%s%b%s\n" "$BLUE" "$*" "$RESET" ;
}

log_gray() {
  printf "%s%b%s\n" "$GRAY" "$*" "$RESET" ;
}

log_ignored()   { 
  log_gray "[IGNORED]\t${*}" 
}

log_info() {
  log_blue "[INFO]\t${*}"
}

# shellcheck disable=SC2317
log_warn() { 
  log_orange "[WARNING]\t${*}" 
}

log_err()  { 
  log_box "[ERROR]  ${*}" "$RED" 2
}

log_success()   { 
  log_green "[SUCCESS]\t${*}"
}

log() {
  log_banner "${*}" "${BLUE}"
}

die() {
  log_err "$*"
  exit 1
}

require_file() {
  [[ -f "$1" ]] || die "Fichier introuvable : $1"
}

link_config() {
  local source="$1"
  local target="$2"
  local backup

  require_file "$source"
  mkdir -p "$(dirname "$target")"

  # Le lien existe déjà et pointe au bon endroit
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    log_ignored "$target"
    return
  fi

  # Un ancien lien symbolique peut être remplacé
  if [[ -L "$target" ]]; then
    rm -- "$target"
  # Un fichier ou dossier existant est sauvegardé
  elif [[ -e "$target" ]]; then
    backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    mv -- "$target" "$backup"
    log_info "backup done: $target -> $backup"
  fi

  ln -s -- "$source" "$target"
  log_info "Link done: $source -> $target"
}

# ==========================================================
# Système et dépendances
# ==========================================================

log "Mise à jour du système et installation des paquets de base"
sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl wget gnupg zsh zenity xdg-desktop-portal-gtk eza bat tmux \
  build-essential ripgrep fd-find unzip nodejs lz4 python3 python3-venv openssl shellcheck

log_success "Mise à jour du système et installation des paquets de base"
# ==========================================================
# Oh My Zsh
# ==========================================================

log "Installation de Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  log_ignored "Oh My Zsh déjà installé"

fi

log "Configuration du switch automatique vers Zsh dans ~/.bashrc"
# shellcheck disable=SC2016
BASHRC_HOOK='if [ -t 1 ] && [ -x "$(command -v zsh)" ] && [ "$SHELL" != "$(command -v zsh)" ]; then
    export SHELL="$(command -v zsh)"
    exec zsh -l
fi'

if ! grep -qF 'exec zsh -l' "$HOME/.bashrc"; then
  printf '\n# Bascule automatique vers ZSH\n%s\n' "$BASHRC_HOOK" >> "$HOME/.bashrc"
else
  log_ignored "Bascule vers Zsh déjà configurée"
fi

log_success  "Installation & config de Oh My Zsh"
# ==========================================================
# Neovim
# ==========================================================

log "Installation de Neovim"
NVIM_VERSION="0.12.6"
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64) NVIM_PKG="nvim-linux-arm64" ;;
  x86_64|amd64) NVIM_PKG="nvim-linux-x86_64" ;;
  *) die "Architecture non prise en charge par ce script : $ARCH" ;;
esac

CURRENT_NVIM=""
if command -v nvim >/dev/null 2>&1; then
  CURRENT_NVIM="$(nvim --version | head -n 1 | sed 's/^NVIM v//')"
fi

if [[ "$CURRENT_NVIM" != "$NVIM_VERSION" ]]; then
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  NVIM_ARCHIVE="${NVIM_PKG}.tar.gz"
  curl -fL "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/${NVIM_ARCHIVE}" \
    -o "$TMP_DIR/$NVIM_ARCHIVE"
  tar -xzf "$TMP_DIR/$NVIM_ARCHIVE" -C "$TMP_DIR"
  sudo rm -rf /opt/nvim
  sudo mv "$TMP_DIR/$NVIM_PKG" /opt/nvim
  sudo ln -sfn /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -rf "$TMP_DIR"
  trap - EXIT
else
  log_ignored "Neovim $NVIM_VERSION déjà installé"
fi

log_success "Installation & config de Neovim"
# ==========================================================
# LazyVim
# ==========================================================

log "Installation de LazyVim"
mkdir -p "$HOME/.config"
if [[ ! -d "$HOME/.config/nvim" ]]; then
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
else
  log_ignored "Configuration Neovim déjà présente"
fi

log_success "Installation & config de LazyVim"

# ==========================================================
# Déploiement des configurations
# ==========================================================

log "Déploiement des configurations"
CONFIG_DIR="$HOME/dev/googlebook/config"
[[ -d "$CONFIG_DIR" ]] || die "Dossier config introuvable : $CONFIG_DIR"

# Zsh
link_config "$CONFIG_DIR/zshrc" "$HOME/.zshrc"

# Thème Oh My Zsh
mkdir -p "$HOME/.oh-my-zsh/custom/themes"
link_config "$CONFIG_DIR/plosco.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/plosco.zsh-theme"

# Vim
link_config "$CONFIG_DIR/vimrc" "$HOME/.vimrc"

# Neovim / LazyVim
link_config "$CONFIG_DIR/lazy.lua" "$HOME/.config/nvim/lua/config/lazy.lua"
link_config "$CONFIG_DIR/shell.lua" "$HOME/.config/nvim/lua/plugins/shell.lua"
link_config "$CONFIG_DIR/theme.lua" "$HOME/.config/nvim/lua/plugins/theme.lua"
link_config "$CONFIG_DIR/options.lua" "$HOME/.config/nvim/lua/config/options.lua"
link_config "$CONFIG_DIR/keymaps.lua" "$HOME/.config/nvim/lua/config/keymaps.lua"
if [[ -f "$CONFIG_DIR/formatting.lua" ]]; then
  link_config "$CONFIG_DIR/formatting.lua" "$HOME/.config/nvim/lua/plugins/formatting.lua"
fi

log_success "Configuration des outils (zsh, vim, lazy)"

# ==========================================================
# Synchronisation des plugins et outils LSP
# ==========================================================

log "Synchronisation de LazyVim et installation des outils Mason"
nvim --headless "+Lazy! sync" +qa
nvim --headless "+Lazy! load mason.nvim" \
  "+MasonInstall bash-language-server shellcheck shfmt" +qa
echo
log_success "Outils LSP"

# ==========================================================
# 1Password CLI
# ==========================================================

log "Installation de 1Password CLI"

if ! command -v op >/dev/null 2>&1; then
  OP_ARCH="$(dpkg --print-architecture)"

  case "$OP_ARCH" in
    amd64|arm64) ;;
    *) die "Architecture non prise en charge par 1Password CLI : $OP_ARCH" ;;
  esac

  sudo install -d -m 755 /usr/share/keyrings

  curl -sS https://downloads.1password.com/linux/keys/1password.asc |
    sudo gpg --dearmor --yes \
      --output /usr/share/keyrings/1password-archive-keyring.gpg

  echo "deb [arch=$OP_ARCH signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$OP_ARCH stable main" |
    sudo tee /etc/apt/sources.list.d/1password.list >/dev/null

  sudo install -d /etc/debsig/policies/AC2D62742012EA22
  curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol |
    sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null

  sudo install -d /usr/share/debsig/keyrings/AC2D62742012EA22
  curl -sS https://downloads.1password.com/linux/keys/1password.asc |
    sudo gpg --dearmor --yes \
      --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

  sudo apt update
  sudo apt install -y 1password-cli
else
  log_ignored "1Password CLI déjà installé : $(op --version)"
fi

log_success "Installation de 1Password CLI"

# ==========================================================
# 1Password CLI - Service Account
# ==========================================================

log "Préparation de 1Password CLI"

OP_CONFIG_DIR="$HOME/.config/1password"
OP_TOKEN_FILE="$OP_CONFIG_DIR/service-account-token"

mkdir -p "$OP_CONFIG_DIR"
chmod 700 "$OP_CONFIG_DIR"

if [[ ! -e "$OP_TOKEN_FILE" ]]; then
  install -m 600 /dev/null "$OP_TOKEN_FILE"
  log_info "Token file created: $OP_TOKEN_FILE"
else
  chmod 600 "$OP_TOKEN_FILE"
  log_ignored "Token 1Password déjà présent"
fi

log_success "Préparation de 1Password CLI"

# ==========================================================
# Synology Decrypt
# ==========================================================

log "Installation de Synology Decrypt"
SYNOLOGY_DECRYPT_DIR="$HOME/dev/synology-decrypt"
SYNOLOGY_DECRYPT_REPO="https://github.com/phl0673/synology-decrypt.git"
SYNOLOGY_DECRYPT_BRANCH="fix-absolute-input-path"
VENV_DIR="$HOME/.venv"
PASSWORD_DIR="$HOME/.config/synology-decrypt"
PRIVATE_KEY_FILE="$PASSWORD_DIR/private.pem"

mkdir -p "$HOME/dev" "$PASSWORD_DIR"
chmod 700 "$PASSWORD_DIR"

if [[ ! -d "$SYNOLOGY_DECRYPT_DIR" ]]; then
  git clone --branch "$SYNOLOGY_DECRYPT_BRANCH" "$SYNOLOGY_DECRYPT_REPO" "$SYNOLOGY_DECRYPT_DIR"
else
  if [[ ! -d "$SYNOLOGY_DECRYPT_DIR/.git" ]]; then
    die "Le dossier existe mais n'est pas un dépôt Git : $SYNOLOGY_DECRYPT_DIR"
  fi

  CURRENT_BRANCH="$(git -C "$SYNOLOGY_DECRYPT_DIR" branch --show-current)"
  if [[ "$CURRENT_BRANCH" != "$SYNOLOGY_DECRYPT_BRANCH" ]]; then
    die "Branche incorrecte dans Synology Decrypt : $CURRENT_BRANCH (attendu : $SYNOLOGY_DECRYPT_BRANCH)"
  fi

  log_ignored "Dépôt Synology Decrypt déjà présent sur la branche $CURRENT_BRANCH"
fi

if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  python3 -m venv "$VENV_DIR"
else
  "$VENV_DIR/bin/python" -m pip install --upgrade pip
fi

"$VENV_DIR/bin/python" -m pip install pycryptodomex docopt
PYTHONPATH="$SYNOLOGY_DECRYPT_DIR" \
  "$VENV_DIR/bin/python" -m syndecrypt --help

# Récupération de la clé privée depuis 1Password
if [[ -s "$PRIVATE_KEY_FILE" ]]; then
  chmod 600 "$PRIVATE_KEY_FILE"
  openssl pkey -in "$PRIVATE_KEY_FILE" -noout -check >/dev/null \
    || die "La clé privée existante est invalide"
  log_ignored "Clé privée déjà présente et valide"
else
  OP_TOKEN_FILE="$HOME/.config/1password/service-account-token"

  SKIP_PRIVATE_KEY_SETUP=0

  if [[ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
    if [[ -s "$OP_TOKEN_FILE" ]]; then
      OP_SERVICE_ACCOUNT_TOKEN="$(< "$OP_TOKEN_FILE")"
      export OP_SERVICE_ACCOUNT_TOKEN
    else
      echo
      log_info "Configuration 1Password nécessaire."
      log_info "Renseigne ton Service Account token dans :"
      log_info "  $OP_TOKEN_FILE"
      log_info
      log_info "Puis relance ce script pour récupérer la clé privée."
      SKIP_PRIVATE_KEY_SETUP=1
    fi
  fi

  if [[ "$SKIP_PRIVATE_KEY_SETUP" -eq 0 ]]; then
    umask 077
    TMP_KEY="$(mktemp "$PASSWORD_DIR/.private.pem.XXXXXX")"

    # shellcheck disable=SC2317
    cleanup_private_key() {
      if [[ -n "${TMP_KEY:-}" && -e "$TMP_KEY" ]]; then
        rm -f -- "$TMP_KEY"
      fi
    }
    trap cleanup_private_key EXIT

    op read \
      "op://cli-access-only/syno-google-encryption/private_key" \
      > "$TMP_KEY" || die "Impossible de récupérer la clé privée depuis 1Password"

    [[ -s "$TMP_KEY" ]] || die "La clé privée récupérée est vide"

    openssl pkey -in "$TMP_KEY" -noout -check >/dev/null \
      || die "La clé privée récupérée est invalide"

    chmod 600 "$TMP_KEY"
    mv -- "$TMP_KEY" "$PRIVATE_KEY_FILE"
    TMP_KEY=""

    trap - EXIT

    log_info "Clé privée récupérée et validée depuis 1Password"
  fi
fi

if [[ -s "$PRIVATE_KEY_FILE" ]]; then
  echo
  log_info "Clé privée Synology :"
  log_info "  $PRIVATE_KEY_FILE"
  log_info "Permissions : 600"
  log_info "Commande de déchiffrement :"
  log_info "  $VENV_DIR/bin/python -m syndecrypt -k \"$PRIVATE_KEY_FILE\" -O <dossier_sortie> <fichier_chiffré>..."
fi

log_success "Installation de Synology Decrypt"

log_box "Setup terminé avec succès" "$GREEN"

exit 0
