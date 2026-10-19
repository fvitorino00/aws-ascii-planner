#!/usr/bin/env zsh
set -euo pipefail

PLAN_SCHEMA='pc-aws-plan/v2'
PLAN_VALIDATOR="${0:A:h}/aws-plan-plan-validate.zsh"
BOOL_KEYS=(interruptible prefer_spot persistent_data interactive mac_required multi_node tightly_coupled slurm managed_slurm many_independent containerized managed_ml bedrock_api event_driven s3_event_source training inference vector_search extreme_object_io shared_posix orchestrated managed_spot_training dcv ebs fsx s3)

write_atomic_json() {
  local file_path="$1" data="$2" dir tmp
  dir="${file_path:h}"
  mkdir -p "$dir"
  tmp="$(mktemp "$dir/.${file_path:t}.XXXXXX")"
  if ! print -r -- "$data" | jq '.' > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  if ! zsh "$PLAN_VALIDATOR" validate --plan "$tmp" >/dev/null; then
    rm -f "$tmp"
    return 1
  fi
  mv -f "$tmp" "$file_path"
}

append_string() {
  local prior="$1" value="$2"
  jq -cn --argjson prior "$prior" --arg value "$value" '$prior + [$value]'
}

append_pair_row() {
  local prior="$1" row="$2" type="$3"
  jq -cn --argjson prior "$prior" --arg row "$row" --arg type "$type" '
    ($row | split("|")) as $f |
    if $type == "service" then
      $prior + [{id:$f[0],name:$f[1],category:$f[2],class:$f[3],reason:$f[4]}]
    elif $type == "resource" then
      $prior + [{id:$f[0],name:($f[1]|gsub("\\\\n";"\n")),owner:$f[2],category:$f[3],class:$f[4]}]
    else
      $prior + [{from:$f[0],to:$f[1],kind:$f[2],label:$f[3],condition:$f[4]}]
    end
  '
}

build_plan() {
  local output='' region='' workload='' execution='' arg key value
  local needs='{}' services='[]' resources='[]' relationships='[]' service_relationships='[]'
  local reasons='[]' optional='[]' avoid='[]' plan_id created_at plan
  while (( $# )); do
    arg="$1"; shift
    case "$arg" in
      --output) output="$1"; shift ;;
      --region) region="$1"; shift ;;
      --workload) workload="$1"; shift ;;
      --execution) execution="$1"; shift ;;
      --need|--service|--resource|--relationship|--service-relationship|--reason|--optional|--avoid)
        key="$arg"; value="$1"; shift
        case "$key" in
          --need)
            local need_key="${value%%=*}" need_value="${value#*=}"
            if (( ${BOOL_KEYS[(Ie)$need_key]} )); then
              [[ $need_value == true ]] && need_value=true || need_value=false
              needs="$(jq -cn --argjson n "$needs" --arg k "$need_key" --argjson v "$need_value" '$n + {($k):$v}')"
            else
              needs="$(jq -cn --argjson n "$needs" --arg k "$need_key" --arg v "$need_value" '$n + {($k):($v | if . == "" then null else . end)}')"
            fi ;;
          --service) services="$(append_pair_row "$services" "$value" service)" ;;
          --resource) resources="$(append_pair_row "$resources" "$value" resource)" ;;
          --relationship) relationships="$(append_pair_row "$relationships" "$value" edge)" ;;
          --service-relationship) service_relationships="$(append_pair_row "$service_relationships" "$value" edge)" ;;
          --reason) reasons="$(append_string "$reasons" "$value")" ;;
          --optional) optional="$(append_string "$optional" "$value")" ;;
          --avoid) avoid="$(append_string "$avoid" "$value")" ;;
        esac ;;
      *) print -u2 -r -- "aws-plan plan error: unknown build argument $arg"; return 2 ;;
    esac
  done
  [[ -n $workload && -n $execution && -n $output ]] || { print -u2 -r -- 'aws-plan plan error: build requires --workload, --execution, and --output'; return 2; }
  [[ $region == 'not configured' ]] && region=''
  plan_id="$(uuidgen | tr '[:upper:]' '[:lower:]')"
  created_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  local args=(--arg schema "$PLAN_SCHEMA" --arg plan_id "$plan_id" --arg created_at "$created_at"
    --arg workload "$workload" --arg execution "$execution" --arg region "$region"
    --arg compute "$(jq -r '.compute // ""' <<< "$needs")"
    --arg ram "$(jq -r '.ram // ""' <<< "$needs")" --arg vram "$(jq -r '.vram // ""' <<< "$needs")"
    --arg gpu_kind "$(jq -r '.gpu_kind // ""' <<< "$needs")"
    --argjson needs "$needs" --argjson services "$services" --argjson resources "$resources"
    --argjson relationships "$relationships" --argjson service_relationships "$service_relationships"
    --argjson reasons "$reasons" --argjson optional "$optional" --argjson avoid "$avoid")
  plan="$(jq -n "${args[@]}" '
    def nullable: if . == "" then null else . end;
    def compute_label: ({"1":"CPU","2":"GPU","3":"AWS ML accelerator"}[.] // null);
    def ram_label: ({small:"Up to about 16 GiB",medium:"About 16–64 GiB",large:"About 64–256 GiB",xlarge:"More than about 256 GiB"}[.] // null);
    def vram_label: ({"1":"Up to about 16 GiB","2":"About 16–48 GiB","3":"About 48–96 GiB","4":"More than about 96 GiB"}[.] // null);
    def gpu_label: ({"1":"Interactive graphics / visualization","2":"ML training / CUDA compute","3":"ML inference / serving","4":"High-VRAM workload; exact GPU family needs sizing"}[.] // null);
    $ARGS.named as $a |
    ($a.needs + {compute_label:($a.compute|compute_label),ram_label:($a.ram|ram_label),vram_label:($a.vram|vram_label),gpu_kind_label:($a.gpu_kind|gpu_label)}) as $needs |
    $a.resources as $resources |
    (["1","2","3","4","5","6","7","8","9"] | index($a.workload)) as $wc |
    {schema:$a.schema,plan_id:$a.plan_id,created_at:$a.created_at,planner:{name:"aws-plan",version:1},
     workload:{code:$a.workload,name:(["One-off / manually launched heavy computation","Many repeated independent jobs","Containerized pipeline","Interactive GUI / 3D workstation","3D render farm","Distributed HPC / multi-node calculation","ML training or self-hosted model inference","Managed foundation-model API","Lightweight event-driven / serverless task"][$wc] // "Unknown workload"),execution_model:$a.execution},
     requirements:$needs,
     decision:{selected_services:$a.services,optional_services:$a.optional,avoided_services:$a.avoid,rationale:$a.reasons},
     architecture:{resources:$resources,relationships:$a.relationships,service_relationships:($a.service_relationships|map(del(.condition)))},
     target:{region:($a.region|nullable)}}
  ' )"
  write_atomic_json "$output" "$plan"
  write_atomic_json "${output:h}/plans/${plan_id}.json" "$plan"
}

command="${1:-}"
shift || true
[[ $command == build ]] || { print -u2 -r -- 'usage: aws-plan-plan.zsh build --workload CODE --execution MODEL --output FILE'; exit 2; }
build_plan "$@"
