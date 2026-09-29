#!/usr/bin/env bash
set -euo pipefail

# Create a ~10% stratified subset of the infilling dataset.
# Strata: domain (dataset) x blank position (unit_idx).
#
# Usage:
#   bash robustness/data_subset/make_subset.sh
# Optional:
#   FRACTION=0.1 SEED=42 bash robustness/data_subset/make_subset.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

INPUT_CSV="${INPUT_CSV:-$PROJECT_ROOT/dataset/infilling_dataset.csv}"
OUTPUT_CSV="${OUTPUT_CSV:-$SCRIPT_DIR/infilling_dataset_subset_10pct.csv}"
FRACTION="${FRACTION:-0.1}"
SEED="${SEED:-42}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [[ ! -f "$INPUT_CSV" ]]; then
  echo "ERROR: input CSV not found: $INPUT_CSV"
  exit 1
fi

"$PYTHON_BIN" - "$INPUT_CSV" "$OUTPUT_CSV" "$FRACTION" "$SEED" <<'PY'
import sys
from pathlib import Path

import pandas as pd

input_csv = Path(sys.argv[1])
output_csv = Path(sys.argv[2])
fraction = float(sys.argv[3])
seed = int(sys.argv[4])

df = pd.read_csv(input_csv)
required = {"dataset", "unit_idx"}
missing = required - set(df.columns)
if missing:
    raise SystemExit(f"Missing required columns: {sorted(missing)}")

parts = []
for _, group in df.groupby(["dataset", "unit_idx"], sort=False):
    n = max(1, int(round(len(group) * fraction)))
    n = min(n, len(group))
    parts.append(group.sample(n=n, random_state=seed))

subset = pd.concat(parts, ignore_index=True)
subset = subset.sample(frac=1.0, random_state=seed).reset_index(drop=True)

output_csv.parent.mkdir(parents=True, exist_ok=True)
subset.to_csv(output_csv, index=False)

print(f"Input : {input_csv}")
print(f"Output: {output_csv}")
print(f"Seed  : {seed}")
print(f"Frac  : {fraction}")
print(f"Full size   : {len(df)}")
print(f"Subset size : {len(subset)} ({100.0 * len(subset) / len(df):.2f}%)")
print("\nDomain counts in subset:")
print(subset["dataset"].value_counts().to_string())
PY
