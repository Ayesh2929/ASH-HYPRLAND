#!/usr/bin/env python3
import argparse
import json
import logging
import sys
from pathlib import Path
from typing import Tuple, Dict

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

def hex_to_linear(h: str) -> Tuple[float, float, float]:
    h = h.lstrip('#')
    if len(h) != 6:
        raise ValueError(f"Invalid hex color: {h}")
    rgb = [int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb)

def lum(h: str) -> float:
    r, g, b = hex_to_linear(h)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def cr(a: str, b: str) -> float:
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)

def main():
    parser = argparse.ArgumentParser(description="WCAG Contrast Checker")
    parser.add_argument("--colors-file", required=True, type=Path)
    parser.add_argument("--standard", choices=['AA', 'AAA'], default='AA')
    parser.add_argument("--output-json", type=Path)
    args = parser.parse_args()

    threshold = 4.5 if args.standard == 'AA' else 7.0

    if not args.colors_file.exists():
        logging.error(f"Colors file not found: {args.colors_file}")
        sys.exit(1)

    try:
        with open(args.colors_file, 'r') as f:
            colors = json.load(f)
    except Exception as e:
        logging.error(f"Failed to read colors file: {e}")
        sys.exit(1)

    bg = colors.get('bg', '#1e1e2e')
    results = {}
    failed = False

    for name, hex_val in colors.items():
        if name == 'bg':
            continue
        try:
            ratio = cr(hex_val, bg)
            passed = ratio >= threshold
            if not passed:
                failed = True
            
            results[name] = {
                "color": hex_val,
                "ratio": float(ratio),
                "status": "pass" if passed else "fail"
            }
            logging.info(f"{name} vs bg: {ratio:.2f}:1 - {'PASS' if passed else 'FAIL'}")
        except Exception as e:
            logging.error(f"Error checking {name}: {e}")
            results[name] = {"color": hex_val, "error": str(e), "status": "error"}
            failed = True

    if args.output_json:
        with open(args.output_json, 'w') as f:
            json.dump(results, f, indent=2)

    sys.exit(1 if failed else 0)

if __name__ == "__main__":
    main()
