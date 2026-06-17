# CLAUDE.md — wechat-to-md

## 项目目的

抓取微信公众号文章，转换为干净的 Markdown 文件，图片保留网络链接，不下载到本地。

## 目录结构

```
wechat-to-md/
├── .claude/
│   └── commands/
│       └── wechat.md    # 项目级 slash command（项目内可用）
├── wechat_to_md.py      # 唯一入口脚本
├── install.sh           # 一键安装：依赖 + 全局 skill 注册（bash）
├── requirements.txt     # pip 依赖
├── .gitignore
├── chrome_profile/      # Patchright 持久化浏览器 profile（不进 git）
├── output/              # 生成的 .md 文件输出目录（不进 git）
├── CLAUDE.md
└── README.md
```

## 运行方式

**初次安装（安装依赖 + 注册全局 skill）：**

```bash
bash install.sh
```

**命令行：**

```bash
python wechat_to_md.py <微信文章URL>
```

**Claude Code slash command（推荐）：**

```
/wechat <微信文章URL>
```

安装后在任意项目中可用，Claude 自动运行转换并展示结果预览。

输出：`output/<文章标题>.md`，单文件，无子文件夹。

## 依赖

- Python 3.13+
- patchright 1.60.1
- markdownify 1.2.2
- beautifulsoup4 4.15.0

安装：

```bash
pip install patchright markdownify beautifulsoup4
patchright install chromium
```

## 核心约定

- **浏览器**：必须用 `launch_persistent_context()`，`user_data_dir` 固定为 `./chrome_profile`，`headless=False`
- **图片**：不下载，直接将 `data-src` 属性转为 `src`，Markdown 中使用原始网络链接
- **输出**：单个 `.md` 文件落在 `output/` 根目录，文件名取文章标题 slug，不建子文件夹
- **反爬**：依赖 Patchright 绕过微信检测，不用 requests/httpx 抓正文

## 函数职责

| 函数 | 作用 |
|------|------|
| `fetch_article(url)` | 用 Patchright 打开页面，提取标题/作者/时间/正文 HTML |
| `fix_image_urls(html)` | 把 `data-src` 换成 `src`，保留网络链接 |
| `html_to_markdown(...)` | 调用 markdownify 转换，拼接文章头部元信息 |
| `slugify(text)` | 文章标题转合法文件名 |
| `main(url)` | 串联以上步骤，写入 `output/` |

## 验证

运行后检查：
1. `output/` 下有对应 `.md` 文件
2. 文件头部含来源、时间、原文链接
3. 图片链接格式为 `![](https://mmbiz.qpic.cn/...)`，非本地路径
