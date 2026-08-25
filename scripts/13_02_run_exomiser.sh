#!/usr/bin/env bash
#SBATCH --job-name=mva_exomiser
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=08:00:00
#SBATCH --output=/work/gr-fe/share/mva-challenge/logs/13_02_exomiser_%j.out
#SBATCH --error=/work/gr-fe/share/mva-challenge/logs/13_02_exomiser_%j.err

set -euo pipefail

PROJECT="/work/gr-fe/share/mva-challenge"
EXOMISER_DIR="/work/gr-fe/elhoujja/tools/exomiser-cli-14.1.0"
EXOMISER_JAR="${EXOMISER_DIR}/exomiser-cli-14.1.0.jar"
INPUT_VCF="${PROJECT}/outputs/13_exomiser/input/WGS_EX2312012_HGWCNDSX7.pass.canonical.norm.vcf.gz"
YAML_FILE="${PROJECT}/outputs/13_exomiser/config/WGS_EX2312012.exome-analysis.yml"
RESULTS_DIR="${PROJECT}/outputs/13_exomiser/results"

mkdir -p "$RESULTS_DIR" "${PROJECT}/logs"

for file in "$EXOMISER_JAR" "$INPUT_VCF" "${INPUT_VCF}.tbi" "$YAML_FILE"; do
    if [[ ! -r "$file" ]]; then
        echo "ERROR: required file is not readable: $file" >&2
        exit 1
    fi
done

echo "Starting Exomiser at $(date --iso-8601=seconds)"
echo "Analysis: $YAML_FILE"
echo "Results:  $RESULTS_DIR"

# Run from EXOMISER_DIR so its application.properties and configured hg38/phenotype
# databases are discovered by Exomiser 14.1.0.
cd "$EXOMISER_DIR"
java -Xmx24g -XX:+UseG1GC -jar "$EXOMISER_JAR" \
    --analysis "$YAML_FILE" \
    --output-directory "$RESULTS_DIR"

echo "Exomiser completed at $(date --iso-8601=seconds)"
