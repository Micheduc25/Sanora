#!/usr/bin/env python3
"""Regenerates app/lib/features/legal/legal_content.dart from the Markdown here.

The .md files in this directory are the canonical legal documents. The app
renders the same text in-app from Dart string constants, because the documents
are not bundled as Flutter assets and the app deliberately carries no Markdown
rendering dependency.

Run this after editing any document in this directory:

    python3 docs/legal/generate_legal_content.py
    cd app && dart format lib/features/legal
"""

import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs" / "legal"
OUT = ROOT / "app" / "lib" / "features" / "legal" / "legal_content.dart"

DOCUMENTS = [
    ("privacyPolicy", "privacy-policy.md"),
    ("termsOfService", "terms-of-service.md"),
    ("healthDisclaimer", "health-disclaimer.md"),
]

HEADER = '''// GENERATED — DO NOT EDIT BY HAND.
//
// Verbatim copies of the Markdown sources in docs/legal/, which are the
// canonical documents. This file exists only because those documents are not
// bundled as Flutter assets, and because the app deliberately carries no
// Markdown rendering dependency.
//
// After editing any document in docs/legal/, regenerate this file:
//
//     python3 docs/legal/generate_legal_content.py
//
// An in-app policy that has drifted from the published one is a compliance
// problem, not a cosmetic one.
//
// Rendered by LegalScreen, which understands a small Markdown subset:
// `##` / `###` headings, `-` bullets, numbered lists, blank-line paragraph
// breaks, `**bold**` and backtick code spans. Keep new content within it.

abstract final class LegalContent {'''

FOOTER = "}\n"


def dart_raw_string(text: str) -> str:
    # A raw string sidesteps escaping entirely, so `$`, `\` and quotes in the
    # documents survive untouched. The only sequence that could close one early
    # is the terminator itself.
    if "'''" in text:
        raise SystemExit("document contains a raw-string terminator")
    # Dart drops the newline immediately after the opening delimiter, so the
    # constant starts at the document's first character.
    return "r'''\n" + text + "''';"


def main() -> None:
    parts = [HEADER]
    for name, filename in DOCUMENTS:
        text = (DOCS / filename).read_text(encoding="utf-8")
        parts.append(f"  /// Mirrors docs/legal/{filename}.")
        parts.append(f"  static const {name} = {dart_raw_string(text)}")
        parts.append("")
    if parts[-1] == "":
        parts.pop()
    OUT.write_text("\n".join(parts) + "\n" + FOOTER, encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
