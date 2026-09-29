#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Aggregate Evaluation Runner (edit values in this section)
#
# ./scripts/run_aggregate_eval.sh
# ./scripts/run_aggregate_eval.sh --method teler|reasoning|both
# ./scripts/run_aggregate_eval.sh --llm-name google_gemma-2-2b-it
# ./scripts/run_aggregate_eval.sh --help
# ============================================================
# Set METHOD to: teler | reasoning | both
METHOD="teler"

# Optional default model stem (e.g., google_gemma-2-2b-it). Empty means all models.
# Override at runtime with: ./scripts/run_aggregate_eval.sh --llm-name STEM
LLM_NAME=""

# Toggle flags: true | false
BY_DATASET="true"
COMMON_MODELS_ONLY="false"
TXT_NO_DETAIL="false"

# Optional custom input dir (leave empty to use defaults from script).
# Default behavior:
#   teler    -> data/eval_files/teler
#   reasoning-> data/eval_files/reasoning
#   both     -> uses both defaults above
INPUT_DIR=""

# Output paths (relative to repo root).
OUTPUT_JSON="data/eval_files/aggregate/evaluation_by_template.json"
OUTPUT_TXT="data/eval_files/aggregate/evaluation_by_template.txt"

# ============================================================
# End config
# ============================================================

usage() {
  cat <<'EOF'
Usage: scripts/run_aggregate_eval.sh [options]

Options override the config block at the top of this script.
  --method teler|reasoning|both
  --llm-name STEM          Aggregate one model (xlsx file stem). Empty value means all models.
  --input-dir DIR
  --output PATH
  --output-txt PATH
  --by-dataset true|false
  --common-models-only true|false
  --txt-no-detail true|false
  -h, --help


EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --method)
      METHOD="${2:?--method requires a value}"
      shift 2
      ;;
    --llm-name|-l)
      LLM_NAME="${2-}"
      shift 2
      ;;
    --input-dir)
      INPUT_DIR="${2:?--input-dir requires a value}"
      shift 2
      ;;
    --output)
      OUTPUT_JSON="${2:?--output requires a value}"
      shift 2
      ;;
    --output-txt)
      OUTPUT_TXT="${2:?--output-txt requires a value}"
      shift 2
      ;;
    --by-dataset)
      BY_DATASET="${2:?--by-dataset requires true or false}"
      shift 2
      ;;
    --common-models-only)
      COMMON_MODELS_ONLY="${2:?--common-models-only requires true or false}"
      shift 2
      ;;
    --txt-no-detail)
      TXT_NO_DETAIL="${2:?--txt-no-detail requires true or false}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
SCRIPT_PATH="$PROJECT_ROOT/result_scripts/result_by_template.py"

cd "$PROJECT_ROOT"

ARGS=(
  --method "$METHOD"
  --output "$OUTPUT_JSON"
  --output-txt "$OUTPUT_TXT"
)

if [[ -n "$INPUT_DIR" ]]; then
  ARGS+=(--input-dir "$INPUT_DIR")
fi

if [[ -n "$LLM_NAME" ]]; then
  ARGS+=(--llm-name "$LLM_NAME")
fi

if [[ "$BY_DATASET" == "true" ]]; then
  ARGS+=(--by-dataset)
fi

if [[ "$COMMON_MODELS_ONLY" == "true" ]]; then
  ARGS+=(--common-models-only)
fi

if [[ "$TXT_NO_DETAIL" == "true" ]]; then
  ARGS+=(--txt-no-detail)
fi

echo "[info] running aggregate eval with:"
echo "       METHOD=$METHOD"
echo "       LLM_NAME=${LLM_NAME:-<all>}"
echo "       BY_DATASET=$BY_DATASET"
echo "       COMMON_MODELS_ONLY=$COMMON_MODELS_ONLY"
echo "       TXT_NO_DETAIL=$TXT_NO_DETAIL"
echo "       INPUT_DIR=${INPUT_DIR:-<default>}"
echo "       OUTPUT_JSON=$OUTPUT_JSON"
echo "       OUTPUT_TXT=$OUTPUT_TXT"

exec "$PYTHON_BIN" "$SCRIPT_PATH" "${ARGS[@]}"
