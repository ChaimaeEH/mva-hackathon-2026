#!/usr/bin/env bash

set -euo pipefail

PROJECT="/work/gr-fe/share/mva-challenge"
SCRIPTS="${PROJECT}/scripts"

mkdir -p "${PROJECT}/logs" "${PROJECT}/outputs/13_exomiser"

# YAML creation is fast and can happen before its referenced VCF is prepared.
"${SCRIPTS}/13_01_create_exomiser_yaml.sh"

prepare_job=$(sbatch --parsable "${SCRIPTS}/13_00_prepare_exomiser_vcf.sh")
exomiser_job=$(sbatch \
    --parsable \
    --dependency="afterok:${prepare_job}" \
    "${SCRIPTS}/13_02_run_exomiser.sh")

echo "Submitted preprocessing job: $prepare_job"
echo "Submitted Exomiser job:      $exomiser_job (afterok:$prepare_job)"
echo "Monitor with: squeue -j ${prepare_job},${exomiser_job}"
