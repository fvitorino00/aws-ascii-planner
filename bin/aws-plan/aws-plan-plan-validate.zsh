#!/usr/bin/env zsh
set -euo pipefail

PLAN_SCHEMA='pc-aws-plan/v2'

json_validate() {
  local file="$1"
  jq -e --arg schema "$PLAN_SCHEMA" '
    . as $plan |
    type == "object" and .schema == $schema and
    all(["plan_id","workload","requirements","decision","architecture","target"][]; . as $key | $plan | has($key)) and
    all(["workload","decision","architecture","target"][]; . as $key | $plan[$key] | type == "object") and
    (.plan_id | type == "string" and test("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")) and
    (.requirements | type == "object") and
    (.decision.selected_services | type == "array" and all(.[]; type == "object" and (.id | type == "string" and test("^[A-Z0-9_]+$")))) and
    (.architecture.resources | type == "array") and
    (.architecture.relationships | type == "array") and
    (.architecture.service_relationships | type == "array") and
    (["interruptible","prefer_spot","persistent_data","interactive","mac_required","multi_node","tightly_coupled","slurm","managed_slurm","many_independent","containerized","managed_ml","bedrock_api","event_driven","s3_event_source","training","inference","vector_search","extreme_object_io","shared_posix","orchestrated","managed_spot_training","dcv","ebs","fsx","s3"] | all(.[]; . as $k | ($plan.requirements[$k] == null or ($plan.requirements[$k] | type == "boolean"))))
  ' "$file" >/dev/null
}

command="${1:-}"
shift || true
case "$command" in
  validate)
    [[ ${1:-} == --plan && -n ${2:-} ]] || { print -u2 -r -- 'usage: aws-plan-plan-validate.zsh validate --plan FILE'; exit 2; }
    json_validate "$2" || { print -u2 -r -- "aws-plan plan error: invalid plan $2"; exit 2; }
    jq -r '"Valid pc-aws-plan/v2: \(.plan_id)"' "$2" ;;
  *) print -u2 -r -- 'usage: aws-plan-plan-validate.zsh validate --plan FILE'; exit 2 ;;
esac
