#!/usr/bin/env python3
"""Merges lib/l10n/fragments/*_{en,fr}.arb into the ARB files gen-l10n reads.

Feature areas own a fragment each so several people (or agents) can extract
strings at once without fighting over one file. `app_en.arb` / `app_fr.arb`
stay the generator's input and are rebuilt from the fragments, which merge in
filename order — `000_base_*` first, so shared keys land before feature ones.

The fragments live in a subdirectory because gen-l10n treats every *.arb
directly inside `arb-dir` as a locale file and refuses two for the same
locale.

    python3 tools/merge_arb.py && flutter gen-l10n

Writes atomically, so a concurrent gen-l10n never reads a half-written file.
Fails on a duplicate key across fragments and on any English key missing its
French counterpart — a silent fallback ships a half-translated screen.
"""

import json
import os
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
L10N = ROOT / "lib" / "l10n"
FRAGMENTS = L10N / "fragments"
OUT = {"en": L10N / "app_en.arb", "fr": L10N / "app_fr.arb"}


def load(path: pathlib.Path) -> dict:
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def merge(locale: str) -> dict:
    merged: dict = {}
    owner: dict = {}
    for frag in sorted(FRAGMENTS.glob(f"*_{locale}.arb")):
        data = load(frag)
        for key, value in data.items():
            if key in merged and owner.get(key) != frag.name:
                sys.exit(
                    f"duplicate key '{key}' in {frag.name}, already defined by "
                    f"{owner[key]}"
                )
            merged[key] = value
            owner[key] = frag.name
    merged["@@locale"] = locale
    return merged


def main() -> None:
    en, fr = merge("en"), merge("fr")

    missing = [
        k for k in en
        if not k.startswith("@") and k not in fr
    ]
    if missing:
        sys.exit(
            "these keys have no French translation:\n  "
            + "\n  ".join(sorted(missing))
        )

    extra = [k for k in fr if not k.startswith("@") and k not in en]
    if extra:
        sys.exit(
            "these French keys have no English source:\n  "
            + "\n  ".join(sorted(extra))
        )

    for locale, data in (("en", en), ("fr", fr)):
        target = OUT[locale]
        tmp = target.with_suffix(".arb.tmp")
        tmp.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        os.replace(tmp, target)

    print(f"merged {len([k for k in en if not k.startswith('@')])} keys "
          f"from {len(list(FRAGMENTS.glob('*_en.arb')))} fragment(s)")


if __name__ == "__main__":
    main()
