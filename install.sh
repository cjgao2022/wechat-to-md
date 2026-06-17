#!/bin/bash
set -e

VERSION="1.0.0"
REPO_URL="https://github.com/cjgao2022/wechat-to-md.git"
INSTALLED=0

# Detect curl | bash vs local execution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
if [ -z "$SCRIPT_DIR" ] || [ ! -f "$SCRIPT_DIR/requirements.txt" ]; then
    # Running via curl | bash — clone repo first
    DEFAULT_DIR="$HOME/wechat-to-md"
    if [ -d "$DEFAULT_DIR/.git" ]; then
        echo ">>> Updating existing repo at $DEFAULT_DIR..."
        git -C "$DEFAULT_DIR" pull -q
    else
        echo ">>> Cloning wechat-to-md to $DEFAULT_DIR..."
        git clone -q "$REPO_URL" "$DEFAULT_DIR"
    fi
    PROJECT_DIR="$DEFAULT_DIR"
else
    PROJECT_DIR="$SCRIPT_DIR"
fi

echo "=== wechat-to-md installer v${VERSION} ==="
echo ""

# Install Python dependencies
echo ">>> Installing Python dependencies..."
python -m pip install -r "$PROJECT_DIR/requirements.txt" -q
echo "[OK] Python dependencies installed"

# Install Patchright Chromium
echo ">>> Installing Patchright Chromium..."
python -m patchright install chromium
echo "[OK] Chromium installed"

echo ""

# Build skill content from template file (avoids heredoc issues with curl | bash)
SKILL_CONTENT=$(sed "s|{{PROJECT_DIR}}|$PROJECT_DIR|g" "$PROJECT_DIR/skill-template.md")

# Install Claude Code skill
if [ -d "$HOME/.claude" ]; then
    SKILL_DIR="$HOME/.claude/skills/wechat"
    mkdir -p "$SKILL_DIR"

    if [ -f "$SKILL_DIR/SKILL.md" ]; then
        if [ -t 0 ]; then
            printf "Claude Code /wechat 已安装，是否覆盖更新？(y/N) "
            read -r answer
        else
            answer="y"
        fi
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            printf '%s\n' "$SKILL_CONTENT" > "$SKILL_DIR/SKILL.md"
            echo "[OK] Claude Code - updated"
        else
            echo "[SKIP] Claude Code - skipped"
        fi
    else
        printf '%s\n' "$SKILL_CONTENT" > "$SKILL_DIR/SKILL.md"
        echo "[OK] Claude Code - installed"
    fi
    INSTALLED=1
fi

if [ $INSTALLED -eq 0 ]; then
    echo "未检测到 Claude Code，请先安装："
    echo "  https://claude.ai/code"
    exit 1
fi

echo ""
echo "Done! v${VERSION} installed"
echo ""
echo "Usage: /wechat https://mp.weixin.qq.com/s/xxx"
