#!/bin/bash

query=$(rofi -dmenu -p "搜索" -l 1 -theme-str 'listview { lines: 0; }' "$@")

if [ -n "$query" ]; then
    encoded=$(printf '%s' "$query" | jq -sRr @uri)
    exec "$(dirname "$0")/run-browser.sh" "https://www.google.com/search?q=${encoded}"
fi
