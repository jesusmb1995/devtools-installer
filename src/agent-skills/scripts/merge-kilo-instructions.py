#!/usr/bin/env python3
"""Merge a managed `instructions` entry into kilo.jsonc without touching anything else.

Usage: merge-kilo-instructions.py <home-dir>

Ensures the global kilo config `<home>/.config/kilo/kilo.jsonc` contains an
`instructions` array entry pointing at our deployed rules glob
(`<home>/.agents/rules/*.md`). Never removes or rewrites existing content:
- config missing -> create a minimal one holding just the entry
- key missing -> insert it textually right after the opening brace
- key present, entry missing -> append the entry inside the existing array
- entry already there -> no-op

Textual editing (not a JSON round-trip) so user comments and formatting
survive byte-for-byte. Always exits 0; prints what it did.
"""

import os
import re
import shutil
import sys


def main(home):
    cfg = os.path.join(home, ".config", "kilo", "kilo.jsonc")
    entry = home.rstrip("/") + "/.agents/rules/*.md"

    if not os.path.exists(cfg):
        os.makedirs(os.path.dirname(cfg), exist_ok=True)
        with open(cfg, "w") as f:
            f.write('{\n  "instructions": [\n    "%s"\n  ]\n}\n' % entry)
        print("merge-kilo-instructions: created %s with instructions entry" % cfg)
        return 0

    with open(cfg) as f:
        text = f.read()

    if entry in text:
        print("merge-kilo-instructions: entry already present, nothing to do")
        return 0

    m = re.search(r'"instructions"\s*:\s*\[', text)
    if m:
        # find the closing bracket of this array (string entries only)
        i = m.end()
        depth = 1
        instr = False
        while i < len(text) and depth > 0:
            ch = text[i]
            if instr:
                if ch == "\\":
                    i += 1
                elif ch == '"':
                    instr = False
            elif ch == '"':
                instr = True
            elif ch == "[":
                depth += 1
            elif ch == "]":
                depth -= 1
            i += 1
        if depth == 0:
            inner = text[m.end():i - 1]
            sep = "" if inner.strip() == "" or inner.rstrip().endswith(",") else ","
            new_text = text[:i - 1] + sep + '\n    "%s"\n  ' % entry + text[i - 1:]
            shutil.copy2(cfg, cfg + ".bak")
            with open(cfg, "w") as f:
                f.write(new_text)
            print("merge-kilo-instructions: appended entry to existing instructions array")
            return 0
        print("merge-kilo-instructions: could not parse instructions array, skipping")
        return 0

    brace = text.find("{")
    if brace < 0:
        print("merge-kilo-instructions: no object brace found, skipping")
        return 0
    shutil.copy2(cfg, cfg + ".bak")
    with open(cfg, "w") as f:
        f.write(text[:brace + 1] + '\n  "instructions": [\n    "%s"\n  ],' % entry + text[brace + 1:])
    print("merge-kilo-instructions: inserted instructions key")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~")))
