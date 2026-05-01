__git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null)
    [[ -n "$branch" ]] && echo " $branch"
}


PS1='\[\033[38;2;122;162;247m\]\w\[\033[0m\]\[\033[38;2;134;134;134m\]$(__git_branch)\[\033[0m\]\n\[\033[1;38;2;187;154;247m\]> \[\033[0m\]'