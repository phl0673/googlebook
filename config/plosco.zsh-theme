
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
