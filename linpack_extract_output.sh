#!/bin/bash

set -u

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <hpl_output_file>" >&2
  exit 1
fi

file="$1"

extract_number() {
  echo "$1" | sed -E 's/,/ /g' | sed -E 's/[^0-9eE.+-]+/ /g' | awk '{
    for(i=1;i<=NF;i++) {
      if ($i ~ /^[+-]?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$/) val=$i
    }
    if (val) print val
  }'
}

HPL_VAL=""
HPL_UNIT=""

line=$(grep -E "HPL_Tflops=|HPL_Gflops=|HPL.*Gflops|WR09c" "$file" 2>/dev/null | tail -n1 || true)
if [ -n "$line" ]; then
  HPL_VAL=$(extract_number "$line")
  if echo "$line" | grep -qi "Tflop"; then
    HPL_UNIT="Tflops"
  elif echo "$line" | grep -qi "Gflop"; then
    HPL_UNIT="Gflops"
  fi
fi

if [ -z "$HPL_VAL" ]; then
  perf_lines=$(awk '/^Performance Summary/ {p=1; next} p && NF==0 {p=0} p {print}' "$file" 2>/dev/null || true)
  if [ -n "$perf_lines" ]; then
    last_line=$(printf "%s\n" "$perf_lines" | awk '/^[[:space:]]*[0-9]+[[:space:]]+[0-9]+/ {line=$0} END{print line}')
    if [ -n "$last_line" ]; then
      avg_val=$(echo "$last_line" | awk '{print $4}')
      if echo "$avg_val" | grep -Eq '^[+-]?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$'; then
        HPL_VAL="$avg_val"
        HPL_UNIT="Gflops"
      fi
    fi
  fi
fi

if [ -z "$HPL_VAL" ]; then
  HPL_VAL=$(awk '/^[[:space:]]*[0-9]+[[:space:]]+[0-9]+/ { val=$NF } END{ if (val) print val }' "$file" | tail -n1 || true)
fi

HPL_VAL=${HPL_VAL:-""}

if [ -n "$HPL_VAL" ] && [ "$HPL_UNIT" = "Tflops" ]; then
  HPL_VAL=$(awk -v v="$HPL_VAL" 'BEGIN{printf "%.6g", v * 1000}')
fi

if [ -z "$HPL_VAL" ]; then
  echo "Warning: Failed to extract HPL value from $file" >&2
fi

yaml=$(cat <<EOF
---
  output:
    HPL:
      value: ${HPL_VAL}
EOF
)

echo "$yaml"

printf "%s\n" "$yaml" > output.yaml
