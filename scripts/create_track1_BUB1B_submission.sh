#!/usr/bin/env bash

set -euo pipefail

PROJECT="/work/gr-fe/share/mva-challenge"
VCF="/work/gr-fe/databases/mva-challenge-data/WGS_EX2312012_HGWCNDSX7.vcf.gz"
BCFTOOLS="/work/gr-fe/elhoujja/tools/bcftools/bin/bcftools"
# The challenge submission identifier differs from the sample name in the VCF.
PROBAND_ID="PROBAND01"
TEAM_NAME="${1:-elhoujja}"
OUTPUT_DIR="${PROJECT}/submissions"
OUTPUT_FILE="${OUTPUT_DIR}/${TEAM_NAME}_bub1b_compound_het.tsv"

[[ "$TEAM_NAME" =~ ^[A-Za-z0-9._-]+$ ]] || {
    echo "ERROR: team name may contain only letters, numbers, dots, underscores, and hyphens" >&2
    exit 1
}

mkdir -p "$OUTPUT_DIR"

[[ -r "$VCF" ]] || { echo "ERROR: VCF is not readable: $VCF" >&2; exit 1; }
[[ -x "$BCFTOOLS" ]] || { echo "ERROR: bcftools is unavailable: $BCFTOOLS" >&2; exit 1; }

validate_variant() {
    local position="$1"
    local ref="$2"
    local alt="$3"
    local expected="15:${position}:${ref}:${alt}"
    local observed

    observed=$("$BCFTOOLS" query \
        --regions "15:${position}-${position}" \
        --include "REF='${ref}' && ALT='${alt}' && GT='het'" \
        --format '%CHROM:%POS:%REF:%ALT\n' \
        "$VCF")

    if [[ "$observed" != "$expected" ]]; then
        echo "ERROR: expected heterozygous variant ${expected}; observed: ${observed:-none}" >&2
        exit 1
    fi
}

validate_variant 40209701 T G
validate_variant 40220612 T G

printf '%s\n' \
    $'proband_id\tchrom_1\tpos_1\tref_1\talt_1\tchrom_2\tpos_2\tref_2\talt_2\tepcr\tfinding_type\tnotes' \
    > "$OUTPUT_FILE"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$PROBAND_ID" chr15 40209701 T G chr15 40220612 T G 1 primary \
    'Top-ranked BUB1B recessive pair: p.Leu737* stop-gain plus p.Asn1002Lys missense; both heterozygous and extremely rare. Read-backed cis/trans phase is being evaluated.' \
    >> "$OUTPUT_FILE"

rows=$(awk 'END {print NR-1}' "$OUTPUT_FILE")
columns=$(awk -F'\t' 'NR==1 {print NF}' "$OUTPUT_FILE")
if [[ "$rows" -ne 1 || "$columns" -ne 12 ]]; then
    echo "ERROR: invalid submission dimensions: ${rows} data rows, ${columns} columns" >&2
    exit 1
fi

echo "Created Track 1 submission: $OUTPUT_FILE"
echo "Candidate rows: $rows"
