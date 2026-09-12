#!/usr/bin/env python3
"""
printf-check — find printf format/argument count mismatches in shell files.

Why this exists: `printf` REUSES its format string when given more arguments
than it has conversion specifiers. So

    printf '  %s a %s b %s\\n' "$x" "$y" "$z" "$w"

does not error and does not drop the extra argument — it prints the whole line
twice, the second time with empty substitutions. The output looks like a
stray duplicate line, which is easy to attribute to something else. (That is
exactly how `ash theme random` came to print its summary twice, the second
copy blank.)

This is a static check. It only reports cases where BOTH counts are knowable:

  * the format is a single-quoted or double-quoted literal on the line,
  * the argument list contains no `"${arr[@]}"` / `"$@"`-style expansion,
    whose length cannot be known without running the script.

Anything it cannot be sure about is skipped rather than guessed at.

Usage: printf-check.py <file-or-directory> [...]
Exit status 1 if any mismatch was found, 0 otherwise.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Conversion specifiers that consume exactly one argument.
SIMPLE = set("sdifxXoOeuEcCbq")
# %% consumes none; these flags/width/precision may precede a specifier.
SPEC_RE = re.compile(r"%(?:[-+ #0']*)(?:\*|\d+)?(?:\.(?:\*|\d+))?(?:[hlLzjt]{0,2})([diouxXeEfgGaAcspbq%])")


def count_specifiers(fmt: str) -> tuple[int, int, bool]:
    """Return (arg-consuming specifiers, *, has-%-that-might-be-dynamic)."""
    n = 0
    stars = 0
    # Strip %% first so it is not mistaken for a specifier.
    fmt = fmt.replace("%%", "")
    for m in re.finditer(r"%[-+ #0']*(?:(\*)|(\d+))?(?:\.(?:(\*)|(\d+)))?[hlLzjt]{0,2}([diouxXeEfgGaAcspbq])", fmt):
        n += 1
        if m.group(1) or m.group(3):
            stars += 1
    return n, stars, False


def join_continuations(lines: list[str]) -> list[tuple[int, str]]:
    out: list[tuple[int, str]] = []
    buf = ""
    start = 0
    for i, raw in enumerate(lines, 1):
        line = raw.rstrip("\n")
        if not buf:
            start = i
        # A trailing backslash continues the statement.
        if line.endswith("\\"):
            buf += line[:-1] + " "
            continue
        buf += line
        out.append((start, buf))
        buf = ""
    if buf:
        out.append((start, buf))
    return out


def split_args(s: str) -> list[str] | None:
    """Split an argument list at top level. None if it cannot be counted."""
    args: list[str] = []
    cur = ""
    depth = 0
    i = 0
    quote = ""
    while i < len(s):
        c = s[i]
        if quote:
            if c == "\\" and quote == '"':
                cur += c + (s[i + 1] if i + 1 < len(s) else "")
                i += 2
                continue
            if c == quote:
                quote = ""
            cur += c
            i += 1
            continue
        if c in "'\"":
            quote = c
            cur += c
            i += 1
            continue
        # A command substitution is a single word when it is quoted, and is
        # consumed whole so that its own quotes and spaces do not confuse the
        # count. Anything inside it belongs to the substitution.
        if c == "$" and i + 1 < len(s) and s[i + 1] == "(":
            sub_depth = 1
            i += 2
            cur += "$("
            inner_quote = ""
            while i < len(s) and sub_depth:
                ch = s[i]
                if inner_quote:
                    if ch == "\\" and inner_quote == '"':
                        cur += ch
                        i += 1
                        if i < len(s):
                            cur += s[i]
                            i += 1
                        continue
                    if ch == inner_quote:
                        inner_quote = ""
                    cur += ch
                    i += 1
                    continue
                if ch in "'\"":
                    inner_quote = ch
                elif ch == "(":
                    sub_depth += 1
                elif ch == ")":
                    sub_depth -= 1
                    if sub_depth == 0:
                        cur += ")"
                        i += 1
                        break
                cur += ch
                i += 1
            continue
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        if c.isspace() and depth == 0:
            if cur:
                args.append(cur)
                cur = ""
            i += 1
            continue
        cur += c
        i += 1
    if cur:
        args.append(cur)
    return args


def arg_count(args: list[str]) -> int | None:
    """Number of arguments, or None if an expansion makes it unknowable."""
    n = 0
    for a in args:
        # Array/hash expansion, "$@", "$*" — length is not statically known.
        if re.search(r"\$\{[^}]*\[[@*]\][^}]*\}", a):
            return None
        if a in ('"$@"', "$@", '"$*"', "$*"):
            return None
        n += 1
    return n


def truncate_at_operator(s: str) -> str:
    """Cut an argument list at the first top-level shell operator.

    `printf '...' a b >&2` and `printf '...' a b | tr x y` have two arguments,
    not four. Redirections, pipes, `;`, `&&`, `||` and a closing `)` all end the
    argument list, and something inside a command substitution belongs to that
    substitution rather than to this printf.
    """
    depth = 0
    quote = ""
    i = 0
    while i < len(s):
        c = s[i]
        if quote:
            if c == "\\" and quote == '"':
                i += 2
                continue
            if c == quote:
                quote = ""
            i += 1
            continue
        if c in "'\"":
            quote = c
            i += 1
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            if depth == 0:
                return s[:i]
            depth -= 1
        elif depth == 0:
            if c in ";|<>&":
                return s[:i]
        i += 1
    return s


def find_printfs(text: str) -> list[tuple[int, str]]:
    """Statements that look like a printf call."""
    out = []
    # printf can appear at a statement start, or after $( or =$( or | or &&.
    pat = re.compile(r"(?:^|[;|&]|\$\()\s*printf\b")
    for m in pat.finditer(text):
        out.append((m.end(), text[m.end():]))
    return out


def check_file(path: Path) -> list[str]:
    problems: list[str] = []
    try:
        src = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return problems

    for lineno, stmt in join_continuations(src.splitlines()):
        for pos, tail in find_printfs("; " + stmt):
            if not tail.startswith(" "):
                continue
            args = split_args(truncate_at_operator(tail.strip()))
            if not args:
                continue
            fmt_raw = args[0]
            # The format must be a plain quoted literal.
            if not (fmt_raw.startswith("'") and fmt_raw.endswith("'")) and \
               not (fmt_raw.startswith('"') and fmt_raw.endswith('"')):
                continue
            fmt = fmt_raw[1:-1]
            # Skip if the format itself interpolates something dynamic.
            if "$" in fmt or "`" in fmt:
                continue
            want, stars, _ = count_specifiers(fmt)
            want += stars
            if want == 0:
                continue
            have = arg_count(args[1:])
            if have is None:
                continue
            if have == want:
                continue

            if have > want:
                # `printf '%s\n' a b c` is the idiomatic "one per line" loop and
                # is not a mistake. The dangerous case is a LINE TEMPLATE — two
                # or more conversions — because reuse then duplicates a whole
                # formatted line with empty substitutions.
                if want < 2:
                    continue
                problems.append(
                    f"{path}:{lineno}: printf has {want} conversion(s) but {have} argument(s)"
                    "  → the format will be REUSED, duplicating the line"
                )
            else:
                problems.append(
                    f"{path}:{lineno}: printf has {want} conversion(s) but only {have} argument(s)"
                    "  → the missing substitutions become empty"
                )
    return problems


def main(argv: list[str]) -> int:
    targets: list[Path] = []
    for a in argv[1:] or ["."]:
        p = Path(a)
        if p.is_dir():
            targets.extend(sorted(p.rglob("*.sh")))
            targets.extend(sorted(p.rglob("*.bash")))
        elif p.is_file():
            targets.append(p)

    total = 0
    for t in targets:
        for prob in check_file(t):
            print(prob)
            total += 1

    print(f"\n{len(targets)} file(s) scanned, {total} suspicious printf call(s)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
