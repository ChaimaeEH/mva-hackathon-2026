#!/usr/bin/env bash
#SBATCH --job-name=phase_BUB1B
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/work/gr-fe/elhoujja/mva-challenge/BUB1B_phasing/phase_BUB1B_%j.out
#SBATCH --error=/work/gr-fe/elhoujja/mva-challenge/BUB1B_phasing/phase_BUB1B_%j.err

set -euo pipefail

MODE="${1:-all}"
PROJECT="/work/gr-fe/elhoujja/mva-challenge"
DATA="/work/gr-fe/databases/mva-challenge-data"
OUT="${PROJECT}/BUB1B_phasing"
VCF="${DATA}/WGS_EX2312012_HGWCNDSX7.vcf.gz"
REFERENCE="/work/gr-fe/saadat/Reference_Genome/GRCH38_no_alt/GCA_000001405.15_GRCh38_no_alt_analysis_set.fa.gz"
BWA="/work/gr-fe/elhoujja/tools/bwa/bwa"
SAMTOOLS="/work/gr-fe/elhoujja/tools/samtools/samtools-1.23/bin/samtools"
BCFTOOLS="/work/gr-fe/elhoujja/tools/bcftools/bin/bcftools"
WHATSHAP="${WHATSHAP:-$(command -v whatshap || true)}"
THREADS="${SLURM_CPUS_PER_TASK:-24}"
SAMPLE="WGS_EX2312012"

# Full-reference alignment is retained only across this broad interval. Mapping
# remains genome-wide; this is not an invalid alignment against a local FASTA.
ALIGN_REGION="chr15:39900000-40400000"
VCF_REGION="15:39900000-40400000"
TARGET1=40209701
TARGET2=40220612

mkdir -p "$OUT" "$OUT/lane_bams" "$OUT/tmp"

inspect_vcf() {
    "$BCFTOOLS" view -H -r "15:${TARGET1}-${TARGET1}" "$VCF" > "$OUT/target_40209701.vcf_record.txt"
    "$BCFTOOLS" view -H -r "15:${TARGET2}-${TARGET2}" "$VCF" > "$OUT/target_40220612.vcf_record.txt"

    {
        printf 'Variant\tGT\tSeparator\tPS\tPGT\tPID\tGQ\tDP\tAD_REF\tAD_ALT\tVAF\n'
        "$BCFTOOLS" query -r "15:${TARGET1}-${TARGET2}" \
            -i "POS=${TARGET1} || POS=${TARGET2}" \
            -f '%CHROM:%POS:%REF:%ALT[\t%GT\t%PGT\t%PID\t%GQ\t%DP\t%AD]\n' "$VCF" \
        | awk -F'\t' 'BEGIN{OFS="\t"} {
              split($7, ad, ","); sep=($2 ~ /\|/ ? "|" : "/");
              dp=$6+0; vaf=(dp ? ad[2]/dp : ".");
              print $1,$2,sep,".",$3,$4,$5,dp,ad[1],ad[2],vaf
          }'
    } > "$OUT/vcf_target_summary.tsv"

    "$BCFTOOLS" query -r "15:40109701-40320612" -i 'GT="het"' \
        -f '%CHROM\t%POS\t%ID\t%REF\t%ALT[\t%GT\t%GQ\t%DP\t%AD\t%PGT\t%PID]\n' "$VCF" \
        > "$OUT/nearby_heterozygous_variants.tsv"

    {
        echo "VCF: $VCF"
        echo "Sample: $SAMPLE"
        echo "PS header present: no"
        echo "Conclusion from supplied VCF: PHASING UNRESOLVED"
        echo "Reason: both targets are unphased 0/1 and have no PGT/PID phase set."
    } > "$OUT/vcf_inspection.txt"
}

inspect_vcf
if [[ "$MODE" == "inspect" ]]; then
    echo "VCF inspection completed in $OUT"
    exit 0
fi

for required in "$VCF" "${VCF}.tbi" "$REFERENCE" "${REFERENCE}.bwt" "$BWA" "$SAMTOOLS" "$BCFTOOLS"; do
    [[ -r "$required" ]] || { echo "ERROR: missing required file: $required" >&2; exit 1; }
done
if [[ -z "$WHATSHAP" || ! -x "$WHATSHAP" ]]; then
    echo "ERROR: WhatsHap is required but not installed or not on PATH." >&2
    echo "Install/activate WhatsHap, or set WHATSHAP=/absolute/path/to/whatshap." >&2
    exit 2
fi

"$BWA" 2>&1 | head -n 3 > "$OUT/bwa_version.txt" || true
"$SAMTOOLS" --version | head -n 2 > "$OUT/samtools_version.txt"
"$BCFTOOLS" --version | head -n 2 > "$OUT/bcftools_version.txt"
"$WHATSHAP" --version > "$OUT/whatshap_version.txt"
printf '%s\n' "$REFERENCE" > "$OUT/reference_path.txt"
printf 'chr15\t39899999\t40400000\n' > "$OUT/retained_region.bed"

lane_bams=()
for lane in 001 002 003 004; do
    r1="${DATA}/${SAMPLE}_HGWCNDSX7_S16_L${lane}_R1_001.fastq.gz"
    r2="${DATA}/${SAMPLE}_HGWCNDSX7_S16_L${lane}_R2_001.fastq.gz"
    bam="${OUT}/lane_bams/${SAMPLE}.L${lane}.region.bam"
    [[ -r "$r1" && -r "$r2" ]] || { echo "ERROR: missing lane L${lane} FASTQs" >&2; exit 1; }
    rg="@RG\\tID:${SAMPLE}.L${lane}\\tSM:${SAMPLE}\\tLB:${SAMPLE}\\tPL:ILLUMINA\\tPU:HGWCNDSX7.L${lane}"
    "$BWA" mem -t "$THREADS" -R "$rg" "$REFERENCE" "$r1" "$r2" \
      | "$SAMTOOLS" view -@ 4 -bh -L "$OUT/retained_region.bed" - \
      | "$SAMTOOLS" sort -@ 4 -o "$bam" -
    "$SAMTOOLS" index -@ 4 "$bam"
    lane_bams+=("$bam")
done

merged="${OUT}/${SAMPLE}.BUB1B.region.merged.bam"
fixed="${OUT}/${SAMPLE}.BUB1B.region.fixmate.sorted.bam"
dedup="${OUT}/${SAMPLE}.BUB1B.region.markdup.bam"
"$SAMTOOLS" merge -@ 4 -f "$merged" "${lane_bams[@]}"
"$SAMTOOLS" collate -@ 4 -O "$merged" \
  | "$SAMTOOLS" fixmate -@ 4 -m - - \
  | "$SAMTOOLS" sort -@ 4 -o "$fixed" -
"$SAMTOOLS" markdup -@ 4 -s "$fixed" "$dedup" 2> "$OUT/markdup_metrics.txt"
"$SAMTOOLS" index -@ 4 "$dedup"

printf '15\tchr15\n' > "$OUT/vcf_to_reference_contigs.tsv"
regional_vcf="${OUT}/${SAMPLE}.BUB1B.region.unphased.vcf.gz"
"$BCFTOOLS" view -r "$VCF_REGION" -Ou "$VCF" \
  | "$BCFTOOLS" annotate --rename-chrs "$OUT/vcf_to_reference_contigs.tsv" -Oz -o "$regional_vcf"
"$BCFTOOLS" index -f -t "$regional_vcf"

phased_vcf="${OUT}/${SAMPLE}.BUB1B.region.whatshap.vcf.gz"
"$WHATSHAP" phase \
    --reference "$REFERENCE" \
    --chromosome chr15 \
    --ignore-read-groups \
    --output "$phased_vcf" \
    "$regional_vcf" "$dedup"
"$BCFTOOLS" index -f -t "$phased_vcf"
"$WHATSHAP" stats --tsv "$OUT/whatshap_stats.tsv" --block-list "$OUT/whatshap_blocks.tsv" "$phased_vcf"

haplotagged="${OUT}/${SAMPLE}.BUB1B.region.whatshap.haplotagged.bam"
"$WHATSHAP" haplotag \
    --reference "$REFERENCE" \
    --ignore-read-groups \
    --output "$haplotagged" \
    "$phased_vcf" "$dedup"
"$SAMTOOLS" index -@ 4 "$haplotagged"

python3 "${PROJECT}/scripts/summarize_BUB1B_phasing.py" \
    "$phased_vcf" "$haplotagged" "$OUT"

echo "BUB1B phasing workflow completed. See ${OUT}/final_summary.md"
