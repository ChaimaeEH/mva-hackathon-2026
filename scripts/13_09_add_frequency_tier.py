#!/usr/bin/env python3
"""Add a gnomAD population-maximum AF rarity tier to the final result table."""

from __future__ import annotations

import csv
import os
import sys
import tempfile
from collections import Counter
from pathlib import Path


AF_COLUMN = "gnomad41_exome_AF_grpmax"
TIER_COLUMN = "GNOMAD_POPMAX_TIER"


def classify(value: str) -> str:
    text = value.strip()
    if text in {"", ".", "NA", "NaN", "nan"}:
        return "Tier 1 - extremely rare (absent from gnomAD)"

    af = float(text)
    if af < 1e-4:
        return "Tier 1 - extremely rare"
    if af < 1e-3:
        return "Tier 2 - rare"
    if af < 1e-2:
        return "Tier 3 - uncommon"
    return "Tier 4 - common"


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {Path(sys.argv[0]).name} TABLE.tsv", file=sys.stderr)
        return 2

    table = Path(sys.argv[1]).resolve()
    counts: Counter[str] = Counter()

    with table.open(newline="") as source:
        reader = csv.DictReader(source, delimiter="\t")
        if not reader.fieldnames or AF_COLUMN not in reader.fieldnames:
            raise ValueError(f"Required column not found: {AF_COLUMN}")

        fieldnames = list(reader.fieldnames)
        if TIER_COLUMN not in fieldnames:
            insert_at = fieldnames.index(AF_COLUMN) + 1
            fieldnames.insert(insert_at, TIER_COLUMN)

        with tempfile.NamedTemporaryFile(
            mode="w",
            newline="",
            dir=table.parent,
            prefix=f".{table.name}.",
            suffix=".tmp",
            delete=False,
        ) as target:
            temporary = Path(target.name)
            writer = csv.DictWriter(
                target, delimiter="\t", fieldnames=fieldnames, lineterminator="\n"
            )
            writer.writeheader()
            for row in reader:
                tier = classify(row[AF_COLUMN])
                row[TIER_COLUMN] = tier
                counts[tier] += 1
                writer.writerow(row)

    os.replace(temporary, table)
    print(f"Updated: {table}")
    for tier in sorted(counts):
        print(f"{tier}: {counts[tier]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
