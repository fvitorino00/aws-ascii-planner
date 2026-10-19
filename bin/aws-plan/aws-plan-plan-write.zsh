aws_plan_write_plan() {
  local rid entry rel_key src dst kind label condition emitted
  local -a plan_args
  local dcv=false ebs=false fsx=false s3=false
  contains DCV "${SERVICES[@]}" && dcv=true
  contains EBS "${SERVICES[@]}" && ebs=true
  contains FSXLUSTRE "${SERVICES[@]}" && fsx=true
  contains S3 "${SERVICES[@]}" && s3=true

  if ! command -v jq >/dev/null 2>&1; then
    print -u2 -r -- "jq is required to write the declarative plan file."
    return 1
  fi

  plan_args=(build --workload "$WORKLOAD" --execution "$EXECUTION_MODE" --output "$AWS_SETUP_OUT/plan.json" --region "${REGION:-}")
  plan_args+=(--need "compute=${COMPUTE:-}" --need "ram=${RAM:-}" --need "vram=${VRAM:-}" --need "gpu_kind=${GPU_KIND:-}")
  plan_args+=(--need "interruptible=${INTERRUPTIBLE}" --need "prefer_spot=${PREFER_SPOT}" --need "persistent_data=${PERSISTENT_DATA}" --need "interactive=${INTERACTIVE}")
  plan_args+=(--need "mac_required=${MAC_REQUIRED}" --need "multi_node=${MULTI_NODE}" --need "tightly_coupled=${TIGHTLY_COUPLED}" --need "slurm=${SLURM}" --need "managed_slurm=${MANAGED_SLURM}")
  plan_args+=(--need "many_independent=${MANY_INDEPENDENT}" --need "containerized=${CONTAINERIZED}" --need "managed_ml=${MANAGED_ML}" --need "bedrock_api=${BEDROCK_API}" --need "event_driven=${EVENT_DRIVEN}")
  plan_args+=(--need "s3_event_source=${S3_EVENT_SOURCE}" --need "training=${TRAINING}" --need "inference=${INFERENCE}" --need "vector_search=${VECTOR_SEARCH}" --need "extreme_object_io=${EXTREME_OBJECT_IO}" --need "shared_posix=${SHARED_POSIX}")
  plan_args+=(--need "orchestrated=${ORCHESTRATED}" --need "managed_spot_training=${MANAGED_SPOT_TRAINING}" --need "dcv=${dcv}" --need "ebs=${ebs}" --need "fsx=${fsx}" --need "s3=${s3}")

  for rid in "${SERVICES[@]}"; do
    plan_args+=(--service "$rid|${SERVICE_NAME[$rid]}|${SERVICE_CATEGORY[$rid]}|${SERVICE_CLASS[$rid]}|")
  done
  for entry in "${REASONS[@]}"; do plan_args+=(--reason "$entry"); done
  for entry in "${OPTIONAL[@]}"; do plan_args+=(--optional "$entry"); done
  for entry in "${AVOID[@]}"; do plan_args+=(--avoid "$entry"); done

  for rid in "${RESOURCE_IDS[@]}"; do
    is_graph_resource_emitted "$rid" || continue
    plan_args+=(--resource "$rid|${RESOURCE_NAME[$rid]}|${RESOURCE_OWNER[$rid]}|${RESOURCE_CATEGORY[$rid]}|${RESOURCE_CLASS[$rid]}")
  done
  for entry in "${RESOURCE_EDGES[@]}"; do
    resource_edge_parts "$entry"
    resource_condition_ok "$RES_CONDITION" || continue
    is_graph_resource_emitted "$RES_SRC" || continue
    is_graph_resource_emitted "$RES_DST" || continue
    plan_args+=(--relationship "$entry")
  done
  for rel_key in ${(k)SERVICE_REL_KIND}; do
    src="${rel_key%%|*}"; dst="${rel_key#*|}"
    kind="${SERVICE_REL_KIND[$rel_key]}"; label="${SERVICE_REL_LABEL[$rel_key]}"
    plan_args+=(--service-relationship "$src|$dst|$kind|$label|")
  done

  zsh "$AWS_PLAN_ROOT/aws-plan-plan.zsh" "${plan_args[@]}"
}
