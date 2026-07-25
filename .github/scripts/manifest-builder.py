#!/usr/bin/env python3
import argparse
import json
import logging
import sys
from pathlib import Path
from typing import Dict, Any

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

def main():
    parser = argparse.ArgumentParser(description="ASH Dotfiles Manifest Builder")
    parser.add_argument("--themes-dir", required=True, type=Path)
    parser.add_argument("--output", type=Path, default=Path("manifest.json"))
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not args.themes_dir.is_dir():
        logging.error(f"Themes directory not found: {args.themes_dir}")
        sys.exit(1)

    manifest: Dict[str, Any] = {
        "version": "1.0",
        "themes": {}
    }

    for theme_dir in args.themes_dir.iterdir():
        if not theme_dir.is_dir():
            continue

        colors_file = theme_dir / "colors.json"
        if colors_file.exists():
            try:
                with open(colors_file, 'r') as f:
                    colors = json.load(f)
                
                theme_name = theme_dir.name
                manifest["themes"][theme_name] = {
                    "name": theme_name,
                    "colors": colors,
                    "screenshot_path": f"assets/screenshots/{theme_name}.webp"
                }
            except Exception as e:
                logging.error(f"Error reading colors for {theme_dir.name}: {e}")
    
    manifest["total_themes"] = len(manifest["themes"])

    if args.dry_run:
        logging.info("Dry run - would write:")
        print(json.dumps(manifest, indent=2))
    else:
        try:
            with open(args.output, 'w') as f:
                json.dump(manifest, f, indent=2)
            logging.info(f"Manifest written to {args.output} with {manifest['total_themes']} themes")
        except Exception as e:
            logging.error(f"Failed to write manifest: {e}")
            sys.exit(1)

if __name__ == "__main__":
    main()
