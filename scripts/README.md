# MVA challenge scripts

## Exomiser exome-mode smoke test

This workflow uses the supplied single-sample GRCh38 VCF as the authoritative
starting point. It does not rerun FASTQ alignment, BQSR, or variant calling.

The preparation job:

1. validates the sample name;
2. retains variants whose site-level filter is `PASS`;
3. retains canonical chromosomes;
4. renames mitochondrial contig `M` to the Ensembl reference name `MT`;
5. splits multiallelic records, normalizes alleles, and removes exact duplicates;
6. writes a new bgzip-compressed VCF and tabix index without modifying the input.

The Exomiser analysis uses hg38, Exomiser 14.1.0, its installed 2508 databases,
and these phenotype terms:

- HP:0002859
- HP:0000121
- HP:0004322
- HP:0001508
- HP:0003202
- HP:0001622
- HP:0001518
- HP:0200067

Submit both dependent Slurm jobs with:

```bash
cd /work/gr-fe/share/mva-challenge
./scripts/13_submit_exomiser_test.sh
```

Outputs are written below `outputs/13_exomiser/` and Slurm logs below `logs/`.
The original VCF and HCC scripts remain unchanged.

## Add gnomAD v4.1 population frequencies

After Exomiser completes, submit:

```bash
sbatch /work/gr-fe/share/mva-challenge/scripts/13_03_annotate_gnomad41.sh
```

This uses the locally indexed ANNOVAR gnomAD v4.1 exome database and appends
overall, raw, sex-specific, ancestry-specific, group-maximum, FAF95, and FAF99
fields to the ranked Exomiser variant table. It writes a new table under
`outputs/13_exomiser/gnomad41/` and leaves all Exomiser outputs unchanged.

## Add local clinical and functional annotations

After the gnomAD stage, submit:

```bash
sbatch /work/gr-fe/share/mva-challenge/scripts/13_05_annotate_clinical.sh
```

This adds RefGene, Ensembl, dbSNP151, dbNSFP 4.7a, dbscSNV 1.1, and the locally
available ClinVar 2025-07-21 snapshot. The consolidated table is written under
`outputs/13_exomiser/clinical_annotations/`.

## Add updated gnomAD v4.1.1 gene constraint

```bash
sbatch /work/gr-fe/share/mva-challenge/scripts/13_07_add_gnomad411_constraint.sh
```

The first run downloads the official ~575 MB constraint table, selects the MANE
Select transcript when available (otherwise canonical), and adds version-labelled
LOEUF, pLI, missense, synonymous, rank, percentile, and quality-flag fields.

## Add population-frequency tiers

```bash
python3 /work/gr-fe/share/mva-challenge/scripts/13_09_add_frequency_tier.py \
  /work/gr-fe/share/mva-challenge/outputs/13_exomiser/clinical_annotations/WGS_EX2312012_exomiser.variants.annotated.constraint411.tsv
```

The script classifies `gnomad41_exome_AF_grpmax` as Tier 1 when absent or below
`1e-4`, Tier 2 from `1e-4` to below `1e-3`, Tier 3 from `1e-3` to below `1e-2`,
and Tier 4 at or above `1e-2`.

## Generate a complete WGS BAM for IGV

The full-genome workflow aligns all four paired-end lanes against the complete
GRCh38 reference, preserves one read group per lane, fixes mate tags, coordinate
sorts, merges lanes, marks duplicates, indexes the BAM, and writes QC reports.
Large intermediates are kept on `/scratch/elhoujja` and removed after successful
validation.

Submit it with:

```bash
sbatch /work/gr-fe/share/mva-challenge/scripts/01_align_full_wgs_for_igv.sh
```

The final IGV files will be:

```text
outputs/01_full_wgs_bam/WGS_EX2312012.GRCh38.markdup.bam
outputs/01_full_wgs_bam/WGS_EX2312012.GRCh38.markdup.bam.bai
```

## Create the BUB1B Track 1 submission

Create a one-row compound-heterozygous prediction containing the two leading
BUB1B alleles with EPCR 1:

```bash
./scripts/create_track1_BUB1B_submission.sh YOUR_TEAM_NAME
```

The script verifies that both alleles are heterozygous in the supplied GRCh38
VCF and writes `submissions/YOUR_TEAM_NAME_bub1b_compound_het.tsv`.
