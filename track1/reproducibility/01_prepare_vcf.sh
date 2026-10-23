#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

require_command "$BCFTOOLS"
require_file "$INPUT_VCF"
require_file "$REFERENCE_FASTA"
require_file "${REFERENCE_FASTA}.fai"

mkdir -p "$PREP_DIR"
OUTPUT_VCF="${PREP_DIR}/${VCF_SAMPLE_ID}.pass.canonical.norm.vcf.gz"
CHROM_MAP="${PREP_DIR}/rename_chromosomes.tsv"
CANONICAL_CONTIGS="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,X,Y,M"

mapfile -t samples < <("$BCFTOOLS" query -l "$INPUT_VCF")
if [[ ${#samples[@]} -ne 1 || "${samples[0]}" != "$VCF_SAMPLE_ID" ]]; then
    echo "ERROR: expected one sample named $VCF_SAMPLE_ID" >&2
    exit 1
fi

printf 'M\tMT\n' > "$CHROM_MAP"
"$BCFTOOLS" view --threads "$THREADS" --apply-filters PASS \
    --regions "$CANONICAL_CONTIGS" --output-type u "$INPUT_VCF" \
| "$BCFTOOLS" annotate --threads "$THREADS" --rename-chrs "$CHROM_MAP" --output-type u \
| "$BCFTOOLS" norm --threads "$THREADS" --fasta-ref "$REFERENCE_FASTA" \
    --multiallelics -any -d exact --output-type z --output "$OUTPUT_VCF"

"$BCFTOOLS" index --force --tbi "$OUTPUT_VCF"
echo "Prepared VCF: $OUTPUT_VCF"

