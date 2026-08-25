#!/usr/bin/env bash
#SBATCH --job-name=mva_constraint411
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=/work/gr-fe/share/mva-challenge/logs/13_07_constraint_%j.out
#SBATCH --error=/work/gr-fe/share/mva-challenge/logs/13_07_constraint_%j.err

set -euo pipefail

PROJECT="/work/gr-fe/share/mva-challenge"
RESOURCE_DIR="${PROJECT}/resources/gnomad"
INPUT_TSV="${PROJECT}/outputs/13_exomiser/clinical_annotations/WGS_EX2312012_exomiser.variants.annotated.tsv"
CONSTRAINT_BGZ="${RESOURCE_DIR}/gnomad.v4.1.1.constraint_metrics.tsv.bgz"
OUTPUT_TSV="${PROJECT}/outputs/13_exomiser/clinical_annotations/WGS_EX2312012_exomiser.variants.annotated.constraint411.tsv"
URL="https://storage.googleapis.com/gcp-public-data--gnomad/release/4.1.1/constraint/gnomad.v4.1.1.constraint_metrics.tsv.bgz"

mkdir -p "$RESOURCE_DIR" "${PROJECT}/logs"

if [[ ! -s "$CONSTRAINT_BGZ" ]]; then
    echo "Downloading official gnomAD v4.1.1 constraint metrics (about 575 MB)..."
    curl --fail --location --retry 3 --continue-at - --output "$CONSTRAINT_BGZ" "$URL"
fi

gzip -t "$CONSTRAINT_BGZ"
python3 "${PROJECT}/scripts/13_08_merge_constraint.py" \
    "$INPUT_TSV" "$CONSTRAINT_BGZ" "$OUTPUT_TSV"

echo "Added gnomAD v4.1.1 constraint metrics: $OUTPUT_TSV"
