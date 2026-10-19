# ASCII architecture graph renderer.
# Generates $AWS_SETUP_OUT/architecture.txt from the RESOURCE_EDGES table,
# condition helpers, and emitted-resource predicates shared with the rest of
# the graph model. NOPROJ edges are rendered as concrete resource setup actions;
# they are only excluded from the derived service-level relationships
# (see aws_plan_graph_edges).

aws_plan_graph_ascii() {
  local entry src_label dst_label rel_label
  local -a arch_edges setup_edges

  for entry in "${RESOURCE_EDGES[@]}"; do
    resource_edge_parts "$entry"
    resource_condition_ok "$RES_CONDITION" || continue
    is_graph_resource_emitted "$RES_SRC" || continue
    is_graph_resource_emitted "$RES_DST" || continue

    src_label="${RESOURCE_NAME[$RES_SRC]//\\n/ }"
    dst_label="${RESOURCE_NAME[$RES_DST]//\\n/ }"
    rel_label="$(resource_display_label)"
    rel_label="${rel_label//\\n/ }"

    if [[ $RES_KIND == architecture ]]; then
      arch_edges+=("$(printf '  %s --[%s]--> %s' "$src_label" "$rel_label" "$dst_label")")
    else
      setup_edges+=("$(printf '  %s ..[%s]..> %s' "$src_label" "$rel_label" "$dst_label")")
    fi
  done

  {
    print -r -- "AWS Unified Architecture Graph"
    print -r -- "=============================="
    print
    print -r -- "Legend:"
    print -r -- "  A --[relationship]--> B  intrinsic architecture relationship"
    print -r -- "  A ..[relationship]..> B  explicit setup/configuration action"
    print
    print -r -- "Architecture relationships"
    print -r -- "--------------------------"
    if (( ${#arch_edges[@]} > 0 )); then
      for e in "${arch_edges[@]}"; do print -r -- "$e"; done
    else
      print -r -- "  (none)"
    fi
    print
    print -r -- "Setup actions"
    print -r -- "-------------"
    if (( ${#setup_edges[@]} > 0 )); then
      for e in "${setup_edges[@]}"; do print -r -- "$e"; done
    else
      print -r -- "  (none)"
    fi
  } > "$ASCII_FILE"
}
