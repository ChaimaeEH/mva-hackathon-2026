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

| Feature | `p.(Leu737*)` | `p.(Asn1002Lys)` |
|---|---|---|
| GRCh38 variant | `chr15:40209701 T>G` | `chr15:40220612 T>G` |
| Genotype | Heterozygous (`0/1`) | Heterozygous (`0/1`) |
| Molecular consequence | Stop-gain; predicted loss of function | Missense substitution |
| Exomiser variant score | 1.0000 | 0.9229 |
| Exomiser ACMG assessment | Pathogenic | Uncertain significance (VUS) |
| ClinVar status | Pathogenic/Likely pathogenic; Variation ID 533901; two-star review status | No matching ClinVar record in the annotation reviewed |
| gnomAD v4.1 exome AF | 7.867 × 10^-5 | 6.841 × 10^-7 |
| gnomAD v4.1 population-max AF | 9.982 × 10^-5 | 8.993 × 10^-7 |
| Rarity tier | Tier 1 | Tier 1 |
| Selected prediction evidence | Established loss-of-function mechanism and clinical classification | Extreme rarity plus supportive computational evidence |

Under the recessive model, BUB1B received an Exomiser combined gene score of `0.9778` and rank 1. The pair was compelling because both variants are heterozygous, affect the same gene, are extremely rare by gnomAD v4.1 population-max frequency, and include a predicted loss-of-function stop-gain allele. In addition, BUB1B is a strong biological candidate for a phenotype involving mosaic variegated aneuploidy.

## ClinVar and pathogenicity review

We reviewed the candidates against ClinVar and the additional clinical/pathogenicity annotations in the pipeline. The `p.(Leu737*)` variant has a current ClinVar aggregate germline classification of **Pathogenic/Likely pathogenic**, based on two submissions with criteria provided and no conflicts. The condition-specific ClinVar record for mosaic variegated aneuploidy syndrome 1 is Pathogenic. This is consistent with the expected effect of a premature stop codon in a gene for which loss of function is an established disease mechanism. The record is [ClinVar Variation ID 533901](https://www.ncbi.nlm.nih.gov/clinvar/variation/533901/).

The `p.(Asn1002Lys)` variant was assessed as **uncertain significance (VUS)** by Exomiser's ACMG module (`PM2_Supporting`, `PP4_Moderate`, `BP1`). A matching ClinVar record was not present in the annotation used for this analysis, and a direct ClinVar search did not identify one at the time of report preparation. It is therefore more precise to describe this allele as an **Exomiser-classified VUS**, rather than a ClinVar-classified VUS. Its evidence includes an AlphaMissense score of `0.9229`, MVP score of approximately `0.852`, ClinPred score of approximately `0.989` with a damaging prediction, and extreme rarity. REVEL was more moderate at `0.472`, illustrating that computational predictors do not agree completely.

These classifications are complementary rather than equivalent. The pathogenic stop-gain allele provides strong evidence for one affected BUB1B copy. The missense VUS is a credible candidate for the second affected copy because of its rarity, phenotype/gene match, and several damaging predictions, but those observations do not independently establish pathogenicity. Under a recessive model, the pair becomes compelling only if the missense allele truly impairs BUB1B function and the two alleles are in trans.

One further caveat is that the ClinVar submitter comment for `p.(Leu737*)` notes that population-frequency metrics at this position may be affected by poor gnomAD data quality. We therefore used frequency as supporting evidence, not as the sole basis for pathogenicity, and retained the stronger consequence, clinical-classification, inheritance, and phenotype evidence.

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
