#!/usr/bin/env python3
"""Summarize read evidence and WhatsHap phase for the two BUB1B SNVs."""

from __future__ import annotations

import csv
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

import pysam


TARGETS = [(40209701, "T", "G"), (40220612, "T", "G")]


def phase_info(record: pysam.VariantRecord, sample: str) -> tuple[str, str, str]:
    call = record.samples[sample]
    gt = call.get("GT")
    phased = bool(call.phased)
    gt_text = ("|" if phased else "/").join("." if x is None else str(x) for x in gt)
    ps = str(call.get("PS", "."))
    if phased and gt in {(0, 1), (1, 0)}:
        hap = "H2" if gt == (0, 1) else "H1"
    else:
        hap = "."
    return gt_text, ps, hap


def main() -> int:
    if len(sys.argv) != 4:
        print("Usage: summarize_BUB1B_phasing.py PHASED.vcf.gz HAPLOTAGGED.bam OUTDIR", file=sys.stderr)
        return 2
    vcf_path, bam_path, out_dir = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    out_dir.mkdir(parents=True, exist_ok=True)

    vcf = pysam.VariantFile(str(vcf_path))
    sample = next(iter(vcf.header.samples))
    records = {record.pos: record for record in vcf.fetch("chr15", TARGETS[0][0] - 1, TARGETS[-1][0])}
    bam = pysam.AlignmentFile(str(bam_path), "rb")
    rows = []

    for pos, ref, alt in TARGETS:
        bases = Counter()
        strands = defaultdict(Counter)
        mapqs = defaultdict(list)
        baseqs = defaultdict(list)
        hp = defaultdict(Counter)
        for column in bam.pileup("chr15", pos - 1, pos, truncate=True, min_base_quality=20, min_mapping_quality=20):
            if column.reference_pos != pos - 1:
                continue
            for item in column.pileups:
                read = item.alignment
                if item.is_del or item.is_refskip or item.query_position is None:
                    continue
                if read.is_duplicate or read.is_secondary or read.is_supplementary or read.is_qcfail:
                    continue
                base = read.query_sequence[item.query_position].upper()
                bases[base] += 1
                strands[base]["reverse" if read.is_reverse else "forward"] += 1
                mapqs[base].append(read.mapping_quality)
                baseqs[base].append(read.query_qualities[item.query_position])
                hp[base][str(read.get_tag("HP")) if read.has_tag("HP") else "."] += 1

        record = records[pos]
        gt, ps, hap = phase_info(record, sample)
        ref_n, alt_n = bases[ref], bases[alt]
        dp = ref_n + alt_n
        rows.append({
            "Variant": f"chr15:{pos}:{ref}>{alt}", "GT": gt, "DP": dp,
            "AD_REF": ref_n, "AD_ALT": alt_n, "VAF": f"{alt_n / dp:.4f}" if dp else ".",
            "REF_FWD": strands[ref]["forward"], "REF_REV": strands[ref]["reverse"],
            "ALT_FWD": strands[alt]["forward"], "ALT_REV": strands[alt]["reverse"],
            "REF_MAPQ_MEDIAN": statistics.median(mapqs[ref]) if mapqs[ref] else ".",
            "ALT_MAPQ_MEDIAN": statistics.median(mapqs[alt]) if mapqs[alt] else ".",
            "REF_BASEQ_MEDIAN": statistics.median(baseqs[ref]) if baseqs[ref] else ".",
            "ALT_BASEQ_MEDIAN": statistics.median(baseqs[alt]) if baseqs[alt] else ".",
            "Phase_set": ps, "Haplotype": hap,
            "REF_HP_COUNTS": ",".join(f"{k}:{v}" for k, v in sorted(hp[ref].items())),
            "ALT_HP_COUNTS": ",".join(f"{k}:{v}" for k, v in sorted(hp[alt].items())),
        })

    with (out_dir / "target_read_and_phase_evidence.tsv").open("w", newline="") as handle:
        writer = csv.DictWriter(handle, delimiter="\t", fieldnames=list(rows[0]), lineterminator="\n")
        writer.writeheader(); writer.writerows(rows)

    same_block = rows[0]["Phase_set"] != "." and rows[0]["Phase_set"] == rows[1]["Phase_set"]
    if same_block and rows[0]["Haplotype"] != "." and rows[1]["Haplotype"] != ".":
        conclusion = "SUPPORTED IN CIS" if rows[0]["Haplotype"] == rows[1]["Haplotype"] else "SUPPORTED IN TRANS"
    else:
        conclusion = "PHASING UNRESOLVED"

    intermediates = []
    if same_block:
        for record in vcf.fetch("chr15", TARGETS[0][0], TARGETS[1][0] - 1):
            call = record.samples[sample]
            if call.phased and str(call.get("PS", ".")) == rows[0]["Phase_set"]:
                gt, ps, hap = phase_info(record, sample)
                intermediates.append([record.contig, record.pos, record.ref, ",".join(record.alts or []), gt, ps, hap])
    with (out_dir / "intermediate_phased_variants.tsv").open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(["CHROM", "POS", "REF", "ALT", "GT", "PS", "ALT_HAPLOTYPE"])
        writer.writerows(intermediates)

    with (out_dir / "final_summary.md").open("w") as handle:
        handle.write(f"# BUB1B read-backed phasing\n\n{conclusion}\n\n")
        handle.write(f"The target variants are {'in the same WhatsHap phase set' if same_block else 'not connected in one WhatsHap phase set'}. ")
        if same_block:
            handle.write(f"Their ALT alleles were assigned to {rows[0]['Haplotype']} and {rows[1]['Haplotype']}. ")
            handle.write("This is indirect read-backed haplotype-chain evidence across intermediate variants, not one read spanning 10.9 kb.\n")
        else:
            handle.write("Short-read evidence did not support a continuous phase chain between them.\n")
        handle.write("\nNo pedigree-based or statistical phasing was used.\n")
    print(conclusion)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
