aws_plan_graph_active_init() {
  typeset -ga GRAPH_ACTIVE GRAPH_ACTIVE_UNIQ
GRAPH_ACTIVE=(IAM BUDGET)
for id in VPC SSM LAMBDA S3 FSXLUSTRE DCV PCS PC BATCH ECR DEADLINE BEDROCK SAGE CW COSTEXP; do
  if [[ "$id" == VPC && "$REQ_VPC" == true ]] || \
     [[ "$id" == SSM && "$REQ_SSM" == true ]] || \
     [[ "$id" == LAMBDA && "$REQ_LAMBDA" == true ]] || \
     [[ "$id" == S3 && "$REQ_S3" == true ]] || \
     [[ "$id" == FSXLUSTRE && "$REQ_FSX" == true ]] || \
     [[ "$id" == DCV && "$REQ_DCV" == true ]] || \
     [[ "$id" == PCS && "$REQ_PCS" == true ]] || \
     [[ "$id" == PC && "$REQ_PC" == true ]] || \
     [[ "$id" == BATCH && "$REQ_BATCH" == true ]] || \
     [[ "$id" == ECR && "$REQ_ECR" == true ]] || \
     [[ "$id" == DEADLINE && "$REQ_DEADLINE" == true ]] || \
     [[ "$id" == BEDROCK && "$REQ_BEDROCK" == true ]] || \
     [[ "$id" == SAGE && "$REQ_SAGE" == true ]] || \
     [[ "$id" == CW && "$REQ_CW" == true ]] || \
     [[ "$id" == COSTEXP && "$REQ_COSTEXP" == true ]]; then
    contains "$id" "${GRAPH_ACTIVE[@]}" || GRAPH_ACTIVE+=("$id")
  fi
done
if [[ "$REQ_EC2" == true ]]; then GRAPH_ACTIVE+=(EC2); fi
GRAPH_ACTIVE_UNIQ=(); for id in "${GRAPH_ACTIVE[@]}"; do contains "$id" "${GRAPH_ACTIVE_UNIQ[@]}" || GRAPH_ACTIVE_UNIQ+=("$id"); done
GRAPH_ACTIVE=("${GRAPH_ACTIVE_UNIQ[@]}")

is_graph_service_active() { contains "$1" "${GRAPH_ACTIVE[@]}"; }

}
