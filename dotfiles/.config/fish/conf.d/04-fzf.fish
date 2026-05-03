# 查看所有绑定 fish -i -c "bind"

if status is-interactive
    stty -ixon
    
    set fzf_preview_dir_cmd exa --all --color=always  # 使用 exa 代替 ls 预览目录
    set fzf_fd_opts --hidden --exclude=.git          # 让 fd 搜索隐藏文件但排除 .git

    # 先声明你想用的快捷键
    fzf_configure_bindings \
        --history=\cr \
        --directory=\co \
        --processes=\cp \
        --git_log=\cg \
        --git_status=\cs 
end
