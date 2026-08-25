# Track 1 Variant-Prediction Report — First Submission

## Objective

The goal of this first submission was to identify a small, biologically plausible set of causal variants for proband `WGS_EX2312012` using the supplied GRCh38 whole-genome VCF and the patient's Human Phenotype Ontology (HPO) terms. Because the challenge allows six submissions, this result was intentionally submitted as an initial, focused hypothesis rather than as an exhaustive candidate list.

## Why we chose this approach

The available inputs were already a variant call file and a structured phenotype description. A phenotype-driven variant-prioritization tool was therefore the most direct first analysis. Exomiser was selected because it can combine:

- similarity between the patient's HPO profile and known disease phenotypes;
- expected inheritance models;
- predicted molecular consequences and pathogenicity scores; and
- population allele frequencies.

This provides a reproducible way to reduce a genome-wide set of variants to a ranked list of genes and alleles that fit both the genotype and the phenotype.

## Input preparation

The supplied single-sample VCF was prepared for Exomiser by retaining `PASS` variants on canonical chromosomes, renaming the mitochondrial contig where necessary, splitting multiallelic records, removing exact duplicates, and normalizing alleles against the GRCh38 reference. This preprocessing was intended to produce consistently represented GRCh38 variants; it did not realign reads or recall variants.

The following HPO terms were used:

- `HP:0002859`
- `HP:0000121`
- `HP:0004322`
- `HP:0001508`
- `HP:0003202`
- `HP:0001622`
- `HP:0001518`
- `HP:0200067`

## Exomiser analysis

Exomiser CLI 14.1.0 was run in exome-analysis mode on the prepared GRCh38 VCF. All standard inheritance models were considered, but the compound-heterozygous recessive models were given greater weight because two damaging rare alleles in the same disease-relevant gene were of particular interest. The analysis used Exomiser population-frequency sources, REVEL, MVP, AlphaMissense and SpliceAI pathogenicity sources, an OMIM prioritizer, and the hiPHIVE phenotype prioritizer.

The initial Exomiser frequency filter allowed variants up to 2% so that plausible candidates would not be discarded prematurely. The ranked output was then annotated with gnomAD v4.1 exome population frequencies and assessed using population maximum allele frequency (`AF_grpmax`), rather than global allele frequency alone. The rarity categories used were:

- Tier 1: absent from gnomAD or population maximum AF below `1 × 10^-4`;
- Tier 2: AF from `1 × 10^-4` to below `1 × 10^-3`;
- Tier 3: AF from `1 × 10^-3` to below `1 × 10^-2`; and
- Tier 4: AF at or above `1 × 10^-2`.

## Principal result

Exomiser ranked **BUB1B** as the top gene under an autosomal-recessive model. Two heterozygous BUB1B variants contributed to this result:

| GRCh38 variant | Protein consequence | Exomiser variant score | gnomAD v4.1 exome AF | Population-max AF | Rarity tier |
|---|---|---:|---:|---:|---|
| `chr15:40209701 T>G` | `p.(Leu737*)` stop-gain | 1.0000 | 7.867 × 10^-5 | 9.982 × 10^-5 | Tier 1 |
| `chr15:40220612 T>G` | `p.(Asn1002Lys)` missense | 0.9229 | 6.841 × 10^-7 | 8.993 × 10^-7 | Tier 1 |

Under the recessive model, BUB1B received an Exomiser combined gene score of `0.9778` and rank 1. The pair was compelling because both variants are heterozygous, affect the same gene, are extremely rare by gnomAD v4.1 population-max frequency, and include a predicted loss-of-function stop-gain allele. In addition, BUB1B is a strong biological candidate for a phenotype involving mosaic variegated aneuploidy.

## First-submission decision

For the first of the six allowed attempts, we chose to test the clearest hypothesis produced by the phenotype- and inheritance-aware analysis. The two BUB1B alleles were submitted together as a single proposed compound-heterozygous pair with:

- `epcr = 1`;
- `finding_type = primary`; and
- no additional candidates that could dilute the initial ranked prediction.

This EPCR expresses the pair's position relative to the candidates in this submission; it should not be interpreted as a formally calibrated 100% probability of causality.

## Important limitation and next steps

The two variants are candidate compound heterozygotes, but a recessive compound-heterozygous mechanism requires them to occur **in trans**. Their phase should therefore be confirmed using parental genotypes or sufficiently informative read-backed phasing. The first submission tests the strongest computational hypothesis while that validation and broader review of structural variants, copy-number variants, mosaic calls, non-coding variants, and alternative genes can continue for later submissions.

## Reproducibility

- Exomiser configuration: `outputs/13_exomiser/config/WGS_EX2312012.exome-analysis.yml`
- Ranked and annotated results: `outputs/13_exomiser/clinical_annotations/WGS_EX2312012_exomiser.variants.annotated.constraint411.tsv`
- Submission-generation script: `scripts/create_track1_BUB1B_submission.sh`
- First prediction file: `submissions/elhoujja_bub1b_compound_het.tsv`
