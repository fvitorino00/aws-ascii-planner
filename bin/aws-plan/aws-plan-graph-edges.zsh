# Derive service-level relationships from the concrete resource edge table.
# Populates global associative arrays SERVICE_REL_KIND and SERVICE_REL_LABEL.
# NOPROJ edges are intentionally excluded from the service projection because
# they describe low-level resource mechanics, not a service-level architecture edge.
# The Deadline Cloud + EC2 Mac special case is preserved separately.
aws_plan_graph_edges() {
  typeset -gA SERVICE_REL_KIND SERVICE_REL_LABEL
  local entry rel_key src dst

  for entry in "${RESOURCE_EDGES[@]}"; do
    resource_edge_parts "$entry"
    [[ "$RES_CONDITION" == NOPROJ ]] && continue
    resource_condition_ok "$RES_CONDITION" || continue
    is_graph_resource_emitted "$RES_SRC" || continue
    is_graph_resource_emitted "$RES_DST" || continue
    src="${RESOURCE_OWNER[$RES_SRC]}"
    dst="${RESOURCE_OWNER[$RES_DST]}"
    [[ $src == $dst ]] && continue
    is_graph_service_active "$src" || continue
    is_graph_service_active "$dst" || continue
    rel_key="$src|$dst"
    if [[ $RES_KIND == architecture ]]; then
      SERVICE_REL_KIND[$rel_key]=architecture
      SERVICE_REL_LABEL[$rel_key]="$RES_LABEL"
    elif [[ -z ${SERVICE_REL_KIND[$rel_key]:-} ]]; then
      SERVICE_REL_KIND[$rel_key]=setup
      SERVICE_REL_LABEL[$rel_key]="$RES_LABEL"
    fi
  done

  if [[ $REQ_DEADLINE == true && $MAC_REQUIRED == true && $REQ_EC2 == true ]]; then
    SERVICE_REL_KIND["DEADLINE|EC2"]=setup
    SERVICE_REL_LABEL["DEADLINE|EC2"]='install/register Mac worker agent'
  fi
}
