#!/usr/bin/env python3
"""Merge ANNOVAR annotations onto the ranked Exomiser table by normalized allele."""

from __future__ import annotations

import csv
import sys
from pathlib import Path


CORE = {"Chr", "Start", "End", "Ref", "Alt"}


def variant_key(chrom: str, start: str, end: str, ref: str, alt: str) -> tuple[str, ...]:
    chrom = chrom.removeprefix("chr")
    if chrom == "M":
        chrom = "MT"
    return chrom, start, end, ref, alt


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: 13_06_merge_annotations.py BASE_TSV MULTIANNO_TSV OUTPUT_TSV", file=sys.stderr)
        return 2

    base_path, annotation_path, output_path = map(Path, sys.argv[1:])
    with annotation_path.open(newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if not reader.fieldnames:
            raise ValueError(f"Missing header: {annotation_path}")
        annotation_columns = [
            name for name in reader.fieldnames
            if name not in CORE and not name.startswith("Otherinfo")
        ]
        annotations = {
            variant_key(row["Chr"], row["Start"], row["End"], row["Ref"], row["Alt"]): {
                name: row[name] for name in annotation_columns
            }
            for row in reader
        }

    total = matched = 0
    with base_path.open(newline="") as source, output_path.open("w", newline="") as target:
        reader = csv.DictReader(source, delimiter="\t")
        if not reader.fieldnames:
            raise ValueError(f"Missing header: {base_path}")
        base_columns = list(reader.fieldnames)
        new_columns = [name for name in annotation_columns if name not in base_columns]
        writer = csv.DictWriter(
            target, delimiter="\t", fieldnames=base_columns + new_columns, lineterminator="\n"
        )
        writer.writeheader()
        for row in reader:
            total += 1
            key = variant_key(row["CONTIG"], row["START"], row["END"], row["REF"], row["ALT"])
            values = annotations.get(key)
            if values:
                matched += 1
                row.update({name: values[name] for name in new_columns})
            else:
                row.update({name: "." for name in new_columns})
            writer.writerow(row)

    print(f"Merged annotations for {matched} of {total} rows; added {len(new_columns)} columns")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
