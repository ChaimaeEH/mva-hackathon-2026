# Reproducible MVA Track 1 workflow

This directory contains the portable version of the analysis used for the first MVA Hackathon 2026 Track 1 submission. It starts from the controlled GRCh38 single-sample VCF and the supplied HPO terms, runs phenotype-driven prioritization with Exomiser, adds current population and clinical annotations, and creates the challenge prediction CSV.

The controlled VCF, reference genome, software databases, intermediate results, and machine-specific paths are deliberately not included. Nothing in this directory is required to live at a particular filesystem location.

## Analysis outline

1. Normalize the supplied VCF and retain canonical, `PASS` variants.
2. Create an Exomiser exome-analysis configuration using the eight supplied HPO terms.
3. Run Exomiser with increased weight for recessive compound-heterozygous models.
4. Add gnomAD v4.1 population frequencies, ClinVar, dbNSFP, transcript and splice annotations with ANNOVAR.
5. Add gnomAD v4.1.1 gene-constraint metrics.
6. Classify variants by gnomAD population-maximum frequency.
7. Validate and write the selected BUB1B compound-heterozygous submission.

## Requirements

- Bash 4 or newer
- Python 3.9 or newer
- Java compatible with Exomiser 14.1.0
- bcftools
- Exomiser CLI 14.1.0 and its hg38/phenotype databases
- ANNOVAR with hg38 `refGene`, `ensGene`, `dbnsfp47a`, `avsnp151`, ClinVar, `dbscsnv11`, and `gnomad41_exome` databases
- GRCh38 FASTA matching the VCF, plus its `.fai` index
- gnomAD v4.1.1 constraint metrics

Software and annotation databases must be obtained under their respective licenses. ANNOVAR is not redistributed by this repository.

## Configuration

Copy the example and edit only the local copy:

```bash
cd reproducibility
cp config.example.env config.env
editor config.env
```

Set the input VCF, GRCh38 reference, Exomiser, ANNOVAR and constraint-file paths. `config.env` is excluded by `.gitignore`, preventing local infrastructure paths from being published.

By default, intermediates are written to `work/` at repository root and the final CSV to `submissions/`. Both the controlled input and `work/` must remain outside version control.

## Scripts

| Step | Script | Purpose | Main output |
|---:|---|---|---|
| 01 | `01_prepare_vcf.sh` | Verifies the single VCF sample, keeps canonical `PASS` records, renames mitochondrial `M` to `MT`, splits multiallelic records, normalizes against GRCh38, removes exact duplicates, and indexes the result. | `work/01_prepared_vcf/*.vcf.gz` |
| 02 | `02_create_exomiser_config.sh` | Writes the Exomiser YAML containing the HPO terms, inheritance weights, filters, predictors and output formats used in the analysis. | `work/02_exomiser_config/*.yml` |
| 03 | `03_run_exomiser.sh` | Runs Exomiser from its installation directory so its configured databases are found. | `work/03_exomiser_results/` |
| 04 | `04_annotate_variants.sh` | Converts ranked Exomiser variants to ANNOVAR input, adds transcript, dbNSFP, dbSNP, ClinVar, splice and gnomAD v4.1 frequency annotations, then joins them by normalized allele. | `work/04_annotations/*.annotated.tsv` |
| 05 | `05_add_constraint.sh` | Selects MANE, then canonical, gnomAD v4.1.1 transcripts per gene and adds loss-of-function, missense and synonymous constraint metrics. | `work/05_final_table/*.constraint.tsv` |
| 06 | `06_add_frequency_tiers.py` | Adds a reproducible rarity tier from `gnomad41_exome_AF_grpmax`: Tier 1 `<10^-4` or absent, Tier 2 `<10^-3`, Tier 3 `<10^-2`, and Tier 4 otherwise. | `work/05_final_table/*.tiered.tsv` |
| 07 | `07_create_submission.sh` | Confirms both selected BUB1B alleles are heterozygous in the source VCF and writes one compound-heterozygous challenge row using `PROBAND01`. | `submissions/model1_matcha_hpo_variants_top.csv` |

The `lib/` directory contains table-joining helpers and shared configuration logic. These are implementation details called by the numbered steps rather than independent analysis stages.

## Running the workflow

Run each stage individually for easier inspection:

```bash
./01_prepare_vcf.sh
./02_create_exomiser_config.sh
./03_run_exomiser.sh
./04_annotate_variants.sh
./05_add_constraint.sh
python3 ./06_add_frequency_tiers.py \
  ../work/05_final_table/WGS_EX2312012_exomiser.annotated.constraint.tsv \
  ../work/05_final_table/WGS_EX2312012_exomiser.annotated.constraint.tiered.tsv
./07_create_submission.sh
```

After validating `config.env`, the same sequence can be launched with:

```bash
./run_all.sh
```

These scripts contain no scheduler directives. On a cluster, invoke individual steps from the site's scheduler and request resources appropriate for the local installation. Exomiser and ANNOVAR are the most resource-intensive stages.

## Parameters and rationale

The supplied phenotype terms are:

```text
HP:0002859  HP:0000121  HP:0004322  HP:0001508
HP:0003202  HP:0001622  HP:0001518  HP:0200067
```

Exomiser's autosomal- and X-linked compound-heterozygous models were weighted `2.0`; other nuclear modes were retained at `0.1` and mitochondrial inheritance at `0.2`. This preserved alternative models while emphasizing the recessive hypothesis. The initial maximum-frequency filter was 2%, deliberately permissive to avoid prematurely removing plausible alleles. Final rarity assessment used gnomAD v4.1 population maximum frequency rather than global AF.

The top recessive result contained two heterozygous BUB1B variants: GRCh38 `chr15:40209701 T>G`, `p.(Leu737*)`, and `chr15:40220612 T>G`, `p.(Asn1002Lys)`. They were submitted as one proposed compound-heterozygous pair. The stop-gain is ClinVar Pathogenic/Likely pathogenic; the missense allele was classified as a VUS by Exomiser's ACMG module and had no matching ClinVar record in the annotation reviewed. In-trans phase and the functional effect of the missense allele remain validation requirements.

## Reproducibility and privacy notes

- Coordinates and reference alleles are GRCh38.
- Annotation releases are configurable because database filenames change over time; record the exact values used in `config.env` in any methods report.
- The public code does not contain raw reads, a VCF, BAM/CRAM files, complete patient-level output tables, credentials, or cluster paths.
- The final prediction CSV is intentionally public challenge output. Review the challenge data-use terms before publishing any additional patient-derived results.
- Computational prioritization is research evidence, not a clinical diagnosis.

