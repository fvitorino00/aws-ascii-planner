aws_plan_graph_audit() {
AUDIT_VERSION="$(print -rl -- "${RESOURCE_EDGES[@]}" "${RESOURCE_IDS[@]}" "${GRAPH_ACTIVE[@]}" | cksum | cut -d' ' -f1)"
{
  print "# AWS Unified Graph Audit"
  print "Audit version: $AUDIT_VERSION"
  print
  print "## Graph rules"
  print
  print -r -- "- **DOTTED** = explicit user configuration/setup action."
  print -r -- "- **SOLID** = intrinsic architecture relationship once the resources are selected."
  print -r -- "- Every concrete resource has exactly one umbrella-service owner."
  print -r -- "- Service-level edges are derived from the concrete resource table."
  print -r -- '- `NOPROJ` flags retain low-level resource mechanics without manufacturing a misleading service-level edge.'
  print
  print "## Active umbrella services"
  print
  for sid in "${GRAPH_ACTIVE[@]}"; do print -r -- "- $sid — ${GRAPH_SERVICE_NAME[$sid]}"; done
  print
  print "## Resource ownership"
  print
  print "| Resource | Owner | Emitted |"
  print "|---|---|---|"
  for rid in "${RESOURCE_IDS[@]}"; do
    emitted=no; is_graph_resource_emitted "$rid" && emitted=yes
    print "| $rid | ${RESOURCE_OWNER[$rid]} | $emitted |"
  done
  print
  print "## Resource relationships"
  print
  print "| # | From | To | Kind | Label | Condition |"
  print "|---:|---|---|---|---|---|"
  i=0
  for entry in "${RESOURCE_EDGES[@]}"; do
    ((i++)); resource_edge_parts "$entry"
    print "| $i | $RES_SRC | $RES_DST | ${RES_KIND:u} | ${RES_LABEL:-—} | ${RES_CONDITION:-—} |"
  done
  print
  print "## Service-level relationships"
  print
  for rel_key in ${(k)SERVICE_REL_KIND}; do
    print -r -- "- ${rel_key%%|*} → ${rel_key#*|}: ${SERVICE_REL_KIND[$rel_key]} — ${SERVICE_REL_LABEL[$rel_key]}"
  done
} > "$GRAPH_AUDIT_FILE"


}
