if status is-interactive
    alias ls='ls --color=auto'
    alias ll='ls -alF --time-style="+%m-%d %H:%M:%S"'
    alias la='ls -A'
    alias cat="bat"
    alias trash='trash-put -v'
    alias comfyup='cd /mnt/github/comfyui-docker; touch ./custom_nodes/.update; docker compose restart; cd -'
    alias lzd='lazydocker'
    alias dcp='docker compose'
    alias myip='curl -s ifconfig.me'
    alias port='sudo ss -tulnp | grep'

    alias battheme='bat --list-themes | fzf --preview "bat --theme={} --color=always --style=numbers ~/.config/fish/config.fish"'

    abbr -a v  nvim
    abbr -a vi nvim
    abbr -a vim nvim
end
