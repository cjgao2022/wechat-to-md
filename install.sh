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

# Skill file content — {{PROJECT_DIR}} replaced by sed at install time
SKILL_TEMPLATE=$(cat << 'SKILL_EOF'
---
name: wechat
description: 将微信公众号文章 URL 转换为 Markdown 文件，图片保留网络链接。
context: fork
allowed-tools: ["Bash"]
---

将微信公众号文章 URL 转换为 Markdown 文件，图片保留网络链接。

用户输入：$ARGUMENTS

按以下步骤执行：

**第一步：提取并验证 URL**

从 $ARGUMENTS 中提取 URL。
- 若为空，回复"请提供微信文章 URL，例如：/wechat https://mp.weixin.qq.com/s/xxx"，停止
- 若 URL 不含 `mp.weixin.qq.com`，回复"URL 不是有效的微信文章链接"，停止

**第二步：运行转换脚本**

使用 Bash 工具执行（项目已固定在安装时的路径）：

```
cd "{{PROJECT_DIR}}" && python wechat_to_md.py "$ARGUMENTS"
```

等待命令完成（会弹出浏览器，正常现象）。若命令失败，输出错误信息并停止。

**第三步：读取并展示结果**

命令成功后，读取 `{{PROJECT_DIR}}/output/` 下最新生成的 `.md` 文件，输出：

- 文件保存路径
- 文章标题、来源、发布时间（从文件头部提取）
- 文件前 30 行内容预览
SKILL_EOF
)

SKILL_CONTENT=$(echo "$SKILL_TEMPLATE" | sed "s|{{PROJECT_DIR}}|$PROJECT_DIR|g")

# Install Claude Code skill
if [ -d "$HOME/.claude" ]; then
    SKILL_DIR="$HOME/.claude/skills/wechat"
    mkdir -p "$SKILL_DIR"

    if [ -f "$SKILL_DIR/SKILL.md" ]; then
        printf "Claude Code /wechat 已安装，是否覆盖更新？(y/N) "
        read -r answer < /dev/tty
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
