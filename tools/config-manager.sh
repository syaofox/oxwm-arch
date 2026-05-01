#!/bin/bash

# ============================================================
# 配置文件备份/还原脚本（fzf 交互版）
# 功能：备份/还原 ssh/gnupg/dconf/fcitx5 配置
# ============================================================

# set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_BASE_DIR="${PROJECT_ROOT}/backups"

# ======================= 安全检查：禁止 root 运行 =======================
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}错误: 请不要使用 root 用户或 sudo 运行此脚本！${NC}"
    echo "此脚本会备份当前用户的配置（$HOME 下的文件）。"
    echo "请使用普通用户身份直接运行，不要加 sudo。"
    exit 1
fi

# ======================= 辅助函数 =======================
press_enter() {
    echo ""
    read -p "按回车键继续..."
}

yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local ans
    while true; do
        if [[ "$default" == "y" ]]; then
            read -p "$prompt [Y/n]: " ans
        else
            read -p "$prompt [y/N]: " ans
        fi
        ans=${ans:-$default}
        case "$ans" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "请输入 y 或 n" ;;
        esac
    done
}

# ======================= 备份单个项目 =======================
backup_item() {
    local src="$1"
    local dest="$2"
    local desc="$3"

    if [ -L "$src" ]; then
        local link_target
        link_target=$(readlink -f "$src")
        if [[ "$link_target" == "$PROJECT_ROOT"* ]]; then
            echo -e "${YELLOW}[SKIP]${NC} $desc (软链接指向项目目录，跳过)"
            return 1
        else
            mkdir -p "$(dirname "$dest")"
            cp -rL "$src" "$dest" 2>/dev/null || {
                echo -e "${RED}[FAIL]${NC} $desc (复制失败)"
                return 1
            }
            echo -e "${GREEN}[OK]${NC} $desc (复制实际内容)"
            return 0
        fi
    elif [ -d "$src" ]; then
        mkdir -p "$dest"
        rsync -a --no-perms --no-owner --no-group "$src"/ "$dest"/ 2>/dev/null || {
            echo -e "${RED}[FAIL]${NC} $desc (复制失败)"
            return 1
        }
        echo -e "${GREEN}[OK]${NC} $desc"
        return 0
    elif [ -f "$src" ]; then
        mkdir -p "$(dirname "$dest")"
        cp -p "$src" "$dest" 2>/dev/null || {
            echo -e "${RED}[FAIL]${NC} $desc (复制失败)"
            return 1
        }
        echo -e "${GREEN}[OK]${NC} $desc"
        return 0
    else
        echo -e "${YELLOW}[SKIP]${NC} $desc (不存在，跳过)"
        return 1
    fi
}

# ======================= fzf 选择函数 =======================
fzf_select_backup_items() {
    local items=("ssh    - SSH 配置 (含密钥)"
                 "gnupg  - GPG 配置 (含密钥)"
                 "dconf  - dconf 配置 (GNOME/GTK 设置)"
                 "fcitx5 - Fcitx5 输入法配置")
    local keys=("ssh" "gnupg" "dconf" "fcitx5")
    local selected=()

    if ! command -v fzf &>/dev/null; then
        echo -e "${YELLOW}fzf 未安装，使用传统选择方式${NC}" >&2
        return 1
    fi

    mapfile -t chosen < <(printf '%s\n' "${items[@]}" | fzf --multi --prompt="选择备份项目 > " --header="TAB/ctrl-a: 多选/全选 / ENTER: 确认 / ESC: 取消" --bind "ctrl-a:toggle-all")
    
    for desc in "${chosen[@]}"; do
        case "$desc" in
            "ssh"*)    selected+=("ssh") ;;
            "gnupg"*)  selected+=("gnupg") ;;
            "dconf"*)  selected+=("dconf") ;;
            "fcitx5"*) selected+=("fcitx5") ;;
        esac
    done

    printf '%s\n' "${selected[@]}"
}

fzf_select_restore_file() {
    local files=()
    mapfile -t files < <(find "$BACKUP_BASE_DIR" -maxdepth 1 -name "backup_*.tar.gz" -type f 2>/dev/null | sort -r)

    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${YELLOW}未找到任何备份文件${NC}" >&2
        return 1
    fi

    if ! command -v fzf &>/dev/null; then
        echo -e "${YELLOW}fzf 未安装，使用传统选择方式${NC}" >&2
        return 1
    fi

    local formatted
    formatted=$(for i in "${!files[@]}"; do
        name=$(basename "${files[$i]}")
        size=$(du -h "${files[$i]}" 2>/dev/null | cut -f1)
        printf "%s|%s|%s\n" "$i" "$name" "$size"
    done | fzf --prompt="选择备份文件 > " --header="ENTER: 确认 / ESC: 取消" --preview='echo {} | cut -d"|" -f2 | xargs -I{} tar -tzf "'"$BACKUP_BASE_DIR"'/{}" 2>/dev/null | head -20' | cut -d'|' -f1)

    if [[ -z "$formatted" ]]; then
        return 1
    fi

    echo "${files[$formatted]}"
}

fzf_select_restore_items() {
    local available_keys=()
    local available_desc=()
    local selected=()

    for item in ssh gnupg dconf fcitx5; do
        if [ -d "$1/$item" ]; then
            case "$item" in
                ssh)    desc="SSH 配置 (含密钥)" ;;
                gnupg)  desc="GPG 配置 (含密钥)" ;;
                dconf)  desc="dconf 配置 (GNOME/GTK 设置)" ;;
                fcitx5) desc="Fcitx5 输入法配置" ;;
                *)      desc="$item" ;;
            esac
            available_keys+=("$item")
            available_desc+=("$item - $desc")
        fi
    done

    if [ ${#available_keys[@]} -eq 0 ]; then
        echo -e "${YELLOW}备份文件中没有可还原的配置项${NC}" >&2
        return 1
    fi

    if ! command -v fzf &>/dev/null; then
        echo -e "${YELLOW}fzf 未安装，使用传统选择方式${NC}" >&2
        return 1
    fi

    mapfile -t chosen < <(printf '%s\n' "${available_desc[@]}" | fzf --multi --prompt="选择还原项目 > " --header="TAB/ctrl-a: 多选/全选 / ENTER: 确认 / ESC: 取消" --bind "ctrl-a:toggle-all")

    for desc in "${chosen[@]}"; do
        case "$desc" in
            "ssh"*)    selected+=("ssh") ;;
            "gnupg"*)  selected+=("gnupg") ;;
            "dconf"*)  selected+=("dconf") ;;
            "fcitx5"*) selected+=("fcitx5") ;;
        esac
    done

    printf '%s\n' "${selected[@]}"
}

# ======================= 备份功能 =======================
do_backup() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="${BACKUP_BASE_DIR}/backup_${TIMESTAMP}"
    mkdir -p "$BACKUP_DIR"

    BACKUP_COUNT=0
    SKIP_COUNT=0

    local available_mb
    available_mb=$(df -m "$BACKUP_BASE_DIR" 2>/dev/null | awk 'NR==2 {print $4}')
    if [ -z "$available_mb" ] || [ "$available_mb" -lt 100 ]; then
        echo -e "${RED}磁盘空间不足！可用空间: ${available_mb:-?}MB，需要至少 100MB${NC}"
        return 1
    fi

    echo ""
    echo "========================================"
    echo "          备份配置向导"
    echo "========================================"

    SELECTED=()
    if command -v fzf &>/dev/null; then
        mapfile -t SELECTED < <(fzf_select_backup_items)
    else
        # 传统方式
        BACKUP_ITEMS_DESC=(
            "ssh    - SSH 配置 (含密钥)"
            "gnupg  - GPG 配置 (含密钥)"
            "dconf  - dconf 配置 (GNOME/GTK 设置)"
            "fcitx5 - Fcitx5 输入法配置"
        )
        BACKUP_ITEM_KEYS=("ssh" "gnupg" "dconf" "fcitx5")

        echo "可选备份项目:"
        for i in "${!BACKUP_ITEMS_DESC[@]}"; do
            printf "  %2d) %s\n" $((i+1)) "${BACKUP_ITEMS_DESC[$i]}"
        done
        echo "----------------------------------------"
        echo "输入编号选择 (多个用逗号分隔，如 1,3,4)，输入 'all' 全选，直接回车取消"
        read -p "你的选择: " choice

        if [[ -z "$choice" ]]; then
            echo -e "${YELLOW}未选择任何项目，退出备份${NC}"
            return 0
        fi

        if [[ "$choice" == "all" ]]; then
            SELECTED=("${BACKUP_ITEM_KEYS[@]}")
        else
            IFS=',' read -ra nums <<< "$choice"
            for num in "${nums[@]}"; do
                num=$(echo "$num" | xargs)
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#BACKUP_ITEM_KEYS[@]} ]; then
                    SELECTED+=("${BACKUP_ITEM_KEYS[$((num-1))]}")
                fi
            done
        fi
    fi

    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        echo -e "${RED}没有有效的选择${NC}"
        return 1
    fi

    echo ""
    echo "即将备份以下项目: ${SELECTED[*]}"
    yes_no "确认开始备份？" "y" || return 0

    umask 077

    for item in "${SELECTED[@]}"; do
        case "$item" in
            ssh)
                backup_item "$HOME/.ssh" "$BACKUP_DIR/ssh" "SSH 配置目录" && ((BACKUP_COUNT++)) || ((SKIP_COUNT++))
                ;;
            gnupg)
                backup_item "$HOME/.gnupg" "$BACKUP_DIR/gnupg" "GPG 配置目录" && ((BACKUP_COUNT++)) || ((SKIP_COUNT++))
                ;;
            dconf)
                if command -v dconf &>/dev/null; then
                    mkdir -p "$BACKUP_DIR/dconf"
                    if dconf dump / > "$BACKUP_DIR/dconf/dconf.ini" 2>/dev/null; then
                        echo -e "${GREEN}[OK]${NC} dconf 配置导出"
                        ((BACKUP_COUNT++))
                    else
                        echo -e "${RED}[FAIL]${NC} dconf 导出失败"
                        ((SKIP_COUNT++))
                    fi
                else
                    echo -e "${YELLOW}[SKIP]${NC} dconf (命令未安装)"
                    ((SKIP_COUNT++))
                fi
                ;;
            fcitx5)
                backup_item "$HOME/.config/fcitx5" "$BACKUP_DIR/fcitx5" "Fcitx5 配置" && ((BACKUP_COUNT++)) || ((SKIP_COUNT++))
                ;;
        esac
    done

    cat > "$BACKUP_DIR/backup_info.txt" << EOF
配置文件备份信息
==================
备份时间: $(date)
备份目录: $BACKUP_DIR
系统信息: $(uname -a)
用户: $USER
主目录: $HOME
备份统计: 成功 $BACKUP_COUNT 项，跳过 $SKIP_COUNT 项
备份内容: ${SELECTED[@]}
注意: SSH/GPG 私钥已备份，请加密存储此压缩包。
EOF

    ARCHIVE_NAME="${BACKUP_BASE_DIR}/backup_${TIMESTAMP}.tar.gz"
    cd "$BACKUP_BASE_DIR" || { echo "无法进入备份目录"; return 1; }
    chmod -R 700 "backup_${TIMESTAMP}/ssh" "backup_${TIMESTAMP}/gnupg" 2>/dev/null || true
    find "backup_${TIMESTAMP}/ssh" "backup_${TIMESTAMP}/gnupg" -type f -exec chmod 600 {} \; 2>/dev/null || true
    if tar -cpzf "$ARCHIVE_NAME" "backup_${TIMESTAMP}"; then
        ARCHIVE_SIZE=$(du -h "$ARCHIVE_NAME" | cut -f1)
        rm -rf "$BACKUP_DIR"
        echo ""
        echo "========================================"
        echo "          备份完成！"
        echo "========================================"
        echo "文件: $ARCHIVE_NAME"
        echo "大小: $ARCHIVE_SIZE"
        echo "成功: $BACKUP_COUNT 项"
        echo "跳过: $SKIP_COUNT 项"
        echo ""
        echo -e "${YELLOW}⚠️ SSH/GPG/dconf 已备份，请妥善保管。${NC}"
        press_enter
    else
        echo -e "${RED}打包失败，临时目录保留在: $BACKUP_DIR${NC}"
        press_enter
        return 1
    fi
}

# ======================= 还原功能 =======================
do_restore() {
    mapfile -t BACKUP_FILES < <(find "$BACKUP_BASE_DIR" -maxdepth 1 -name "backup_*.tar.gz" -type f 2>/dev/null | sort -r)
    if [ ${#BACKUP_FILES[@]} -eq 0 ]; then
        echo -e "${YELLOW}未找到任何备份文件 (${BACKUP_BASE_DIR}/backup_*.tar.gz)${NC}"
        press_enter
        return 1
    fi

    echo ""
    echo "========================================"
    echo "          还原配置向导"
    echo "========================================"

    FULL_PATH=""
    if command -v fzf &>/dev/null; then
        FULL_PATH=$(fzf_select_restore_file)
        if [[ -z "$FULL_PATH" ]]; then
            echo "已取消"
            return 0
        fi
    else
        # 传统方式
        echo "可用备份文件:"
        for i in "${!BACKUP_FILES[@]}"; do
            NAME=$(basename "${BACKUP_FILES[$i]}")
            SIZE=$(du -h "${BACKUP_FILES[$i]}" | cut -f1)
            printf "  %2d) %s  (%s)\n" $((i+1)) "$NAME" "$SIZE"
        done
        echo "----------------------------------------"
        read -p "请选择备份文件编号 (直接回车取消): " file_choice

        if [[ -z "$file_choice" ]]; then
            echo "已取消"
            return 0
        fi
        if [[ ! "$file_choice" =~ ^[0-9]+$ ]] || [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt ${#BACKUP_FILES[@]} ]; then
            echo -e "${RED}无效选择${NC}"
            press_enter
            return 1
        fi
        FULL_PATH="${BACKUP_FILES[$((file_choice-1))]}"
    fi

    echo "选择: $(basename "$FULL_PATH")"

    TEMP_RESTORE_DIR=$(mktemp -d -t config_restore_XXXXXX)
    if ! tar -xzf "$FULL_PATH" -C "$TEMP_RESTORE_DIR" 2>/dev/null; then
        echo -e "${RED}解压备份文件失败${NC}"
        rm -rf "$TEMP_RESTORE_DIR"
        press_enter
        return 1
    fi

    BACKUP_CONTENT_DIR=$(find "$TEMP_RESTORE_DIR" -maxdepth 1 -type d -name "backup_*" | head -1)
    if [ -z "$BACKUP_CONTENT_DIR" ]; then
        echo -e "${RED}备份文件结构异常，找不到备份内容目录${NC}"
        rm -rf "$TEMP_RESTORE_DIR"
        press_enter
        return 1
    fi

    SELECTED_RESTORE=()
    if command -v fzf &>/dev/null; then
        mapfile -t SELECTED_RESTORE < <(fzf_select_restore_items "$BACKUP_CONTENT_DIR")
        if [[ ${#SELECTED_RESTORE[@]} -eq 0 ]]; then
            echo "已取消"
            rm -rf "$TEMP_RESTORE_DIR"
            return 0
        fi
    else
        # 传统方式
        AVAILABLE_KEYS=()
        AVAILABLE_DESC=()
        for item in ssh gnupg dconf fcitx5; do
            if [ -d "$BACKUP_CONTENT_DIR/$item" ]; then
                case "$item" in
                    ssh)    desc="SSH 配置 (含密钥)" ;;
                    gnupg)  desc="GPG 配置 (含密钥)" ;;
                    dconf)  desc="dconf 配置 (GNOME/GTK 设置)" ;;
                    fcitx5)  desc="Fcitx5 输入法配置" ;;
                    *)      desc="$item" ;;
                esac
                AVAILABLE_KEYS+=("$item")
                AVAILABLE_DESC+=("$item - $desc")
            fi
        done

        if [ ${#AVAILABLE_KEYS[@]} -eq 0 ]; then
            echo -e "${YELLOW}备份文件中没有可还原的配置项${NC}"
            rm -rf "$TEMP_RESTORE_DIR"
            press_enter
            return 1
        fi

        echo ""
        echo "备份中包含以下可还原项目:"
        for i in "${!AVAILABLE_DESC[@]}"; do
            printf "  %2d) %s\n" $((i+1)) "${AVAILABLE_DESC[$i]}"
        done
        echo "----------------------------------------"
        echo "输入编号选择 (多个用逗号分隔，如 1,3,4)，输入 'all' 全选，直接回车取消"
        read -p "你的选择: " choice

        if [[ -z "$choice" ]]; then
            echo "未选择任何项目，取消还原"
            rm -rf "$TEMP_RESTORE_DIR"
            return 0
        fi

        if [[ "$choice" == "all" ]]; then
            SELECTED_RESTORE=("${AVAILABLE_KEYS[@]}")
        else
            IFS=',' read -ra nums <<< "$choice"
            for num in "${nums[@]}"; do
                num=$(echo "$num" | xargs)
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#AVAILABLE_KEYS[@]} ]; then
                    SELECTED_RESTORE+=("${AVAILABLE_KEYS[$((num-1))]}")
                fi
            done
        fi
    fi

    if [[ ${#SELECTED_RESTORE[@]} -eq 0 ]]; then
        echo -e "${RED}没有有效的选择${NC}"
        rm -rf "$TEMP_RESTORE_DIR"
        return 1
    fi

    echo ""
    echo "即将还原以下项目: ${SELECTED_RESTORE[*]}"
    echo -e "${YELLOW}注意: 还原将覆盖现有配置（旧配置会备份为 .bak_时间戳）${NC}"

    # dconf 单独确认
    if [[ " ${SELECTED_RESTORE[*]} " =~ " dconf " ]]; then
        echo ""
        if ! yes_no "还原 dconf 将覆盖当前 GNOME/GTK 的所有设置。是否继续？" "n"; then
            # 移除 dconf
            local new_array=()
            for item in "${SELECTED_RESTORE[@]}"; do
                [[ "$item" != "dconf" ]] && new_array+=("$item")
            done
            SELECTED_RESTORE=("${new_array[@]}")
        fi
    fi

    yes_no "确认开始还原？" "n" || {
        rm -rf "$TEMP_RESTORE_DIR"
        return 0
    }

    RESTORE_COUNT=0
    BACKUP_SUFFIX=".bak_$(date +%Y%m%d_%H%M%S)"

    for item in "${SELECTED_RESTORE[@]}"; do
        case "$item" in
            ssh)
                if [ -d "$BACKUP_CONTENT_DIR/ssh" ]; then
                    if [ -d "$HOME/.ssh" ]; then
                        cp -r "$HOME/.ssh" "$HOME/.ssh$BACKUP_SUFFIX" 2>/dev/null || true
                    fi
                    rm -rf "$HOME/.ssh" 2>/dev/null || true
                    if rsync -a --no-perms --no-owner --no-group "$BACKUP_CONTENT_DIR/ssh/" "$HOME/.ssh/" 2>/dev/null; then
                        chmod -R 700 "$HOME/.ssh" 2>/dev/null || true
                        find "$HOME/.ssh" -type f -exec chmod 600 {} \; 2>/dev/null || true
                        echo -e "${GREEN}[OK]${NC} 还原 SSH 配置"
                        ((RESTORE_COUNT++))
                    else
                        echo -e "${RED}[FAIL]${NC} 还原 SSH 配置失败"
                    fi
                fi
                ;;
            gnupg)
                if [ -d "$BACKUP_CONTENT_DIR/gnupg" ]; then
                    if [ -d "$HOME/.gnupg" ]; then
                        cp -r "$HOME/.gnupg" "$HOME/.gnupg$BACKUP_SUFFIX" 2>/dev/null || true
                    fi
                    rm -rf "$HOME/.gnupg" 2>/dev/null || true
                    if rsync -a --no-perms --no-owner --no-group "$BACKUP_CONTENT_DIR/gnupg/" "$HOME/.gnupg/" 2>/dev/null; then
                        chmod -R 700 "$HOME/.gnupg" 2>/dev/null || true
                        find "$HOME/.gnupg" -type f -exec chmod 600 {} \; 2>/dev/null || true
                        echo -e "${GREEN}[OK]${NC} 还原 GPG 配置"
                        ((RESTORE_COUNT++))
                    else
                        echo -e "${RED}[FAIL]${NC} 还原 GPG 配置失败"
                    fi
                fi
                ;;
            dconf)
                if [ -f "$BACKUP_CONTENT_DIR/dconf/dconf.ini" ]; then
                    if ! command -v dconf &>/dev/null; then
                        echo -e "${YELLOW}[SKIP]${NC} dconf (命令未安装)"
                        continue
                    fi
                    BACKUP_DCONF="$HOME/dconf_backup_$(date +%Y%m%d_%H%M%S).ini"
                    dconf dump / > "$BACKUP_DCONF" 2>/dev/null || true
                    echo -e "${GREEN}[OK]${NC} 当前 dconf 已备份到 $BACKUP_DCONF"
                    if dconf load / < "$BACKUP_CONTENT_DIR/dconf/dconf.ini" 2>/dev/null; then
                        echo -e "${GREEN}[OK]${NC} 还原 dconf 配置"
                        ((RESTORE_COUNT++))
                    else
                        echo -e "${RED}[FAIL]${NC} dconf 还原失败"
                    fi
                fi
                ;;
            fcitx5)
                if [ -d "$BACKUP_CONTENT_DIR/fcitx5" ]; then
                    if pgrep -x fcitx5 >/dev/null 2>&1 || pgrep -f "fcitx5.*daemon" >/dev/null 2>&1; then
                        echo -e "${YELLOW}[STOP]${NC} 正在停止 Fcitx5 服务..."
                        fcitx5-remote -e 2>/dev/null || qdbus org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1.Exit 2>/dev/null || true
                        sleep 0.5
                        pkill -f fcitx5 2>/dev/null || true
                    fi
                    if command -v systemctl &>/dev/null; then
                        systemctl stop --user fcitx5-daemon 2>/dev/null || true
                    fi
                    if [ -d "$HOME/.config/fcitx5" ]; then
                        cp -r "$HOME/.config/fcitx5" "$HOME/.config/fcitx5$BACKUP_SUFFIX" 2>/dev/null || true
                    fi
                    rm -rf "$HOME/.config/fcitx5" 2>/dev/null || true
                    if rsync -a --no-perms --no-owner --no-group "$BACKUP_CONTENT_DIR/fcitx5/" "$HOME/.config/fcitx5/" 2>/dev/null; then
                        echo -e "${GREEN}[OK]${NC} 还原 Fcitx5 配置"
                        ((RESTORE_COUNT++))
                        if command -v systemctl &>/dev/null && systemctl is-active --user fcitx5-daemon &>/dev/null; then
                            systemctl restart --user fcitx5-daemon 2>/dev/null || true
                        else
                            fcitx5 -d 2>/dev/null || true
                        fi
                    else
                        echo -e "${RED}[FAIL]${NC} 还原 Fcitx5 配置失败"
                    fi
                fi
                ;;
        esac
    done

    rm -rf "$TEMP_RESTORE_DIR"

    echo ""
    echo "========================================"
    echo "          还原完成！"
    echo "========================================"
    echo "成功还原 $RESTORE_COUNT 项配置。"
    echo "旧配置已备份为 *$BACKUP_SUFFIX"
    echo ""
    echo "dconf 备份文件位于 ~/dconf_backup_*.ini"
    press_enter
}

# ======================= 主菜单 =======================
main_menu() {
    while true; do
        clear
        echo "========================================"
        echo "        配置管理工具 (fzf 版)"
        echo "========================================"

        if command -v fzf &>/dev/null; then
            local choice
            choice=$(printf '备份配置文件\n还原配置文件\n退出' | fzf --prompt="选择操作 > " --header="ENTER: 确认 / ESC: 退出")
            
            case "$choice" in
                "备份配置文件") do_backup ;;
                "还原配置文件") do_restore ;;
                "退出"|"") echo "再见！"; exit 0 ;;
            esac
        else
            echo "  1) 备份配置文件"
            echo "  2) 还原配置文件"
            echo "  0) 退出"
            echo "----------------------------------------"
            read -p "请输入选项 [0-2]: " opt
            
            case "$opt" in
                1) do_backup ;;
                2) do_restore ;;
                0) echo "再见！"; exit 0 ;;
                *) echo -e "${RED}无效选项，请重新输入${NC}"; sleep 1 ;;
            esac
        fi
    done
}

# ======================= 入口 =======================
case "${1:-}" in
    backup)  do_backup ;;
    restore) do_restore ;;
    *)       main_menu ;;
esac
