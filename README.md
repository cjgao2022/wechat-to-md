# wechat-to-md

将微信公众号文章转换为 Markdown 文件，图片保留原始网络链接，输出单个 `.md` 文件。

支持 Claude Code `/wechat` slash command，一条命令完成抓取、转换、预览。

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/cjgao2022/wechat-to-md/main/install.sh | bash
```

或者手动克隆安装：

```bash
git clone https://github.com/cjgao2022/wechat-to-md.git
cd wechat-to-md
bash install.sh
```

`install.sh` 自动完成：

1. 安装 Python 依赖（patchright、markdownify、beautifulsoup4）
2. 安装 Patchright Chromium 浏览器
3. 将 `/wechat` skill 注册到 Claude Code 全局命令

## 使用

安装完成后，在 Claude Code **任意项目**中使用：

```
/wechat https://mp.weixin.qq.com/s/xxxxxxxxxxxx
```

Claude 自动完成抓取、转换，并展示文章标题、来源、时间和内容预览。

也可以直接用命令行：

```bash
python wechat_to_md.py "https://mp.weixin.qq.com/s/xxxxxxxxxxxx"
```

输出文件：`output/<文章标题>.md`

## 输出格式

```markdown
# 文章标题

**来源**：公众号名称
**时间**：2026-06-16
**原文**：https://mp.weixin.qq.com/s/...

---

正文内容……

![图片](https://mmbiz.qpic.cn/...)
```

## 前置条件

- Python 3.11+
- [Claude Code](https://claude.ai/code)

## 注意事项

- 运行时会弹出 Chrome 浏览器窗口，用于绕过微信反爬，属正常现象
- 首次运行若遇到登录验证，在弹出窗口中手动完成即可，登录态会自动保存
- `chrome_profile/` 和 `output/` 已加入 `.gitignore`

## 依赖

| 包 | 用途 |
|----|------|
| [patchright](https://github.com/Kaliiiiiiiiii-Vinyzu/patchright) | 绕过微信反爬，模拟真实浏览器 |
| [markdownify](https://github.com/matthewwithanm/python-markdownify) | HTML 转 Markdown |
| [beautifulsoup4](https://www.crummy.com/software/BeautifulSoup/) | 处理图片 `data-src` 属性 |
