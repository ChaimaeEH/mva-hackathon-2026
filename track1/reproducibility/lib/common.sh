#!/usr/bin/env bash

set -euo pipefail

WORKFLOW_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPO_DIR=$(cd "${WORKFLOW_DIR}/.." && pwd)
CONFIG_FILE="${MVA_CONFIG:-${WORKFLOW_DIR}/config.env}"

if [[ ! -r "$CONFIG_FILE" ]]; then
    echo "ERROR: missing configuration: $CONFIG_FILE" >&2
    echo "Copy config.example.env to config.env and set the local paths." >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

WORK_DIR="${MVA_WORK_DIR:-${REPO_DIR}/work}"
PREP_DIR="${WORK_DIR}/01_prepared_vcf"
CONFIG_DIR="${WORK_DIR}/02_exomiser_config"
EXOMISER_RESULTS_DIR="${WORK_DIR}/03_exomiser_results"
ANNOTATION_DIR="${WORK_DIR}/04_annotations"
FINAL_DIR="${WORK_DIR}/05_final_table"
SUBMISSION_DIR="${REPO_DIR}/submissions"

require_file() {
    [[ -r "$1" ]] || { echo "ERROR: required file is not readable: $1" >&2; exit 1; }
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR: command not found: $1" >&2; exit 1; }
}

