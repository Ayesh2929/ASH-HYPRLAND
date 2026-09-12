#!/usr/bin/env python3
"""
╔═══════════════════════════════════════════════════════════════════════════════╗
║  ⚡ ASH DOTFILES v5.0 OMEGA — theme/generate-gallery.py                        ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Builds docs/theme-gallery.html: a browsable, self-contained view of every theme
in themes/.

The output is ONE file with no external requests. That is deliberate — the
gallery has to work from a file:// URL, from a GitHub Pages branch, and from
inside the sandboxed preview iframe, and a page that fetches its own theme
metadata would fail in the last two.

Usage:
    scripts/theme/generate-gallery.py [--themes DIR] [--out FILE]
"""

from __future__ import annotations

import argparse
import glob
import html
import json
import os
import sys

SWATCH_ORDER = [
    "base", "mantle", "crust", "surface", "overlay", "subtext", "text",
    "accent", "mint", "sky", "gold", "rose", "violet",
]


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def load_themes(directory: str) -> list[dict]:
    """Every *.json in `directory` that looks like a theme.

    The directory also holds its JSON Schema and possibly index files. Those are
    not themes, and rendering them as cards with empty swatches would make the
    gallery look broken, so anything without a `base` slot is skipped.
    """
    themes = []
    for path in sorted(glob.glob(os.path.join(directory, "*.json"))):
        try:
            with open(path) as handle:
                data = json.load(handle)
        except (OSError, json.JSONDecodeError) as exc:
            print(f"  skip {os.path.basename(path)}: {exc}", file=sys.stderr)
            continue

        colors = data.get("colors")
        if not isinstance(colors, dict) or "base" not in colors:
            continue

        themes.append(data)
    return themes


def render_card(theme: dict) -> str:
    colors = theme["colors"]

    preview = f'''<div class="mini" style="background:{colors['base']};border-color:{colors['surface']}">
  <div class="minibar" style="background:{colors['mantle']}">
    <span style="background:{colors['accent']};width:26%"></span>
    <span style="background:{colors['overlay']};width:14%"></span>
    <span style="background:{colors['overlay']};width:18%"></span>
  </div>
  <div class="minibody">
    <div class="miniline" style="background:{colors['text']};width:62%"></div>
    <div class="miniline" style="background:{colors['subtext']};width:44%"></div>
    <div class="miniline" style="background:{colors['overlay']};width:74%"></div>
    <div class="minichips">
      <b style="background:{colors['mint']}"></b><b style="background:{colors['sky']}"></b>
      <b style="background:{colors['gold']}"></b><b style="background:{colors['rose']}"></b>
      <b style="background:{colors['violet']}"></b>
    </div>
  </div>
</div>'''

    swatches = "".join(
        f'<i style="background:{colors[slot]}" title="{slot} {colors[slot]}"></i>'
        for slot in SWATCH_ORDER if slot in colors
    )

    return f'''<article class="card" data-name="{esc(theme['name']).lower()}" data-family="{esc(theme.get('family',''))}" data-variant="{esc(theme.get('variant',''))}" style="--accent:{colors['accent']}">
  {preview}
  <div class="meta">
    <h3>{esc(theme['name'])}</h3>
    <p>{esc(theme.get('description', ''))}</p>
    <div class="row"><span class="tag {esc(theme.get('variant',''))}">{esc(theme.get('variant',''))}</span><span class="tag">{esc(theme.get('family',''))}</span><code>{esc(colors['accent'])}</code></div>
  </div>
  <div class="swatches">{swatches}</div>
</article>'''


TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>ASH Theme Library — {count} themes</title>
<style>
:root {{
  --bg:#11111b; --mantle:#181825; --crust:#0b0b12; --surface:#1e1e2e;
  --overlay:#313244; --text:#cdd6f4; --subtext:#a6adc8;
  --accent:#cba6f7; --mint:#a6e3a1; --sky:#89dceb; --gold:#f9e2af;
  --rose:#f38ba8; --violet:#b4befe;
  --radius:16px; --ease:cubic-bezier(.2,.8,.2,1);
}}
@media (prefers-reduced-motion: reduce) {{
  *,*::before,*::after {{ animation-duration:.001ms !important; transition-duration:.001ms !important }}
}}
*{{box-sizing:border-box}}
html,body{{margin:0;padding:0}}
body{{
  background:var(--bg); color:var(--text);
  font:15px/1.55 ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;
  -webkit-font-smoothing:antialiased; min-height:100vh;
}}
body::before{{
  content:""; position:fixed; inset:-30vmax; z-index:-1; pointer-events:none;
  background:
    radial-gradient(closest-side, color-mix(in oklab, var(--accent) 26%, transparent), transparent 70%) 22% 18%/44vmax 44vmax no-repeat,
    radial-gradient(closest-side, color-mix(in oklab, var(--sky) 22%, transparent), transparent 70%) 78% 30%/40vmax 40vmax no-repeat,
    radial-gradient(closest-side, color-mix(in oklab, var(--rose) 18%, transparent), transparent 70%) 50% 88%/46vmax 46vmax no-repeat;
  filter:blur(28px); opacity:.5;
  animation:drift 44s var(--ease) infinite alternate;
}}
@keyframes drift {{
  from {{ transform:translate3d(-3%,-2%,0) scale(1) }}
  to   {{ transform:translate3d(4%,3%,0) scale(1.12) }}
}}
header{{
  position:sticky; top:0; z-index:10; padding:22px 26px 16px;
  background:linear-gradient(to bottom, var(--crust) 60%, transparent);
  backdrop-filter:blur(14px); border-bottom:1px solid var(--surface);
}}
h1{{margin:0 0 4px; font-size:26px; letter-spacing:-.02em}}
h1 em{{font-style:normal; color:var(--accent)}}
.sub{{color:var(--subtext); font-size:13px; margin:0 0 14px}}
.bar{{display:flex; gap:10px; flex-wrap:wrap; align-items:center}}
input[type=search]{{
  flex:1; min-width:200px; padding:10px 14px;
  background:var(--surface); color:var(--text);
  border:1px solid var(--overlay); border-radius:999px;
  font-size:14px; outline:none;
  transition:border-color .18s var(--ease), box-shadow .18s var(--ease);
}}
input[type=search]:focus{{
  border-color:var(--accent);
  box-shadow:0 0 0 4px color-mix(in oklab, var(--accent) 22%, transparent);
}}
.chip{{
  padding:7px 13px; border-radius:999px; cursor:pointer;
  background:var(--surface); color:var(--subtext);
  border:1px solid var(--overlay); font-size:12.5px;
  transition:all .16s var(--ease);
}}
.chip:hover{{color:var(--text); border-color:var(--accent); transform:translateY(-1px)}}
.chip[aria-pressed=true]{{background:var(--accent); color:var(--crust); border-color:var(--accent); font-weight:600}}
main{{padding:24px 26px 80px; display:grid; gap:18px; grid-template-columns:repeat(auto-fill, minmax(268px,1fr))}}
.card{{
  background:color-mix(in oklab, var(--mantle) 88%, transparent);
  border:1px solid var(--surface); border-radius:var(--radius);
  overflow:hidden; display:flex; flex-direction:column;
  transition:transform .22s var(--ease), border-color .22s var(--ease), box-shadow .22s var(--ease);
  animation:rise .5s var(--ease) both;
}}
@keyframes rise {{ from {{opacity:0; transform:translateY(14px)}} to {{opacity:1; transform:none}} }}
.card:hover{{
  transform:translateY(-4px); border-color:var(--accent);
  box-shadow:0 14px 40px -18px var(--accent), 0 2px 8px rgba(0,0,0,.4);
}}
.mini{{padding:10px; border-bottom:1px solid var(--surface)}}
.minibar{{display:flex; gap:5px; padding:5px 7px; border-radius:7px 7px 0 0}}
.minibar span{{height:7px; border-radius:3px; display:block}}
.minibody{{padding:11px 9px; display:flex; flex-direction:column; gap:6px}}
.miniline{{height:6px; border-radius:3px; opacity:.85}}
.minichips{{display:flex; gap:5px; margin-top:5px}}
.minichips b{{width:14px; height:14px; border-radius:5px; display:block}}
.meta{{padding:12px 14px 8px; flex:1}}
.meta h3{{margin:0 0 3px; font-size:15px}}
.meta p{{margin:0 0 9px; font-size:12px; color:var(--subtext)}}
.row{{display:flex; gap:6px; align-items:center; flex-wrap:wrap}}
.tag{{font-size:10.5px; padding:2.5px 8px; border-radius:999px; background:var(--surface); color:var(--subtext); border:1px solid var(--overlay)}}
.tag.dark{{color:var(--sky); border-color:color-mix(in oklab, var(--sky) 40%, transparent)}}
.tag.light{{color:var(--gold); border-color:color-mix(in oklab, var(--gold) 40%, transparent)}}
code{{font-size:11px; color:var(--accent); margin-left:auto}}
.swatches{{display:flex; height:16px}}
.swatches i{{flex:1; transition:flex .2s var(--ease)}}
.swatches i:hover{{flex:2.4}}
.empty{{grid-column:1/-1; text-align:center; padding:60px; color:var(--subtext)}}
footer{{padding:0 26px 40px; color:var(--overlay); font-size:12px}}
</style>
</head>
<body>
<header>
  <h1>ASH <em>Theme Library</em></h1>
  <p class="sub">{count} themes, every one derived from a seed colour and verified against WCAG AA before it ships.</p>
  <div class="bar">
    <input type="search" id="q" placeholder="Search themes…  (press / )" autocomplete="off">
    <button class="chip" data-family="" aria-pressed="true">all</button>
    {chips}
  </div>
</header>
<main id="grid">{cards}</main>
<footer>Generated by scripts/theme/generate-gallery.py — do not edit themes/*.json by hand.</footer>
<script>
const grid = document.getElementById('grid');
const cards = [...grid.querySelectorAll('.card')];
const q = document.getElementById('q');
const chips = [...document.querySelectorAll('.chip')];
let family = '';

// Filtering ~360 cards on every keystroke stays well under a frame, so there is
// no debounce and no virtualisation. Adding either would only make the
// interaction feel slower than the work it is avoiding.
function apply() {{
  const term = q.value.trim().toLowerCase();
  let shown = 0;
  for (const card of cards) {{
    const okText = !term || card.dataset.name.includes(term) || card.dataset.family.includes(term);
    const okFam  = !family || card.dataset.family === family;
    const ok = okText && okFam;
    card.style.display = ok ? '' : 'none';
    if (ok) shown++;
  }}
  let note = document.getElementById('none');
  if (!shown) {{
    if (!note) {{
      note = document.createElement('p');
      note.id = 'none'; note.className = 'empty';
      note.textContent = 'No themes match that search.';
      grid.appendChild(note);
    }}
  }} else if (note) note.remove();
}}

q.addEventListener('input', apply);
for (const chip of chips) {{
  chip.addEventListener('click', () => {{
    family = chip.dataset.family;
    for (const c of chips) c.setAttribute('aria-pressed', String(c === chip));
    apply();
  }});
}}

// "/" focuses search, Escape clears it — the conventions people already have.
addEventListener('keydown', e => {{
  if (e.key === '/' && document.activeElement !== q) {{ e.preventDefault(); q.focus(); }}
  if (e.key === 'Escape' && document.activeElement === q) {{ q.value = ''; apply(); q.blur(); }}
}});

// Stagger the entrance so the grid arrives rather than snapping in.
cards.forEach((c, i) => c.style.animationDelay = Math.min(i * 6, 600) + 'ms');
</script>
</body>
</html>"""


def main() -> int:
    parser = argparse.ArgumentParser(description="Build the ASH theme gallery.")
    parser.add_argument("--themes", default="themes", help="directory of theme JSON files")
    parser.add_argument("--out", default="docs/theme-gallery.html", help="output HTML path")
    args = parser.parse_args()

    themes = load_themes(args.themes)
    if not themes:
        print(f"generate-gallery: no themes found in {args.themes}", file=sys.stderr)
        return 1

    families = sorted({t.get("family", "") for t in themes if t.get("family")})
    chips = "".join(f'<button class="chip" data-family="{esc(f)}">{esc(f)}</button>' for f in families)

    document = TEMPLATE.format(
        count=len(themes),
        chips=chips,
        cards="\n".join(render_card(t) for t in themes),
    )

    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    with open(args.out, "w") as handle:
        handle.write(document)

    size_kb = os.path.getsize(args.out) / 1024
    print(f"  {args.out}: {len(themes)} themes, {len(families)} families, {size_kb:,.0f} kB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
