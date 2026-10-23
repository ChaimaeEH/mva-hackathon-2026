#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

mkdir -p "$CONFIG_DIR" "$EXOMISER_RESULTS_DIR"
INPUT="${PREP_DIR}/${VCF_SAMPLE_ID}.pass.canonical.norm.vcf.gz"
OUTPUT="${CONFIG_DIR}/${VCF_SAMPLE_ID}.exome-analysis.yml"
require_file "$INPUT"

cat > "$OUTPUT" <<EOF
---
analysis:
  genomeAssembly: hg38
  vcf: $INPUT
  proband: $VCF_SAMPLE_ID
  hpoIds:
    - 'HP:0002859'
    - 'HP:0000121'
    - 'HP:0004322'
    - 'HP:0001508'
    - 'HP:0003202'
    - 'HP:0001622'
    - 'HP:0001518'
    - 'HP:0200067'
  inheritanceModes:
    AUTOSOMAL_DOMINANT: 0.1
    AUTOSOMAL_RECESSIVE_HOM_ALT: 0.1
    AUTOSOMAL_RECESSIVE_COMP_HET: 2.0
    X_DOMINANT: 0.1
    X_RECESSIVE_HOM_ALT: 0.1
    X_RECESSIVE_COMP_HET: 2.0
    MITOCHONDRIAL: 0.2
  analysisMode: PASS_ONLY
  frequencySources:
    - UK10K
    - GNOMAD_E_AFR
    - GNOMAD_E_AMR
    - GNOMAD_E_EAS
    - GNOMAD_E_NFE
    - GNOMAD_E_SAS
    - GNOMAD_G_AFR
    - GNOMAD_G_AMR
    - GNOMAD_G_EAS
    - GNOMAD_G_NFE
    - GNOMAD_G_SAS
  pathogenicitySources: [REVEL, MVP, ALPHA_MISSENSE, SPLICE_AI]
  steps:
    - failedVariantFilter: {}
    - variantEffectFilter:
        remove:
          - FIVE_PRIME_UTR_EXON_VARIANT
          - FIVE_PRIME_UTR_INTRON_VARIANT
          - THREE_PRIME_UTR_EXON_VARIANT
          - THREE_PRIME_UTR_INTRON_VARIANT
          - NON_CODING_TRANSCRIPT_EXON_VARIANT
          - NON_CODING_TRANSCRIPT_INTRON_VARIANT
          - CODING_TRANSCRIPT_INTRON_VARIANT
          - UPSTREAM_GENE_VARIANT
          - DOWNSTREAM_GENE_VARIANT
          - INTERGENIC_VARIANT
          - REGULATORY_REGION_VARIANT
    - frequencyFilter: {maxFrequency: 2.0}
    - pathogenicityFilter: {keepNonPathogenic: true}
    - inheritanceFilter: {}
    - omimPrioritiser: {}
    - hiPhivePrioritiser: {runParams: 'human'}
outputOptions:
  outputDirectory: $EXOMISER_RESULTS_DIR
  outputContributingVariantsOnly: false
  numGenes: 0
  outputFileName: $OUTPUT_BASENAME
  outputFormats: [HTML, JSON, TSV_GENE, TSV_VARIANT, VCF]
EOF

echo "Created Exomiser analysis: $OUTPUT"

