#!/usr/bin/env bash
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)

"$HERE/01_prepare_vcf.sh"
"$HERE/02_create_exomiser_config.sh"
"$HERE/03_run_exomiser.sh"
"$HERE/04_annotate_variants.sh"
"$HERE/05_add_constraint.sh"

source "$HERE/lib/common.sh"
"$PYTHON" "$HERE/06_add_frequency_tiers.py" \
    "${FINAL_DIR}/${OUTPUT_BASENAME}.annotated.constraint.tsv" \
    "${FINAL_DIR}/${OUTPUT_BASENAME}.annotated.constraint.tiered.tsv"

"$HERE/07_create_submission.sh"

