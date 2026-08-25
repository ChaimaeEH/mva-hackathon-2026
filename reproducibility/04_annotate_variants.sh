#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

require_command "$PERL"
require_command "$PYTHON"
INPUT="${EXOMISER_RESULTS_DIR}/${OUTPUT_BASENAME}.variants.tsv"
TABLE_ANNOVAR="${ANNOVAR_DIR}/table_annovar.pl"
require_file "$INPUT"
require_file "$TABLE_ANNOVAR"
mkdir -p "$ANNOTATION_DIR"

AVINPUT="${ANNOTATION_DIR}/${OUTPUT_BASENAME}.avinput"
PREFIX="${ANNOTATION_DIR}/${OUTPUT_BASENAME}"
MULTIANNO="${PREFIX}.hg38_multianno.txt"
OUTPUT="${ANNOTATION_DIR}/${OUTPUT_BASENAME}.annotated.tsv"

awk 'BEGIN {FS=OFS="\t"} NR > 1 {print $15,$16,$17,$18,$19}' "$INPUT" > "$AVINPUT"
"$PERL" "$TABLE_ANNOVAR" "$AVINPUT" "$ANNOVAR_DB_DIR" \
    --buildver hg38 --outfile "$PREFIX" --remove \
    --protocol "refGene,ensGene,dbnsfp47a,avsnp151,${CLINVAR_PROTOCOL},dbscsnv11,${GNOMAD_PROTOCOL}" \
    --operation g,g,f,f,f,f,f --nastring . --thread "$THREADS" --polish

"$PYTHON" "${WORKFLOW_DIR}/lib/merge_annovar.py" "$INPUT" "$MULTIANNO" "$OUTPUT"
echo "Annotated table: $OUTPUT"

