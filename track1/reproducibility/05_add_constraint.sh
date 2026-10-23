#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

require_command "$PYTHON"
INPUT="${ANNOTATION_DIR}/${OUTPUT_BASENAME}.annotated.tsv"
OUTPUT="${FINAL_DIR}/${OUTPUT_BASENAME}.annotated.constraint.tsv"
require_file "$INPUT"
require_file "$GNOMAD_CONSTRAINT_FILE"
mkdir -p "$FINAL_DIR"

"$PYTHON" "${WORKFLOW_DIR}/lib/merge_constraint.py" "$INPUT" "$GNOMAD_CONSTRAINT_FILE" "$OUTPUT"
echo "Constraint-annotated table: $OUTPUT"

