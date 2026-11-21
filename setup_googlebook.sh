#!/usr/bin/env bash
set -e

# ==========================================================
# Fonctions communes
# ==========================================================

log() {
  echo
  echo "=== $1 ==="
}

die() {
  echo "[ERROR] $*" >&2
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
    echo "[OK] $target"
    return
  fi

  # Un ancien lien symbolique peut être remplacé
  if [[ -L "$target" ]]; then
    rm -- "$target"
  # Un fichier ou dossier existant est sauvegardé
  elif [[ -e "$target" ]]; then
    backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    mv -- "$target" "$backup"
    echo "[BACKUP] $target -> $backup"
  fi

  ln -s -- "$source" "$target"
  echo "[LINK] $target"
}

# ==========================================================
# Système et dépendances
# ==========================================================

log "Mise à jour du système et installation des paquets de base"
sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl wget gnupg zsh zenity xdg-desktop-portal-gtk eza bat tmux \
  build-essential ripgrep fd-find unzip nodejs npm

# ==========================================================
# Oh My Zsh
# ==========================================================

log "Installation de Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "[OK] Oh My Zsh déjà installé"
fi

log "Configuration du switch automatique vers Zsh dans ~/.bashrc"
BASHRC_HOOK='if [ -t 1 ] && [ -x "$(command -v zsh)" ] && [ "$SHELL" != "$(command -v zsh)" ]; then
    export SHELL="$(command -v zsh)"
    exec zsh -l
fi'

if ! grep -qF 'exec zsh -l' "$HOME/.bashrc"; then
  printf '\n# Bascule automatique vers ZSH\n%s\n' "$BASHRC_HOOK" >> "$HOME/.bashrc"
else
  echo "[OK] Bascule vers Zsh déjà configurée"
fi

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
  echo "[OK] Neovim $NVIM_VERSION déjà installé"
fi

# ==========================================================
# LazyVim
# ==========================================================

log "Installation de LazyVim"
if [[ ! -d "$HOME/.config/nvim" ]]; then
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
else
  echo "[OK] Configuration Neovim déjà présente"
fi

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

# ==========================================================
# Synchronisation des plugins et outils LSP
# ==========================================================

log "Synchronisation de LazyVim et installation des outils Mason"
nvim --headless "+Lazy! sync" +qa
nvim --headless "+MasonInstall bash-language-server shellcheck shfmt" +qa

log "Installation terminée avec succès !"
exit 0
