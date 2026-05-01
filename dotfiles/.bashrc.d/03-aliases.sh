# 常用别名和环境变量设置

# 常用别名
alias ls='ls --color=auto'
alias ll='ls -alF --time-style="+%m-%d %H:%M:%S"'
alias la='ls -A'

alias trash='trash-put -v'
# alias rm='trash-put -v'
alias vim='nvim'
# alias svim='sudo -E nvim'

# 常用工具快捷命令
alias lzd='lazydocker'
alias dcp='docker compose'

# 网络相关
alias myip='curl -s ifconfig.me'
# 查看哪个进程占用了某个端口
alias port='sudo ss -tulnp | grep'

# 软件
alias comfyup='cd /mnt/github/comfyui-docker; touch ./custom_nodes/.update; docker compose restart; cd -'