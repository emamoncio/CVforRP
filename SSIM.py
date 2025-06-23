

import os
import cv2
import pandas as pd
from itertools import combinations
from tqdm import tqdm

# ---------- paths ----------
TARGET_DIR   = "/Users/exyamc/Dropbox/RP/Revision/Documentation/Preprocessed"  # ← your images here
OUTPUT_CSV   = os.path.join(TARGET_DIR, "design_ssim_2.csv")

# ---------- constants ----------
C1 = (0.01 * 255) ** 2
C2 = (0.03 * 255) ** 2
EPS = 1e-12

# ---------- tiny helpers ----------
def brightness(img):           # mean intensity
    return img.mean()

def contrast(img):             # standard deviation
    return img.std()

def covariance(img1, img2):
    return ((img1 - img1.mean()) * (img2 - img2.mean())).mean()

def calc_ssim(img1, img2):
    L1, L2 = brightness(img1), brightness(img2)
    C1_ = contrast(img1)
    C2_ = contrast(img2)
    Cov = covariance(img1, img2)

    luminance  = (2 * L1 * L2 + C1) / (L1**2 + L2**2 + C1)
    contrast_t = (2 * C1_ * C2_ + C2) / (C1_**2 + C2_**2 + C2)
    structure  = (Cov + C2) / (C1_ * C2_ + C2 + EPS)

    return luminance * contrast_t * structure   # your “calculated_ssim”

# ---------- gather files ----------
files = [f for f in os.listdir(TARGET_DIR)
         if f.lower().endswith((".png", ".jpg", ".jpeg"))]

if len(files) < 2:
    raise SystemExit("Need at least two images to compare.")

pairs = combinations(sorted(files), 2)

import re

# ---------- main loop ----------
records = []
for f1, f2 in tqdm(list(pairs), desc="SSIM pairs", unit="pair"):
    img1_path = os.path.join(TARGET_DIR, f1)
    img2_path = os.path.join(TARGET_DIR, f2)
    img1 = cv2.imread(img1_path, cv2.IMREAD_GRAYSCALE)
    img2 = cv2.imread(img2_path, cv2.IMREAD_GRAYSCALE)

    if img1 is None or img2 is None:
        print(f"[read-fail] {f1}  /  {f2}")
        continue

    # Extract numeric part only (e.g., from D123456_ap.png → 123456)
    id1 = re.findall(r"\d+", f1)[0]
    id2 = re.findall(r"\d+", f2)[0]

    ssim_val = calc_ssim(img1, img2)
    records.append({"design1": id1, "design2": id2, "ssim": float(ssim_val)})

# ---------- save ----------
pd.DataFrame(records).to_csv(OUTPUT_CSV, index=False)
print(f"✓ SSIM table saved to {OUTPUT_CSV}")

