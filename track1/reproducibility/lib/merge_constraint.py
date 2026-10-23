#!/usr/bin/env python3
"""Add MANE/canonical gnomAD v4.1.1 constraint metrics by gene symbol."""

import csv
import gzip
import sys
from pathlib import Path

WANTED = ["gene_id", "transcript", "mane_select", "canonical", "gene_flags", "constraint_flags", "lof.oe", "lof.z_score", "lof.oe_ci.lower", "lof.oe_ci.upper", "lof.pLI", "mis.oe", "mis.z_score", "syn.oe", "syn.z_score"]


def truthy(value: str) -> bool:
    return value.lower() in {"true", "1", "yes"}


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: merge_constraint.py INPUT.tsv CONSTRAINT.tsv.bgz OUTPUT.tsv", file=sys.stderr)
        return 2
    input_path, constraint_path, output_path = map(Path, sys.argv[1:])
    selected = {}
    with gzip.open(constraint_path, "rt", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if not reader.fieldnames or "gene" not in reader.fieldnames:
            raise ValueError("Unexpected gnomAD constraint header")
        available = [c for c in WANTED if c in reader.fieldnames]
        for row in reader:
            gene = row.get("gene", "")
            priority = 2 if truthy(row.get("mane_select", "")) else 1 if truthy(row.get("canonical", "")) else 0
            if gene and (gene not in selected or priority > selected[gene][0]):
                selected[gene] = priority, {c: row.get(c, "") or "." for c in available}
    prefix = "GNOMAD_V4_1_1_CONSTRAINT_"
    added = [prefix + c for c in available]
    with input_path.open(newline="") as source, output_path.open("w", newline="") as target:
        reader = csv.DictReader(source, delimiter="\t")
        if not reader.fieldnames:
            raise ValueError("Input table has no header")
        writer = csv.DictWriter(target, delimiter="\t", fieldnames=list(reader.fieldnames) + added, lineterminator="\n")
        writer.writeheader()
        for row in reader:
            values = selected.get(row.get("GENE_SYMBOL", ""), (0, {}))[1]
            row.update({prefix + c: values.get(c, ".") for c in available})
            writer.writerow(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

