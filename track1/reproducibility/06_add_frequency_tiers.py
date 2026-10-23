#!/usr/bin/env python3
"""Write a copy of the final table with gnomAD population-max AF tiers."""

import csv
import sys
from pathlib import Path

AF_COLUMN = "gnomad41_exome_AF_grpmax"
TIER_COLUMN = "GNOMAD_POPMAX_TIER"


def classify(value: str) -> str:
    if value.strip() in {"", ".", "NA", "NaN", "nan"}:
        return "Tier 1 - extremely rare (absent from gnomAD)"
    af = float(value)
    if af < 1e-4:
        return "Tier 1 - extremely rare"
    if af < 1e-3:
        return "Tier 2 - rare"
    if af < 1e-2:
        return "Tier 3 - uncommon"
    return "Tier 4 - common"


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: 06_add_frequency_tiers.py INPUT.tsv OUTPUT.tsv", file=sys.stderr)
        return 2
    input_path, output_path = map(Path, sys.argv[1:])
    with input_path.open(newline="") as source, output_path.open("w", newline="") as target:
        reader = csv.DictReader(source, delimiter="\t")
        if not reader.fieldnames or AF_COLUMN not in reader.fieldnames:
            raise ValueError(f"Required column not found: {AF_COLUMN}")
        fields = list(reader.fieldnames)
        fields.insert(fields.index(AF_COLUMN) + 1, TIER_COLUMN)
        writer = csv.DictWriter(target, delimiter="\t", fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in reader:
            row[TIER_COLUMN] = classify(row[AF_COLUMN])
            writer.writerow(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

