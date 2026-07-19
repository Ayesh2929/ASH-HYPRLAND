from pathlib import Path
import sys

base = Path('config')

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

issues = 0
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

if issues:
    sys.exit(1)