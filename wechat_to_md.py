"""
WeChat article scraper: fetch article and convert to Markdown.
Usage: python wechat_to_md.py <url>
"""

import asyncio
import re
import sys
from pathlib import Path

from bs4 import BeautifulSoup
from markdownify import markdownify
from patchright.async_api import async_playwright


OUTPUT_DIR = Path("output")
CHROME_PROFILE = Path("chrome_profile")


async def fetch_article(url: str) -> dict:
    async with async_playwright() as p:
        context = await p.chromium.launch_persistent_context(
            user_data_dir=str(CHROME_PROFILE),
            headless=False,
            args=["--disable-blink-features=AutomationControlled"],
        )
        page = await context.new_page()
        await page.goto(url, wait_until="networkidle", timeout=60000)

        # Extract metadata
        title = await page.title()
        title = re.sub(r"\s*[-_|]\s*.*$", "", title).strip()  # strip site suffix

        author = ""
        pub_time = ""
        try:
            author = await page.locator("#js_name").inner_text(timeout=3000)
            author = author.strip()
        except Exception:
            pass
        try:
            pub_time = await page.locator("#publish_time").inner_text(timeout=3000)
            pub_time = pub_time.strip()
        except Exception:
            pass

        # Get article body HTML
        try:
            content_html = await page.locator("#js_content").inner_html(timeout=5000)
        except Exception:
            content_html = await page.content()

        await context.close()

    return {
        "title": title,
        "author": author,
        "pub_time": pub_time,
        "url": url,
        "content_html": content_html,
    }


def slugify(text: str) -> str:
    text = re.sub(r'[\\/*?:"<>|]', "", text)
    text = text.strip().replace(" ", "_")
    return text[:80]


def fix_image_urls(html: str) -> str:
    soup = BeautifulSoup(html, "html.parser")
    for img in soup.find_all("img"):
        src = img.get("data-src") or img.get("src") or ""
        if src.startswith("http"):
            img["src"] = src
            if img.get("data-src"):
                del img["data-src"]
    return str(soup)


def html_to_markdown(html: str, title: str, author: str, pub_time: str, url: str) -> str:
    md = markdownify(html, heading_style="ATX", strip=["script", "style"])
    # Collapse 3+ blank lines to 2
    md = re.sub(r"\n{3,}", "\n\n", md)
    md = md.strip()

    header = f"# {title}\n\n"
    if author:
        header += f"**来源**：{author}  \n"
    if pub_time:
        header += f"**时间**：{pub_time}  \n"
    header += f"**原文**：{url}\n\n---\n\n"

    return header + md


async def main(url: str):
    print(f"Fetching: {url}")
    article = await fetch_article(url)
    print(f"Title: {article['title']}")

    slug = slugify(article["title"]) or "article"
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print("Converting to Markdown...")
    fixed_html = fix_image_urls(article["content_html"])
    md = html_to_markdown(
        fixed_html,
        article["title"],
        article["author"],
        article["pub_time"],
        article["url"],
    )

    out_file = OUTPUT_DIR / f"{slug}.md"
    out_file.write_text(md, encoding="utf-8")
    print(f"Saved: {out_file}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python wechat_to_md.py <url>")
        sys.exit(1)
    asyncio.run(main(sys.argv[1]))
