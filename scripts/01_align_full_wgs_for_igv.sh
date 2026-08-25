#!/usr/bin/env bash
#SBATCH --job-name=mva_full_wgs_bam
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=96G
#SBATCH --time=48:00:00
#SBATCH --output=/work/gr-fe/share/mva-challenge/logs/01_full_wgs_bam_%j.out
#SBATCH --error=/work/gr-fe/share/mva-challenge/logs/01_full_wgs_bam_%j.err

set -euo pipefail

DATA="/work/gr-fe/databases/mva-challenge-data"
PROJECT="/work/gr-fe/share/mva-challenge"
OUTPUT_DIR="${PROJECT}/outputs/01_full_wgs_bam"
SAMPLE="WGS_EX2312012"
FLOWCELL="HGWCNDSX7"
REFERENCE="/work/gr-fe/saadat/Reference_Genome/GRCH38_no_alt/GCA_000001405.15_GRCh38_no_alt_analysis_set.fa.gz"
BWA="/work/gr-fe/elhoujja/tools/bwa/bwa"
SAMTOOLS="/work/gr-fe/elhoujja/tools/samtools/samtools-1.23/bin/samtools"
THREADS="${SLURM_CPUS_PER_TASK:-24}"
SORT_THREADS=8
SORT_MEMORY="6G"

JOB_TOKEN="${SLURM_JOB_ID:-manual_$$}"
WORK_DIR="/scratch/elhoujja/mva_full_wgs_bam_${JOB_TOKEN}"
FINAL_BAM="${OUTPUT_DIR}/${SAMPLE}.GRCh38.markdup.bam"
METRICS="${OUTPUT_DIR}/${SAMPLE}.GRCh38.markdup.metrics.txt"

mkdir -p "$OUTPUT_DIR" "${PROJECT}/logs" "$WORK_DIR"

cleanup_success() {
    # Delete only this job's explicitly named scratch directory after validation.
    rm -rf -- "$WORK_DIR"
}

fail() {
    echo "ERROR: $*" >&2
    echo "Scratch intermediates retained for diagnosis: $WORK_DIR" >&2
    exit 1
}

for required in "$REFERENCE" "${REFERENCE}.bwt" "${REFERENCE}.fai" "$BWA" "$SAMTOOLS"; do
    [[ -r "$required" ]] || fail "required file is not readable: $required"
done

echo "Whole-genome BAM workflow started: $(date --iso-8601=seconds)"
echo "Reference: $REFERENCE"
echo "Scratch:   $WORK_DIR"
echo "Output:    $FINAL_BAM"

"$BWA" 2>&1 | head -n 3 > "${OUTPUT_DIR}/bwa_version.txt" || true
"$SAMTOOLS" --version | head -n 2 > "${OUTPUT_DIR}/samtools_version.txt"
printf '%s\n' "$REFERENCE" > "${OUTPUT_DIR}/reference_path.txt"

lane_bams=()
for lane in 001 002 003 004; do
    r1="${DATA}/${SAMPLE}_${FLOWCELL}_S16_L${lane}_R1_001.fastq.gz"
    r2="${DATA}/${SAMPLE}_${FLOWCELL}_S16_L${lane}_R2_001.fastq.gz"
    name_bam="${WORK_DIR}/${SAMPLE}.L${lane}.name.bam"
    fixmate_bam="${WORK_DIR}/${SAMPLE}.L${lane}.fixmate.bam"
    coord_bam="${WORK_DIR}/${SAMPLE}.L${lane}.fixmate.coord.bam"

    [[ -r "$r1" && -r "$r2" ]] || fail "missing paired FASTQs for lane L${lane}"
    rg="@RG\\tID:${SAMPLE}.L${lane}\\tSM:${SAMPLE}\\tLB:${SAMPLE}\\tPL:ILLUMINA\\tPU:${FLOWCELL}.L${lane}"

    echo "Aligning lane L${lane}: $(date --iso-8601=seconds)"
    "$BWA" mem -t "$THREADS" -R "$rg" "$REFERENCE" "$r1" "$r2" \
      | "$SAMTOOLS" sort \
          -n \
          -@ "$SORT_THREADS" \
          -m "$SORT_MEMORY" \
          -T "${WORK_DIR}/L${lane}.name_sort" \
          -o "$name_bam" \
          -

    "$SAMTOOLS" fixmate -@ "$SORT_THREADS" -m "$name_bam" "$fixmate_bam"
    "$SAMTOOLS" sort \
        -@ "$SORT_THREADS" \
        -m "$SORT_MEMORY" \
        -T "${WORK_DIR}/L${lane}.coord_sort" \
        -o "$coord_bam" \
        "$fixmate_bam"

    "$SAMTOOLS" quickcheck -v "$coord_bam" || fail "lane L${lane} BAM failed quickcheck"
    rm -f -- "$name_bam" "$fixmate_bam"
    lane_bams+=("$coord_bam")
done

merged_bam="${WORK_DIR}/${SAMPLE}.GRCh38.fixmate.merged.bam"
echo "Merging four coordinate-sorted lanes: $(date --iso-8601=seconds)"
"$SAMTOOLS" merge -@ "$SORT_THREADS" -f "$merged_bam" "${lane_bams[@]}"
"$SAMTOOLS" quickcheck -v "$merged_bam" || fail "merged BAM failed quickcheck"

echo "Marking duplicates: $(date --iso-8601=seconds)"
"$SAMTOOLS" markdup \
    -@ "$SORT_THREADS" \
    -s \
    -f "$METRICS" \
    "$merged_bam" "$FINAL_BAM"

"$SAMTOOLS" index -@ "$SORT_THREADS" "$FINAL_BAM"
"$SAMTOOLS" quickcheck -v "$FINAL_BAM" || fail "final BAM failed quickcheck"
[[ -s "${FINAL_BAM}.bai" ]] || fail "BAM index was not created"

"$SAMTOOLS" flagstat -@ "$SORT_THREADS" "$FINAL_BAM" > "${OUTPUT_DIR}/${SAMPLE}.GRCh38.markdup.flagstat.txt"
"$SAMTOOLS" idxstats "$FINAL_BAM" > "${OUTPUT_DIR}/${SAMPLE}.GRCh38.markdup.idxstats.txt"
"$SAMTOOLS" stats -@ "$SORT_THREADS" "$FINAL_BAM" > "${OUTPUT_DIR}/${SAMPLE}.GRCh38.markdup.stats.txt"
md5sum "$FINAL_BAM" "${FINAL_BAM}.bai" > "${OUTPUT_DIR}/${SAMPLE}.GRCh38.markdup.md5"

cleanup_success
echo "Whole-genome BAM workflow completed: $(date --iso-8601=seconds)"
echo "IGV BAM:   $FINAL_BAM"
echo "IGV index: ${FINAL_BAM}.bai"
