#!/usr/bin/env python3
"""Merge ANNOVAR columns into an Exomiser variant table by normalized allele."""

import csv
import sys
from pathlib import Path

CORE = {"Chr", "Start", "End", "Ref", "Alt"}


def key(chrom: str, start: str, end: str, ref: str, alt: str):
    chrom = chrom.removeprefix("chr")
    return ("MT" if chrom == "M" else chrom), start, end, ref, alt


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: merge_annovar.py EXOMISER.tsv MULTIANNO.txt OUTPUT.tsv", file=sys.stderr)
        return 2
    base_path, anno_path, output_path = map(Path, sys.argv[1:])
    with anno_path.open(newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if not reader.fieldnames:
            raise ValueError("ANNOVAR table has no header")
        columns = [c for c in reader.fieldnames if c not in CORE and not c.startswith("Otherinfo")]
        annotations = {
            key(r["Chr"], r["Start"], r["End"], r["Ref"], r["Alt"]): {c: r[c] for c in columns}
            for r in reader
        }
    with base_path.open(newline="") as source, output_path.open("w", newline="") as target:
        reader = csv.DictReader(source, delimiter="\t")
        if not reader.fieldnames:
            raise ValueError("Exomiser table has no header")
        new_columns = [c for c in columns if c not in reader.fieldnames]
        writer = csv.DictWriter(target, delimiter="\t", fieldnames=list(reader.fieldnames) + new_columns, lineterminator="\n")
        writer.writeheader()
        for row in reader:
            values = annotations.get(key(row["CONTIG"], row["START"], row["END"], row["REF"], row["ALT"]), {})
            row.update({c: values.get(c, ".") for c in new_columns})
            writer.writerow(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

