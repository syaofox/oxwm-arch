set fish_greeting
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx HF_ENDPOINT https://hf-mirror.com
set -gx UV_CACHE_DIR "/mnt/github/.caches/uv"
set -gx BAT_THEME "Nord"
set -gx NVM_DIR "$HOME/.config/nvm"

fish_add_path "$HOME/.local/bin"
if test -d $HOME/.opencode/bin
    fish_add_path $HOME/.opencode/bin
end
