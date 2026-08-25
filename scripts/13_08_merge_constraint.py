#!/usr/bin/env python3
"""Add MANE/canonical gnomAD v4.1.1 constraint metrics by gene symbol."""

from __future__ import annotations

import csv
import gzip
import sys
from pathlib import Path


WANTED = [
    "gene_id", "transcript", "mane_select", "canonical", "gene_flags",
    "constraint_flags", "lof.oe", "lof.z_score", "lof.oe_ci.lower",
    "lof.oe_ci.upper", "lof.oe_ci.upper_rank", "lof.oe_ci.upper_bin_percentile",
    "lof.pLI", "mis.oe", "mis.z_score", "syn.oe", "syn.z_score",
]


def is_true(value: str) -> bool:
    return value.lower() in {"true", "1", "yes"}


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: 13_08_merge_constraint.py INPUT_TSV CONSTRAINT_BGZ OUTPUT_TSV", file=sys.stderr)
        return 2

    input_path, constraint_path, output_path = map(Path, sys.argv[1:])
    selected: dict[str, tuple[int, dict[str, str]]] = {}
    with gzip.open(constraint_path, "rt", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if not reader.fieldnames or "gene" not in reader.fieldnames:
            raise ValueError("Unexpected gnomAD constraint header")
        available = [name for name in WANTED if name in reader.fieldnames]
        for row in reader:
            gene = row.get("gene", "")
            if not gene:
                continue
            priority = 2 if is_true(row.get("mane_select", "")) else 1 if is_true(row.get("canonical", "")) else 0
            old = selected.get(gene)
            if old is None or priority > old[0]:
                selected[gene] = (priority, {name: row.get(name, "") or "." for name in available})

    prefix = "GNOMAD_V4_1_1_CONSTRAINT_"
    added_columns = [prefix + name for name in available]
    matched = total = 0
    with input_path.open(newline="") as source, output_path.open("w", newline="") as target:
        reader = csv.DictReader(source, delimiter="\t")
        if not reader.fieldnames:
            raise ValueError(f"Missing header: {input_path}")
        writer = csv.DictWriter(target, delimiter="\t", fieldnames=list(reader.fieldnames) + added_columns, lineterminator="\n")
        writer.writeheader()
        for row in reader:
            total += 1
            entry = selected.get(row.get("GENE_SYMBOL", ""))
            if entry:
                matched += 1
                values = entry[1]
                row.update({prefix + name: values[name] for name in available})
            else:
                row.update({name: "." for name in added_columns})
            writer.writerow(row)

    print(f"Added {len(added_columns)} gnomAD v4.1.1 constraint columns; matched {matched}/{total} rows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
