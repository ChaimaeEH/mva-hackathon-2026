#!/usr/bin/env bash
#SBATCH --job-name=mva_clinical_anno
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --output=/work/gr-fe/share/mva-challenge/logs/13_05_clinical_%j.out
#SBATCH --error=/work/gr-fe/share/mva-challenge/logs/13_05_clinical_%j.err

set -euo pipefail

PROJECT="/work/gr-fe/share/mva-challenge"
ANNOVAR="/work/gr-fe/elhoujja/tools/annovar"
HUMANDB="${ANNOVAR}/humandb_hg38"
EXOMISER_TSV="${PROJECT}/outputs/13_exomiser/results/WGS_EX2312012_exomiser.variants.tsv"
GNOMAD_TSV="${PROJECT}/outputs/13_exomiser/gnomad41/WGS_EX2312012_exomiser.variants.gnomad41.tsv"
OUTPUT_DIR="${PROJECT}/outputs/13_exomiser/clinical_annotations"
AVINPUT="${OUTPUT_DIR}/WGS_EX2312012_exomiser.avinput"
PREFIX="${OUTPUT_DIR}/WGS_EX2312012_exomiser_clinical"
MULTIANNO="${PREFIX}.hg38_multianno.txt"
FINAL_TSV="${OUTPUT_DIR}/WGS_EX2312012_exomiser.variants.annotated.tsv"

mkdir -p "$OUTPUT_DIR" "${PROJECT}/logs"

if [[ -s "$GNOMAD_TSV" ]]; then
    BASE_TSV="$GNOMAD_TSV"
else
    BASE_TSV="$EXOMISER_TSV"
fi

for file in "$EXOMISER_TSV" "${ANNOVAR}/table_annovar.pl"; do
    [[ -r "$file" ]] || { echo "ERROR: unreadable file: $file" >&2; exit 1; }
done

awk 'BEGIN {FS=OFS="\t"} NR > 1 {print $15, $16, $17, $18, $19}' \
    "$EXOMISER_TSV" > "$AVINPUT"

perl "${ANNOVAR}/table_annovar.pl" \
    "$AVINPUT" "$HUMANDB" \
    --buildver hg38 \
    --outfile "$PREFIX" \
    --remove \
    --protocol refGene,ensGene,dbnsfp47a,avsnp151,clinvar_20250721,dbscsnv11 \
    --operation g,g,f,f,f,f \
    --nastring . \
    --thread 4 \
    --polish

python3 "${PROJECT}/scripts/13_06_merge_annotations.py" \
    "$BASE_TSV" "$MULTIANNO" "$FINAL_TSV"

echo "Clinical annotation completed: $FINAL_TSV"
