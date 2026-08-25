#!/usr/bin/env bash
#SBATCH --job-name=mva_gnomad41
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --time=02:00:00
#SBATCH --output=/work/gr-fe/share/mva-challenge/logs/13_03_gnomad41_%j.out
#SBATCH --error=/work/gr-fe/share/mva-challenge/logs/13_03_gnomad41_%j.err

set -euo pipefail

PROJECT="/work/gr-fe/share/mva-challenge"
ANNOVAR="/work/gr-fe/elhoujja/tools/annovar"
HUMANDB="${ANNOVAR}/humandb_hg38"
INPUT_TSV="${PROJECT}/outputs/13_exomiser/results/WGS_EX2312012_exomiser.variants.tsv"
OUTPUT_DIR="${PROJECT}/outputs/13_exomiser/gnomad41"
AVINPUT="${OUTPUT_DIR}/WGS_EX2312012_exomiser.avinput"
PREFIX="${OUTPUT_DIR}/WGS_EX2312012_exomiser_gnomad41"
MULTIANNO="${PREFIX}.hg38_multianno.txt"
FINAL_TSV="${OUTPUT_DIR}/WGS_EX2312012_exomiser.variants.gnomad41.tsv"

mkdir -p "$OUTPUT_DIR" "${PROJECT}/logs"

for file in \
    "$INPUT_TSV" \
    "${ANNOVAR}/table_annovar.pl" \
    "${HUMANDB}/hg38_gnomad41_exome.txt" \
    "${HUMANDB}/hg38_gnomad41_exome.txt.idx" \
    "${PROJECT}/scripts/13_04_merge_gnomad.py"; do
    if [[ ! -r "$file" ]]; then
        echo "ERROR: required file is not readable: $file" >&2
        exit 1
    fi
done

# ANNOVAR input columns are chromosome, start, end, reference, alternate.
# Exomiser's leading # on RANK is handled by selecting columns by position.
awk 'BEGIN {FS=OFS="\t"} NR > 1 {print $15, $16, $17, $18, $19}' \
    "$INPUT_TSV" > "$AVINPUT"

if [[ ! -s "$AVINPUT" ]]; then
    echo "ERROR: no Exomiser variants were converted to ANNOVAR input" >&2
    exit 1
fi

perl "${ANNOVAR}/table_annovar.pl" \
    "$AVINPUT" \
    "$HUMANDB" \
    --buildver hg38 \
    --outfile "$PREFIX" \
    --remove \
    --protocol gnomad41_exome \
    --operation f \
    --nastring . \
    --thread 4

python3 "${PROJECT}/scripts/13_04_merge_gnomad.py" \
    "$INPUT_TSV" \
    "$MULTIANNO" \
    "$FINAL_TSV"

echo "gnomAD v4.1 population-frequency annotation completed."
echo "Output: $FINAL_TSV"
