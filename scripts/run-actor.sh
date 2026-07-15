#!/usr/bin/env bash
set -euo pipefail

actor_id="actablesite~new-behavioral-health-practices-actor"
public_preview_url="https://raw.githubusercontent.com/unitedideas/practice-radar-data/main/public/sample.json"
preview="${PREVIEW:-true}"
states="${STATES:-}"
max_charge="${MAX_TOTAL_CHARGE_USD:-0.10}"
output_file="${OUTPUT_FILE:-behavioral-health-practices.json}"

if [[ "$preview" != "true" && "$preview" != "false" ]]; then
  echo "preview must be true or false." >&2
  exit 2
fi
if ! [[ "$max_charge" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "max-total-charge-usd must be a non-negative number." >&2
  exit 2
fi
if [[ "$preview" == "false" ]] && ! awk -v value="$max_charge" 'BEGIN { exit !(value >= 9.25) }'; then
  echo "A full edition needs max-total-charge-usd of at least 9.25 to cover the fixed \$9 event and bounded platform usage." >&2
  exit 2
fi
if [[ "$preview" == "false" && -z "${APIFY_TOKEN:-}" ]]; then
  echo "APIFY_TOKEN is required for a full edition. Store it as a GitHub Actions secret." >&2
  exit 2
fi
if [[ "$output_file" == *$'\n'* || -z "$output_file" ]]; then
  echo "output-file must be a non-empty single-line path." >&2
  exit 2
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
input_file="$tmp_dir/input.json"
response_file="$tmp_dir/response.json"
states_json="$(jq -Rn --arg states "$states" '$states | split(",") | map(gsub("^[[:space:]]+|[[:space:]]+$"; "") | ascii_upcase | select(length > 0))')"

if [[ "$preview" == "true" ]]; then
  http_status="$({
    curl --silent --show-error --location \
      --output "$response_file" \
      --write-out '%{http_code}' \
      "$public_preview_url"
  } 2>"$tmp_dir/curl-error")" || {
    echo "The public preview request failed before returning an HTTP response." >&2
    sed -n '1,3p' "$tmp_dir/curl-error" >&2
    exit 1
  }
else
  jq -n \
    --argjson states "$states_json" \
    '{ preview: false, states: $states }' > "$input_file"

  endpoint="https://api.apify.com/v2/acts/${actor_id}/run-sync-get-dataset-items"
  query="timeout=300&memory=512&maxTotalChargeUsd=${max_charge}&format=json&clean=true"
  http_status="$({
    curl --silent --show-error --location \
      --output "$response_file" \
      --write-out '%{http_code}' \
      --request POST \
      --header "Authorization: Bearer ${APIFY_TOKEN}" \
      --header 'Content-Type: application/json' \
      --data-binary "@${input_file}" \
      "${endpoint}?${query}"
  } 2>"$tmp_dir/curl-error")" || {
    echo "The Apify request failed before returning an HTTP response." >&2
    sed -n '1,3p' "$tmp_dir/curl-error" >&2
    exit 1
  }
fi

if [[ ! "$http_status" =~ ^2[0-9][0-9]$ ]]; then
  error_message="$(jq -r '.error.message // .message // "Data request failed"' "$response_file" 2>/dev/null || printf 'Data request failed')"
  printf 'Data request returned HTTP %s: %s\n' "$http_status" "$error_message" >&2
  exit 1
fi
if [[ "$preview" == "true" ]]; then
  if ! jq -e '.receipt.schema_version == 1 and (.records | type == "array")' "$response_file" >/dev/null; then
    echo "The public preview did not match the versioned Practice Radar contract." >&2
    exit 1
  fi
  jq --argjson states "$states_json" \
    'if ($states | length) == 0 then .records else [.records[] | select(.state as $state | ($states | index($state)) != null)] end' \
    "$response_file" > "$tmp_dir/filtered.json"
  mv "$tmp_dir/filtered.json" "$response_file"
elif ! jq -e 'type == "array"' "$response_file" >/dev/null; then
  echo "Apify returned an invalid dataset response; no output file was published." >&2
  exit 1
fi

mkdir -p "$(dirname "$output_file")"
mv "$response_file" "$output_file"
record_count="$(jq 'length' "$output_file")"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf 'record-count=%s\n' "$record_count" >> "$GITHUB_OUTPUT"
  printf 'output-file=%s\n' "$output_file" >> "$GITHUB_OUTPUT"
fi
printf 'Wrote %s records to %s.\n' "$record_count" "$output_file"
