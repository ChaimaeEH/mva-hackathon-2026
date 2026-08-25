#!/usr/bin/env python3
"""Merge ANNOVAR gnomAD v4.1 frequency columns into Exomiser variants."""

from __future__ import annotations

import csv
import sys
from pathlib import Path


def canonical_contig(value: str) -> str:
    value = value.removeprefix("chr")
    return "MT" if value == "M" else value


def key(chrom: str, start: str, end: str, ref: str, alt: str) -> tuple[str, ...]:
    return canonical_contig(chrom), start, end, ref, alt


def main() -> int:
    if len(sys.argv) != 4:
        print(
            "Usage: 13_04_merge_gnomad.py EXOMISER_TSV MULTIANNO_TSV OUTPUT_TSV",
            file=sys.stderr,
        )
        return 2

    exomiser_path, multianno_path, output_path = map(Path, sys.argv[1:])

    with multianno_path.open(newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if reader.fieldnames is None:
            raise ValueError(f"Missing header in {multianno_path}")
        frequency_columns = [
            column for column in reader.fieldnames if column.startswith("gnomad41_")
        ]
        if not frequency_columns:
            raise ValueError("No gnomAD v4.1 columns found in ANNOVAR output")

        annotations: dict[tuple[str, ...], dict[str, str]] = {}
        for row in reader:
            variant_key = key(row["Chr"], row["Start"], row["End"], row["Ref"], row["Alt"])
            annotations[variant_key] = {column: row[column] for column in frequency_columns}

    joined = 0
    observed = 0
    total = 0
    with exomiser_path.open(newline="") as source, output_path.open("w", newline="") as target:
        reader = csv.DictReader(source, delimiter="\t")
        if reader.fieldnames is None:
            raise ValueError(f"Missing header in {exomiser_path}")
        original_columns = list(reader.fieldnames)
        writer = csv.DictWriter(
            target,
            delimiter="\t",
            fieldnames=original_columns + frequency_columns,
            lineterminator="\n",
        )
        writer.writeheader()

        for row in reader:
            total += 1
            variant_key = key(row["CONTIG"], row["START"], row["END"], row["REF"], row["ALT"])
            annotation = annotations.get(variant_key)
            if annotation is None:
                row.update({column: "." for column in frequency_columns})
            else:
                joined += 1
                if any(value not in {"", "."} for value in annotation.values()):
                    observed += 1
                row.update(annotation)
            writer.writerow(row)

    print(f"Joined ANNOVAR output for {joined} of {total} Exomiser variant rows")
    print(f"Found non-missing gnomAD v4.1 frequency data for {observed} rows")
    print(f"Added {len(frequency_columns)} population-frequency columns")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
