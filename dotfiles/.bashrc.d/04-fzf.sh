# Example	                                Description
# CTRL-t	                                Look for files and directories
# CTRL-r	                                Look through command history
# Enter	                                    Select the item
# Ctrl-j or Ctrl-n or Down arrow	        Go down one result
# Ctrl-k or Ctrl-p or Up arrow	            Go up one result
# Tab	                                    Mark a result
# Shift-Tab	                                Unmark a result
# cd **Tab	                                Open up fzf to find directory
# export **Tab	                            Look for env variable to export
# unset **Tab	                            Look for env variable to unset
# unalias **Tab	                            Look for alias to unalias
# ssh **Tab	                                Look for recently visited host names
# kill -9 **Tab	                            Look for process name to kill to get pid
# any command (like nvim or code) + **Tab	Look for files & directories to complete command

[ -d "$HOME/.fzf/bin" ] && PATH="$HOME/.fzf/bin:$PATH"
eval "$(fzf --bash)"

# -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

fz-menu() {
    fzf --multi \
        --height 50% --layout=reverse --border \
        --header "➜ Ctrl-A:全选 | Ctrl-D:取消 | Ctrl-R:反选" \
        --bind "ctrl-a:select-all,ctrl-d:deselect-all,ctrl-r:toggle-all"
}