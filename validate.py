#!/usr/bin/env python3
import sys
import json
import argparse
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description="ASH Dotfiles Validation Script")
    parser.add_argument("--strict", action="store_true", help="Exit non-zero on warnings")
    parser.add_argument("--sarif", action="store_true", help="Output in SARIF format")
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
                        json.load(f)
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