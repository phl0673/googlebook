#!/usr/bin/env bash
set -e

echo "=== [1/6] Mise à jour du système et paquets de base ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget gnupg zsh zenity xdg-desktop-portal-gtk eza bat tmux

echo "=== [2/6] Optimisation du file-watcher pour le dev ==="
cat <<'CONF' | sudo tee /etc/sysctl.d/60-vscode.conf
fs.inotify.max_user_watches=524288
CONF
sudo sysctl -p /etc/sysctl.d/60-vscode.conf

echo "=== [3/6] Installation de Visual Studio Code officiel ==="
curl -fsSL https://code-server.dev/install.sh | sh

echo " -> setup le no passwd mode"
mkdir -p ~/.config/code-server
cat <<'EOF' >~/.config/code-server/config.yaml
bind-addr: 0.0.0.0:8080
auth: none
cert: false
EOF
echo " -> force le server au demarrage de la VM"
systemctl --user enable --now code-server
systemctl --user status code-server --no-pager || true
echo " -> utilise http://localhost:8080 pour utiliser code-server"

echo "code-server [OK]"

echo "=== [4/6] Installation de Oh My Zsh ==="
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  # --unattended évite qu'il ne bloque le script pour demander confirmation ou basculer le shell
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "=== [5/6] Configuration du switch automatique vers Zsh dans ~/.bashrc ==="
BASHRC_HOOK='if [ -t 1 ] && [ -x "$(command -v zsh)" ] && [ "$SHELL" != "$(command -v zsh)" ]; then
    export SHELL="$(command -v zsh)"
    exec zsh -l
fi'

if ! grep -q "exec zsh -l" "$HOME/.bashrc"; then
  echo -e "\n# Bascule automatique vers ZSH\n$BASHRC_HOOK" >>"$HOME/.bashrc"
fi

echo "deploy config"
CONFIG_DIR=${HOME}/dev/googlebook/config

## zshrc
rm -f ${HOME}/.zshrc
ln -sf ${CONFIG_DIR}/zshrc ${HOME}/.zshrc

## theme
mkdir -p ${HOME}/.oh-my-zsh/custom/themes
ln -sf ${CONFIG_DIR}/plosco.zsh-theme ${HOME}/.oh-my-zsh/custom/themes/plosco.zsh-theme

## vimrc
rm -f ${HOME}/.vimrc
ln -sf ${CONFIG_DIR}/vimrc ${HOME}/.vimrc

## keyboards binding vscode
rm -f ${HOME}/.local/share/code-server/User/keybindings.json
ln -sf ${CONFIG_DIR}/keybindings.json ${HOME}/.local/share/code-server/User/keybindings.json

## Keyboard layout azerty / hack to cope with xwayland bug
sudo cp /usr/share/X11/xkb/symbols/us /usr/share/X11/xkb/symbols/us.bk
sudo cp /usr/share/X11/xkb/symbols/fr /usr/share/X11/xkb/symbols/us

## neovim
sudo apt update && sudo apt install -y git curl build-essential ripgrep fd-find unzip nodejs npm
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
  NVIM_PKG="nvim-linux-arm64"
else
  NVIM_PKG="nvim-linux-x86_64"
fi

curl -LO "https://github.com/neovim/neovim/releases/download/v0.12.6/${NVIM_PKG}.tar.gz"
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf "${NVIM_PKG}.tar.gz"
sudo mv "/opt/${NVIM_PKG}" /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
rm -f "${NVIM_PKG}.tar.gz"

## lazyvim
if [ -d ~/.config/nvim ]; then
  rm -rf ~/.config/nvim.bak
  mv ~/.config/nvim ~/.config/nvim.bak
fi

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

ln -sf ${CONFIG_DIR}/lazy.lua ~/.config/nvim/lua/config/lazy.lua
ln -sf ${CONFIG_DIR}/shell.lua ~/.config/nvim/lua/plugins/shell.lua
ln -sf ${CONFIG_DIR}/theme.lua ~/.config/nvim/lua/plugins/theme.lua
ln -sf ${CONFIG_DIR}/options.lua ~/.config/nvim/lua/config/options.lua
ln -sf ${CONFIG_DIR}/keymaps.lua ~/.config/nvim/lua/config/keymaps.lua

## load
nvim --headless "+Lazy! sync" +qa
nvim --headless "+MasonInstall bash-language-server shellcheck shfmt" +qa

echo
echo "======================================================="
echo " Installation terminée avec succès !"
echo "======================================================="

exit 0
