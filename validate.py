#!/usr/bin/env python3
import sys
import json
import re
import argparse
from pathlib import Path


def strip_jsonc(text):
    """Remove // and /* */ comments plus trailing commas from JSONC.

    VS Code and Zed both allow comments in their config files, so parsing them
    with a plain json.load() reports valid files as broken. String-aware: a //
    inside a string literal (e.g. "xdg-open https://wttr.in") is left alone.
    """
    out = []
    i, n = 0, len(text)
    in_string = False
    escaped = False

    while i < n:
        char = text[i]

        if in_string:
            out.append(char)
            if escaped:
                escaped = False
            elif char == '\\':
                escaped = True
            elif char == '"':
                in_string = False
            i += 1
            continue

        if char == '"':
            in_string = True
            out.append(char)
            i += 1
            continue

        if char == '/' and i + 1 < n and text[i + 1] == '/':
            while i < n and text[i] not in '\r\n':
                i += 1
            continue

        if char == '/' and i + 1 < n and text[i + 1] == '*':
            i += 2
            while i + 1 < n and not (text[i] == '*' and text[i + 1] == '/'):
                i += 1
            i += 2
            continue

        out.append(char)
        i += 1

    return re.sub(r',(\s*[}\]])', r'\1', ''.join(out))

def main():
    parser = argparse.ArgumentParser(description="ASH Dotfiles Validation Script")
    parser.add_argument("--strict", action="store_true", help="Exit non-zero on warnings")
    parser.add_argument("--sarif", action="store_true", help="Output in SARIF format")
    parser.add_argument("--check-stubs", action="store_true", help="Also check for omega stub placeholders")
    args = parser.parse_args()

    base = Path('config')
    issues = 0
    warnings = 0
    sarif_results = []

    counts = {
        'Shell scripts (.sh)': len(list(base.rglob('*.sh'))),
        'Lua files (.lua)': len(list(base.rglob('*.lua'))),
        'Config files (.conf)': len(list(base.rglob('*.conf'))),
        'CSS files (.css)': len(list(base.rglob('*.css'))),
        'SCSS files (.scss)': len(list(base.rglob('*.scss'))),
        'JSON/JSONC (.json*)': len(list(base.rglob('*.json*'))),
        'TOML files (.toml)': len(list(base.rglob('*.toml'))),
        'Fish files (.fish)': len(list(base.rglob('*.fish'))),
        'JavaScript (.js)': len(list(base.rglob('*.js'))),
        'RASI files (.rasi)': len(list(base.rglob('*.rasi'))),
        'GLSL shaders (.glsl)': len(list(base.rglob('*.glsl'))),
        'Yuck files (.yuck)': len(list(base.rglob('*.yuck'))),
    }

    total = sum(counts.values())
    print(f"\n{'='*50}")
    print(f"{'ASH Dotfiles File Count Report':^50}")
    print(f"{'='*50}")
    for category, count in sorted(counts.items(), key=lambda x: -x[1]):
        bar = '█' * min(count // 2, 30)
        print(f"  {category:<30} {count:>4}  {bar}")
    print(f"{'─'*50}")
    print(f"  {'TOTAL CONFIG FILES':<30} {total:>4}")

    MIN_TOTAL = 150
    MIN_SCRIPTS = 60

    print(f"\n{'Verification':^50}")
    print(f"{'─'*50}")

    if total >= MIN_TOTAL:
        print(f"  ✅ Total files: {total} (min: {MIN_TOTAL})")
    else:
        print(f"  ❌ Too few files: {total} (min: {MIN_TOTAL})")
        issues += 1

    scripts = counts['Shell scripts (.sh)']
    if scripts >= MIN_SCRIPTS:
        print(f"  ✅ Shell scripts: {scripts} (min: {MIN_SCRIPTS})")
    else:
        print(f"  ❌ Too few scripts: {scripts} (min: {MIN_SCRIPTS})")
        issues += 1

    # Additional Checks
    print(f"\n{'Extended Checks':^50}")
    print(f"{'─'*50}")

    # Broken symlinks
    broken_symlinks = 0
    if base.exists():
        for p in base.rglob('*'):
            if p.is_symlink() and not p.exists():
                print(f"  ❌ Broken symlink: {p}")
                broken_symlinks += 1
                issues += 1
                sarif_results.append({
                    "ruleId": "BROKEN_SYMLINK",
                    "level": "error",
                    "message": {"text": f"Broken symlink found: {p}"},
                    "locations": [{"physicalLocation": {"artifactLocation": {"uri": str(p)}}}]
                })
    if broken_symlinks == 0:
        print("  ✅ No broken symlinks")

    # Windows line endings
    crlf_files = 0
    if base.exists():
        for p in base.rglob('*'):
            if p.is_file() and not p.is_symlink():
                try:
                    with open(p, 'rb') as f:
                        if b'\r\n' in f.read():
                            print(f"  ⚠️  CRLF line endings: {p}")
                            crlf_files += 1
                            warnings += 1
                            sarif_results.append({
                                "ruleId": "CRLF_LINE_ENDINGS",
                                "level": "warning",
                                "message": {"text": f"CRLF line endings found: {p}"},
                                "locations": [{"physicalLocation": {"artifactLocation": {"uri": str(p)}}}]
                            })
                except Exception:
                    pass
    if crlf_files == 0:
        print("  ✅ No CRLF line endings")

    # Shell scripts missing shebang
    missing_shebang = 0
    if base.exists():
        for p in base.rglob('*.sh'):
            if p.is_file() and not p.is_symlink():
                try:
                    with open(p, 'r', encoding='utf-8') as f:
                        first_line = f.readline()
                        if not first_line.startswith('#!'):
                            print(f"  ❌ Missing shebang: {p}")
                            missing_shebang += 1
                            issues += 1
                            sarif_results.append({
                                "ruleId": "MISSING_SHEBANG",
                                "level": "error",
                                "message": {"text": f"Missing shebang in shell script: {p}"},
                                "locations": [{"physicalLocation": {"artifactLocation": {"uri": str(p)}}}]
                            })
                except Exception:
                    pass
    if missing_shebang == 0:
        print("  ✅ All shell scripts have shebangs")

    # JSON syntax validation
    invalid_json = 0
    if base.exists():
        for p in base.rglob('*.json'):
            if p.is_file() and not p.is_symlink():
                try:
                    with open(p, 'r', encoding='utf-8') as f:
                        raw = f.read()
                    # Accept JSONC (comments / trailing commas) — VS Code and
                    # Zed configs are JSONC by design.
                    json.loads(strip_jsonc(raw))
                except json.JSONDecodeError as e:
                    print(f"  ❌ Invalid JSON in {p}: {e}")
                    invalid_json += 1
                    issues += 1
                    sarif_results.append({
                        "ruleId": "INVALID_JSON",
                        "level": "error",
                        "message": {"text": f"Invalid JSON syntax in {p}: {e}"},
                        "locations": [{"physicalLocation": {"artifactLocation": {"uri": str(p)}}}]
                    })
                except Exception:
                    pass
    if invalid_json == 0:
        print("  ✅ All JSON files are valid")

    # Check for omega stub JSON files outside config (opt-in via --check-stubs)
    if args.check_stubs:
        stub_jsons = []
        for p in Path('.').rglob('*.json'):
            if '.git' in str(p) or 'node_modules' in str(p):
                continue
            try:
                raw = p.read_text(encoding='utf-8')
                if '"status": "ready"' in raw and 'ASH Dotfiles OMEGA component' in raw:
                    try:
                        data = json.loads(raw)
                        if data.get('status') == 'ready' and data.get('version') == '5.0.0-omega':
                            stub_jsons.append(p)
                    except:
                        pass
            except:
                pass
        if stub_jsons:
            for pj in stub_jsons[:20]:
                print(f"  ⚠️  Stub JSON (should be real schema/data): {pj}")
                warnings += 1
            if len(stub_jsons) > 20:
                print(f"  ... and {len(stub_jsons)-20} more stub JSONs")
        else:
            print("  ✅ No stub JSONs in repo (outside .git)")

        stub_sh = 0
        for p in Path('.').rglob('*.sh'):
            if '.git' in str(p):
                continue
            try:
                if 'omega stub' in p.read_text(encoding='utf-8'):
                    stub_sh += 1
            except:
                pass
        if stub_sh > 300:
            print(f"  ⚠️  {stub_sh} shell scripts are stubs (omega stub) — expected < 50 for production")
            warnings += 1
        else:
            print(f"  ✅ Stub shell scripts: {stub_sh} (threshold 300)")


    if args.sarif:
        sarif = {
            "version": "2.1.0",
            "$schema": "http://json.schemastore.org/sarif-2.1.0-rtm.5",
            "runs": [
                {
                    "tool": {
                        "driver": {
                            "name": "ASH Dotfiles Validator",
                            "informationUri": "https://ash-dotfiles.dev",
                            "rules": []
                        }
                    },
                    "results": sarif_results
                }
            ]
        }
        with open("validation-results.sarif", "w", encoding="utf-8") as f:
            json.dump(sarif, f, indent=2)
        print("\n  ✅ SARIF report generated: validation-results.sarif")

    print(f"\n{'Summary':^50}")
    print(f"{'─'*50}")
    print(f"  Errors:   {issues}")
    print(f"  Warnings: {warnings}")

    if issues > 0:
        sys.exit(1)
    elif warnings > 0 and args.strict:
        sys.exit(2)
    else:
        sys.exit(0)

if __name__ == '__main__':
    main()