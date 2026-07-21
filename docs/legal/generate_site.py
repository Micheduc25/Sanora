#!/usr/bin/env python3
"""Builds the public legal site in site/ from the Markdown documents here.

The .md files stay canonical: they generate the in-app text (see
generate_legal_content.py) and these pages, so the published policy and the one
inside the app cannot drift apart.

    python3 docs/legal/generate_site.py

Output goes to site/, which is served by GitHub Pages from the gh-pages branch.
Every page is self-contained — no external CSS, fonts or scripts — because a
privacy policy that phones a CDN to render is a bad look, and because these
pages must survive being read on a bad connection in a hurry.
"""

import html
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs" / "legal"
SITE = ROOT / "site"

BASE = "https://micheduc25.github.io/Sanora"

# slug, source file, <title>, meta description
PAGES = [
    (
        "privacy",
        "privacy-policy.md",
        "Privacy Policy",
        "How Sanora handles your health data: what is collected, who processes "
        "it, and how to delete it.",
    ),
    (
        "terms",
        "terms-of-service.md",
        "Terms of Service",
        "The terms you agree to when you use Sanora.",
    ),
    (
        "health-disclaimer",
        "health-disclaimer.md",
        "Health Disclaimer",
        "What Sanora's numbers mean, what they do not mean, and when to see a "
        "clinician.",
    ),
]

STYLE = """
:root {
  --vital: #10a56d;
  --canvas: #f7f8f6;
  --surface: #ffffff;
  --ink: #17211c;
  --ink-muted: #5c6b63;
  --line: #e6eae7;
}
@media (prefers-color-scheme: dark) {
  :root {
    --vital: #5cd6a6;
    --canvas: #0e1512;
    --surface: #151f1a;
    --ink: #eef4f0;
    --ink-muted: #9aab a2;
    --ink-muted: #9aaba2;
    --line: #24312b;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0;
  padding: 0 20px 80px;
  background: var(--canvas);
  color: var(--ink);
  font: 17px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
    "Helvetica Neue", Arial, sans-serif;
  -webkit-text-size-adjust: 100%;
}
.wrap { max-width: 46rem; margin: 0 auto; }
header.site {
  display: flex; align-items: center; gap: 12px;
  padding: 28px 0 24px; border-bottom: 1px solid var(--line); margin-bottom: 36px;
}
header.site .mark {
  width: 34px; height: 34px; border-radius: 11px; flex: none;
  background: var(--vital); color: #fff; font-weight: 700;
  display: flex; align-items: center; justify-content: center;
}
header.site a { color: inherit; text-decoration: none; font-weight: 600; }
h1 { font-size: 2rem; line-height: 1.2; margin: 0 0 8px; letter-spacing: -0.02em; }
h2 {
  font-size: 1.3rem; margin: 2.4em 0 0.6em; letter-spacing: -0.01em;
  padding-top: 0.6em; border-top: 1px solid var(--line);
}
h3 { font-size: 1.05rem; margin: 1.8em 0 0.4em; }
p, li { color: var(--ink); }
ul { padding-left: 1.2em; }
li { margin: 0.35em 0; }
a { color: var(--vital); }
code {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 0.9em; background: var(--surface);
  border: 1px solid var(--line); border-radius: 5px; padding: 0.1em 0.35em;
}
.meta {
  color: var(--ink-muted); font-size: 0.92rem;
  background: var(--surface); border: 1px solid var(--line);
  border-radius: 14px; padding: 14px 18px; margin: 0 0 28px;
}
.meta ul { margin: 0; padding-left: 1.1em; }
footer.site {
  margin-top: 56px; padding-top: 20px; border-top: 1px solid var(--line);
  color: var(--ink-muted); font-size: 0.9rem;
}
footer.site a { margin-right: 14px; }
.cards { display: grid; gap: 14px; margin: 28px 0; }
.card {
  display: block; padding: 18px 20px; background: var(--surface);
  border: 1px solid var(--line); border-radius: 16px;
  text-decoration: none; color: inherit;
}
.card:hover { border-color: var(--vital); }
.card strong { display: block; font-size: 1.05rem; margin-bottom: 3px; }
.card span { color: var(--ink-muted); font-size: 0.94rem; }
.steps { counter-reset: step; list-style: none; padding: 0; }
.steps li {
  counter-increment: step; position: relative;
  padding-left: 42px; margin: 0 0 18px;
}
.steps li::before {
  content: counter(step); position: absolute; left: 0; top: -1px;
  width: 28px; height: 28px; border-radius: 50%;
  background: var(--vital); color: #fff; font-weight: 600; font-size: 0.9rem;
  display: flex; align-items: center; justify-content: center;
}
"""

INLINE_CODE = re.compile(r"`([^`]+)`")
BOLD = re.compile(r"\*\*([^*]+)\*\*")
URL = re.compile(r"(?<![\"'>=])(https?://[^\s<)]+)")


def inline(text: str) -> str:
    """Escapes, then applies the small Markdown subset the documents use."""
    out = html.escape(text, quote=False)
    out = INLINE_CODE.sub(lambda m: f"<code>{m.group(1)}</code>", out)
    out = BOLD.sub(lambda m: f"<strong>{m.group(1)}</strong>", out)
    out = URL.sub(lambda m: f'<a href="{m.group(1)}">{m.group(1)}</a>', out)
    return out


def render(markdown: str) -> tuple[str, str]:
    """Returns (page title, body HTML) for one document.

    Handles exactly what the legal documents contain — `#`/`##`/`###`
    headings, `-` bullets, `1.` numbered items, blank-line paragraphs — and
    nothing else. An unsupported construct should look wrong immediately rather
    than silently render as prose.
    """
    title = ""
    parts: list[str] = []
    paragraph: list[str] = []
    bullets: list[str] = []
    intro_done = False

    def flush_paragraph() -> None:
        nonlocal paragraph
        if paragraph:
            parts.append(f"<p>{inline(' '.join(paragraph))}</p>")
            paragraph = []

    def flush_bullets() -> None:
        nonlocal bullets
        if bullets:
            items = "".join(f"<li>{inline(b)}</li>" for b in bullets)
            parts.append(f"<ul>{items}</ul>")
            bullets = []

    lines = markdown.splitlines()
    index = 0
    while index < len(lines):
        line = lines[index]
        stripped = line.strip()

        # A bullet or paragraph continues while the next line is indented.
        if (bullets or paragraph) and stripped and line.startswith("  ") \
                and not stripped.startswith(("-", "#")):
            if bullets:
                bullets[-1] += " " + stripped
            else:
                paragraph.append(stripped)
            index += 1
            continue

        if not stripped:
            flush_paragraph()
            flush_bullets()
        elif stripped.startswith("### "):
            flush_paragraph()
            flush_bullets()
            parts.append(f"<h3>{inline(stripped[4:])}</h3>")
        elif stripped.startswith("## "):
            flush_paragraph()
            flush_bullets()
            parts.append(f"<h2>{inline(stripped[3:])}</h2>")
        elif stripped.startswith("# "):
            title = stripped[2:]
            parts.append(f"<h1>{inline(title)}</h1>")
        elif stripped.startswith("- "):
            flush_paragraph()
            bullets.append(stripped[2:])
        else:
            flush_bullets()
            paragraph.append(stripped)

        # The publisher line and the effective-date bullets open every
        # document; boxing them separates the identity of the thing from its
        # terms.
        if not intro_done and parts and parts[-1].startswith("<ul>"):
            parts[-1] = f'<div class="meta">{parts[-1]}</div>'
            intro_done = True

        index += 1

    flush_paragraph()
    flush_bullets()
    return title, "\n".join(parts)


def page(title: str, description: str, body: str, canonical: str) -> str:
    nav = "".join(
        f'<a href="{BASE}/{slug}/">{name}</a>'
        for slug, name in [
            ("privacy", "Privacy"),
            ("terms", "Terms"),
            ("health-disclaimer", "Health disclaimer"),
            ("delete-account", "Delete your account"),
        ]
    )
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)} — Sanora</title>
<meta name="description" content="{html.escape(description)}">
<link rel="canonical" href="{canonical}">
<meta name="color-scheme" content="light dark">
<style>{STYLE}</style>
</head>
<body>
<div class="wrap">
<header class="site">
  <div class="mark">S</div>
  <a href="{BASE}/">Sanora</a>
</header>
{body}
<footer class="site">
{nav}
<p>Sanora is published by Ndjock Michel Junior (Innovation Cameroon).
Contact: <a href="mailto:ndjockjunior@gmail.com">ndjockjunior@gmail.com</a></p>
</footer>
</div>
</body>
</html>
"""


INDEX_BODY = f"""<h1>Sanora</h1>
<p>Sanora — Know Your Body — is an offline-first personal health companion:
meals, measurements, habits and workouts, with an AI coach. It is built and run
by one developer in Cameroon.</p>
<p>These are the documents that govern it.</p>
<div class="cards">
  <a class="card" href="{BASE}/privacy/">
    <strong>Privacy Policy</strong>
    <span>What Sanora collects, who processes it, where it is stored, and how
    to get it back or erase it.</span>
  </a>
  <a class="card" href="{BASE}/terms/">
    <strong>Terms of Service</strong>
    <span>The agreement between you and the publisher, including how the
    Premium subscription works.</span>
  </a>
  <a class="card" href="{BASE}/health-disclaimer/">
    <strong>Health Disclaimer</strong>
    <span>What the numbers mean, what they do not mean, and when to see a
    clinician instead.</span>
  </a>
  <a class="card" href="{BASE}/delete-account/">
    <strong>Delete your account</strong>
    <span>Erase your account and all of its data — in the app, or by
    request.</span>
  </a>
</div>
<h2>Contact</h2>
<p>Sanora is published by Ndjock Michel Junior, an individual developer based in
Cameroon, under the name Innovation Cameroon. For anything at all — support, a
privacy request, a legal notice — write to
<a href="mailto:ndjockjunior@gmail.com">ndjockjunior@gmail.com</a>.</p>
"""

DELETE_BODY = """<h1>Delete your Sanora account</h1>
<p>Deleting your account erases it and everything in it. You do not need to ask
anyone's permission and you do not need to explain why.</p>

<h2>In the app — immediate</h2>
<ol class="steps">
  <li>Open Sanora and go to the <strong>You</strong> tab.</li>
  <li>Tap <strong>Delete my data</strong>.</li>
  <li>Choose <strong>Delete account</strong> and confirm.</li>
</ol>
<p>This runs straight away. There is no grace period and no recovery, so export
anything you want to keep first — <strong>Reports</strong> generates a PDF you
can save or send.</p>

<h2>By request</h2>
<p>If you no longer have the app installed, or you cannot sign in, write to
<a href="mailto:ndjockjunior@gmail.com">ndjockjunior@gmail.com</a> from the
e-mail address you signed up with, asking for your account to be deleted. We
will confirm within 30 days.</p>

<h2>What is deleted</h2>
<p>Your authentication record, and with it — deleted by the database in the same
transaction — your profile, your measurements, your meals, your habits and
habit logs, your coach conversations, your reminders, your workouts, your AI
usage counters, your subscription record, your friendships, your group
memberships, your challenge entries and any group invitations. Any meal photo
stored under your account is deleted first. The copy of your data held on your
own device is wiped at the same time.</p>

<h2>What is kept, and why</h2>
<ul>
  <li><strong>Abuse reports made about you by other users</strong> are kept, so
  that deleting an account cannot be used to erase a moderation record. They
  contain the report itself, not your health data.</li>
  <li><strong>Encrypted backups</strong> held by our hosting provider may
  contain your data for a short period before they rotate out. They are never
  restored into the live system.</li>
  <li><strong>Purchase records</strong> held by Apple or Google. We do not
  control these — the store took the payment and keeps its own accounting
  record under its own rules.</li>
</ul>
<p>Deleting your account does not cancel a subscription. Cancel that in your
Apple ID or Google Play account settings, or it will keep renewing.</p>
"""


def main() -> None:
    SITE.mkdir(exist_ok=True)
    # Without this, Pages runs Jekyll and quietly drops anything it dislikes.
    (SITE / ".nojekyll").write_text("", encoding="utf-8")

    written = []
    for slug, filename, title, description in PAGES:
        markdown = (DOCS / filename).read_text(encoding="utf-8")
        doc_title, body = render(markdown)
        canonical = f"{BASE}/{slug}/"
        directory = SITE / slug
        directory.mkdir(exist_ok=True)
        (directory / "index.html").write_text(
            page(doc_title or title, description, body, canonical),
            encoding="utf-8",
        )
        written.append(f"{slug}/index.html")

    (SITE / "index.html").write_text(
        page(
            "Sanora",
            "Sanora — Know Your Body. Privacy policy, terms of service, health "
            "disclaimer and account deletion.",
            INDEX_BODY,
            f"{BASE}/",
        ),
        encoding="utf-8",
    )
    written.append("index.html")

    delete_dir = SITE / "delete-account"
    delete_dir.mkdir(exist_ok=True)
    (delete_dir / "index.html").write_text(
        page(
            "Delete your account",
            "How to delete your Sanora account and all of its data, in the app "
            "or by request.",
            DELETE_BODY,
            f"{BASE}/delete-account/",
        ),
        encoding="utf-8",
    )
    written.append("delete-account/index.html")

    for name in written:
        print(f"wrote site/{name}")


if __name__ == "__main__":
    main()
