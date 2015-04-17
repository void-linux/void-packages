autoload -Uz fzf-file-widget
autoload -Uz fzf-cd-widget
autoload -Uz fzf-history-widget

zle -N fzf-file-widget
zle -N fzf-cd-widget
zle -N fzf-history-widget

bindkey '^T' fzf-file-widget
bindkey '\ec' fzf-cd-widget
bindkey '^R' fzf-history-widget
