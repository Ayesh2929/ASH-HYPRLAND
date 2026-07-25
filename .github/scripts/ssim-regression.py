#!/usr/bin/env python3
import argparse
import json
import logging
import sys
from pathlib import Path
try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("Error: PIL and numpy are required.")
    sys.exit(1)

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

def ssim(p1: Path, p2: Path) -> float:
    sz = (256, 144)
    a = np.array(Image.open(p1).convert('RGB').resize(sz)).astype(float)
    b = np.array(Image.open(p2).convert('RGB').resize(sz)).astype(float)
    mu_a, mu_b = a.mean(), b.mean()
    sig_a, sig_b = a.std(), b.std()
    sig_ab = np.mean((a - mu_a) * (b - mu_b))
    C1, C2 = (0.01 * 255) ** 2, (0.03 * 255) ** 2
    num = (2 * mu_a * mu_b + C1) * (2 * sig_ab + C2)
    den = (mu_a**2 + mu_b**2 + C1) * (sig_a**2 + sig_b**2 + C2)
    return num / den

def main():
    parser = argparse.ArgumentParser(description="SSIM Visual Regression Tool")
    parser.add_argument("--baseline-dir", required=True, type=Path)
    parser.add_argument("--current-dir", required=True, type=Path)
    parser.add_argument("--threshold", type=float, default=0.95)
    parser.add_argument("--output-json", type=Path)
    args = parser.parse_args()

    results = {}
    failed = False

    for current_file in args.current_dir.glob("*.webp"):
        baseline_file = args.baseline_dir / current_file.name
        if not baseline_file.exists():
            logging.info(f"New image: {current_file.name}")
            results[current_file.name] = {"status": "new", "score": None}
            continue

        try:
            score = ssim(current_file, baseline_file)
            logging.info(f"{current_file.name}: SSIM = {score:.4f}")
            passed = score >= args.threshold
            if not passed:
                failed = True
                logging.error(f"{current_file.name} failed (score {score:.4f} < {args.threshold})")
            
            results[current_file.name] = {
                "status": "pass" if passed else "fail",
                "score": float(score)
            }
        except Exception as e:
            logging.error(f"Error processing {current_file.name}: {e}")
            results[current_file.name] = {"status": "error", "score": None}
            failed = True

    if args.output_json:
        with open(args.output_json, 'w') as f:
            json.dump(results, f, indent=2)

    sys.exit(1 if failed else 0)

if __name__ == "__main__":
    main()
