#!/usr/bin/env bash
set -e

echo "=== [1/6] Mise à jour du système et paquets de base ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget gnupg zsh zenity xdg-desktop-portal-gtk eza

echo "=== [2/6] Optimisation du file-watcher pour le dev ==="
cat << 'CONF' | sudo tee /etc/sysctl.d/60-vscode.conf
fs.inotify.max_user_watches=524288
CONF
sudo sysctl -p /etc/sysctl.d/60-vscode.conf

echo "=== [3/6] Installation de Visual Studio Code officiel ==="
curl -fsSL https://code-server.dev/install.sh | sh

echo" -> setup le no passwd mode"
mkdir -p ~/.config/code-server
cat << 'EOF' > ~/.config/code-server/config.yaml
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
    echo -e "\n# Bascule automatique vers ZSH\n$BASHRC_HOOK" >> "$HOME/.bashrc"
fi



echo "deploy config"
CONFIG_DIR=${HOME}/dev/googlebook/config

## zshrc
rm -f ~/.zshrc
ln -sf ${CONFIG_DIR}/zshrc ${HOME}/.zshrc

## theme
mkdir -p ~/.oh-my-zsh/custom/themes
ln -sf ${CONFIG_DIR}/plosco.zsh-theme ${HOME}/.oh-my-zsh/custom/themes/plosco.zsh-theme


echo
echo "======================================================="
echo " Installation terminée avec succès !"
echo "======================================================="
