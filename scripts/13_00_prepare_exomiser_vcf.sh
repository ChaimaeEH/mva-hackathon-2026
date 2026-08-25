#!/usr/bin/env bash
#SBATCH --job-name=mva_exomiser_prep
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=/work/gr-fe/share/mva-challenge/logs/13_00_prepare_%j.out
#SBATCH --error=/work/gr-fe/share/mva-challenge/logs/13_00_prepare_%j.err

set -euo pipefail

INPUT_VCF="/work/gr-fe/databases/mva-challenge-data/WGS_EX2312012_HGWCNDSX7.vcf.gz"
REFERENCE="/work/gr-fe/saadat/Reference_Genome/GRCH38_primary_assembly/Homo_sapiens.GRCh38.dna.primary_assembly.fa"
PROJECT="/work/gr-fe/share/mva-challenge"
OUTPUT_DIR="${PROJECT}/outputs/13_exomiser/input"
OUTPUT_VCF="${OUTPUT_DIR}/WGS_EX2312012_HGWCNDSX7.pass.canonical.norm.vcf.gz"
CHROM_MAP="${OUTPUT_DIR}/rename_chromosomes.tsv"
EXPECTED_SAMPLE="WGS_EX2312012"
CANONICAL_CONTIGS="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,X,Y,M"

mkdir -p "$OUTPUT_DIR" "${PROJECT}/logs"

for file in "$INPUT_VCF" "$REFERENCE" "${REFERENCE}.fai"; do
    if [[ ! -r "$file" ]]; then
        echo "ERROR: required file is not readable: $file" >&2
        exit 1
    fi
done

sample_count=$(bcftools query -l "$INPUT_VCF" | wc -l)
sample_name=$(bcftools query -l "$INPUT_VCF")
if [[ "$sample_count" -ne 1 || "$sample_name" != "$EXPECTED_SAMPLE" ]]; then
    echo "ERROR: expected one sample named ${EXPECTED_SAMPLE}; found ${sample_count}: ${sample_name}" >&2
    exit 1
fi

# The input calls mitochondrial DNA "M"; the Ensembl GRCh38 reference calls it "MT".
printf 'M\tMT\n' > "$CHROM_MAP"

echo "Preparing PASS-only, canonical-contig, split and normalized Exomiser input."
echo "Input:  $INPUT_VCF"
echo "Output: $OUTPUT_VCF"

bcftools view \
    --threads 4 \
    --apply-filters PASS \
    --regions "$CANONICAL_CONTIGS" \
    --output-type u \
    "$INPUT_VCF" \
| bcftools annotate \
    --threads 4 \
    --rename-chrs "$CHROM_MAP" \
    --output-type u \
| bcftools norm \
    --threads 4 \
    --fasta-ref "$REFERENCE" \
    --multiallelics -any \
    -d exact \
    --output-type z \
    --output "$OUTPUT_VCF"

bcftools index --force --tbi "$OUTPUT_VCF"
bcftools view --header-only "$OUTPUT_VCF" >/dev/null
if [[ ! -s "${OUTPUT_VCF}.tbi" ]]; then
    echo "ERROR: tabix index was not created: ${OUTPUT_VCF}.tbi" >&2
    exit 1
fi

input_records=$(bcftools index --nrecords "$INPUT_VCF")
output_records=$(bcftools index --nrecords "$OUTPUT_VCF")
output_samples=$(bcftools query -l "$OUTPUT_VCF")

echo "Input records:  $input_records"
echo "Output records: $output_records"
echo "Output sample:  $output_samples"
echo "Prepared VCF and index successfully."
