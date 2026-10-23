#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib/common.sh"

require_command "$JAVA"
require_file "$EXOMISER_JAR"
ANALYSIS="${CONFIG_DIR}/${VCF_SAMPLE_ID}.exome-analysis.yml"
require_file "$ANALYSIS"
mkdir -p "$EXOMISER_RESULTS_DIR"

cd "$EXOMISER_DIR"
"$JAVA" "-Xmx${JAVA_MEMORY}" -XX:+UseG1GC -jar "$EXOMISER_JAR" \
    --analysis "$ANALYSIS" --output-directory "$EXOMISER_RESULTS_DIR"

echo "Exomiser results: $EXOMISER_RESULTS_DIR"

