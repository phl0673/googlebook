
# function toon {
#   echo -n "➜ "
# }

# function toon {
#   echo -n "%(?.%{$fg[green]%}.%{$fg[red]%})➜%{$reset_color%} "
# }

# function python_virtualenv_info {
#   if [ -n "$VIRTUAL_ENV" ]; then
#     echo "%{$fg[yellow]%}($(basename "$VIRTUAL_ENV"))%{$reset_color%}"
#   fi
# }


# PROMPT='$fg[white]%}$(toon) $fg_bold[blue][ $fg[yellow]%D %t $fg_bold[blue]] $fg_bold[blue] [ $fg[cyan]%n@%m:%~/ $(git_prompt_info)$fg[yellow] $fg_bold[blue]]$reset_color
# $ '

# # git theming
# ZSH_THEME_GIT_PROMPT_PREFIX="$fg[green]("
# ZSH_THEME_GIT_PROMPT_SUFFIX="$fg[green])"
# ZSH_THEME_GIT_PROMPT_CLEAN="$fg[green]✔"
# ZSH_THEME_GIT_PROMPT_DIRTY="$fg[red]✗"


# Flèche d'état adoucie (vert menthe / rouge brique doux)
function toon {
  echo -n "%(?.%F{114}.%F{167})➜%f "
}

# Venv Python doux (ambre/sable)
function python_virtualenv_info {
  if [ -n "$VIRTUAL_ENV" ]; then
    echo " %F{215}($(basename "$VIRTUAL_ENV"))%f"
  fi
}

# Prompt principal
# 242 = gris ardoise doux pour les crochets
# 222 = jaune sable / vanille pour la date
# 110 = bleu pastel pour user@host
# 151 = vert sauge / cyan feutré pour le path
PROMPT='%F{242}[ %F{222}%D %t %F{242}] [ %F{110}%n@%m%F{242}:%F{151}%~ $(git_prompt_info)$(python_virtualenv_info)%F{242} ]%f
$(toon)$ '

# Thème Git moins agressif
# 114 = vert sauge doux
# 167 = corail / rouge brique
ZSH_THEME_GIT_PROMPT_PREFIX="%F{114}("
ZSH_THEME_GIT_PROMPT_SUFFIX="%F{114})"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{114}✔"
ZSH_THEME_GIT_PROMPT_DIRTY="%F{167}✗"
