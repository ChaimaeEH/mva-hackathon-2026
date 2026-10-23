#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

require_command "$BCFTOOLS"
require_file "$INPUT_VCF"
mkdir -p "$SUBMISSION_DIR"
OUTPUT="${SUBMISSION_DIR}/model1_matcha_hpo_variants_top.csv"

validate() {
    local pos=$1 ref=$2 alt=$3
    local found
    found=$("$BCFTOOLS" query --regions "15:${pos}-${pos}" \
        --include "REF='${ref}' && ALT='${alt}' && GT='het'" \
        --format '%CHROM:%POS:%REF:%ALT\n' "$INPUT_VCF")
    [[ "$found" == "15:${pos}:${ref}:${alt}" ]] || {
        echo "ERROR: expected heterozygous variant 15:${pos}:${ref}:${alt}" >&2
        exit 1
    }
}

validate 40209701 T G
validate 40220612 T G

printf '%s\n' \
    'proband_id,chrom_1,pos_1,ref_1,alt_1,chrom_2,pos_2,ref_2,alt_2,epcr,finding_type,notes' \
    "${CHALLENGE_PROBAND_ID},chr15,40209701,T,G,chr15,40220612,T,G,1,primary,Top-ranked BUB1B recessive pair: p.Leu737* stop-gain plus p.Asn1002Lys missense; both heterozygous and extremely rare. Phase requires confirmation." \
    > "$OUTPUT"

echo "Challenge submission: $OUTPUT"

