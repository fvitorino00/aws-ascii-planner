aws_plan_graph_relationships_init() {
  typeset -ga RESOURCE_EDGES
RESOURCE_EDGES=(
  'VPC_RES|SUBNET|architecture|contains subnet|'
  'SUBNET|EC2_RES|setup|launch EC2 in subnet|'
  'SG|EC2_RES|setup|associate security group|'
  'ROLE|PROFILE|setup|add role to instance profile|'
  'PROFILE|EC2_RES|setup|attach instance profile|'
  'DEDICATED_HOST|EC2_RES|setup|allocate Dedicated Host and launch Mac instance|mac'
  'VPC_RES|FSX|setup|create filesystem in VPC/subnets|'
  'VPC_RES|S3EXP_EP|setup|create S3 Express gateway endpoint|NOPROJ'

  'LAMBDA_ROLE|LAMBDAF|setup|attach execution role|'
  'LAMBDA_ROLE|BEDROCK_CFG|setup|grant Bedrock model permissions|lambda_bedrock'
  'SAGE_ROLE|SMJOB|setup|attach execution role|'
  'SAGE_ROLE|ECRR|setup|grant SageMaker image access|sage_ecr'
  'SAGE_ROLE|CWLG|setup|grant SageMaker log access|sage_logs'
  'BEDROCK_ROLE|BEDROCK_KB|setup|attach Knowledge Base service role|bedrock_kb_role'
  'BEDROCK_ROLE|BEDROCK_CFG|setup|grant Knowledge Base model access|bedrock_kb_role'
  'BEDROCK_ROLE|S3B|setup|grant Knowledge Base S3 access|bedrock_kb_s3'
  'BEDROCK_ROLE|S3VB|setup|grant Knowledge Base S3 Vectors access|bedrock_kb_vectors'
  'BATCH_ROLE|BATCHCE|setup|use required Batch service role|'
  'PCS_ROLE|PCSCL|setup|use required PCS service role|'
  'PC_ROLE|PCCL|setup|use cluster IAM roles|'
  'DEADLINE_HOST_ROLE|FLEET|setup|use worker-host role|deadline_worker'
  'DEADLINE_QUEUE_ROLE|DQUEUE|setup|use queue role|deadline_queue_role'
  'DEADLINE_QUEUE_ROLE|S3B|setup|grant queue job-attachment S3 access|deadline_s3'
  'DEADLINE_FLEET_ROLE|FLEET|setup|use fleet role|deadline_worker'
  'DEADLINE_FLEET_ROLE|CWLG|setup|grant worker log access|deadline_logs'

  'SSM_RES|EC2_RES|setup|configure Session Manager access|'
  'EC2_RES|EBSV|setup|attach and format block device|'
  'EC2_RES|S3B|setup|configure S3 access|'
  'EC2_RES|S3XB|setup|configure S3 Express client access|'
  'ROLE|S3B|setup|grant S3 permissions|'
  'ROLE|S3XB|setup|grant S3 Express permissions|'
  'LAMBDA_ROLE|S3B|setup|grant Lambda S3 permissions|lambda_s3'
  'SAGE_ROLE|S3B|setup|grant SageMaker S3 permissions|sage_s3'
  'EC2_RES|DCVS|setup|install/configure DCV server|'
  'EC2_RES|FSX|setup|mount Lustre filesystem|'
  'S3B|FSX|setup|link S3 bucket as data repository|'

  'EC2_RES|EFAI|setup|attach EFA interface|NOPROJ'
  'SG|EFAI|setup|allow EFA/Lustre traffic|NOPROJ'
  'PCSNG|EFAI|setup|configure EFA|NOPROJ'
  'PCCL|EFAI|setup|configure EFA-enabled nodes|NOPROJ'
  'SMJOB|EFAI|setup|enable EFA|NOPROJ'

  'VPC_RES|PCSCL|setup|create PCS cluster in VPC/subnets|'
  'PCSCL|PCSNG|architecture|contains compute node group|'
  'PCSCL|PCSQ|setup|create queue in cluster|'
  'PCSQ|PCSNG|architecture|routes queued jobs to compute node group|'
  'PCSNG|FSX|setup|mount shared filesystem|pcs_fsx'
  'PCSNG|EC2_RES|architecture|provisions EC2 compute nodes|pcs_capacity'
  'PCSNG|TRNNODE|architecture|launches Trainium compute|pcs_trn'
  'PCSNG|INFNODE|architecture|launches Inferentia compute|pcs_inf'

  'VPC_RES|PCCL|setup|create ParallelCluster in VPC/subnets|'
  'PCCL|FSX|setup|mount shared filesystem|pc_fsx'
  'PCCL|EC2_RES|architecture|provisions EC2 cluster capacity|pc_capacity'
  'PCCL|TRNNODE|architecture|launches Trainium compute|pc_trn'
  'PCCL|INFNODE|architecture|launches Inferentia compute|pc_inf'
  'PCCL|DCVS|setup|enable DCV in cluster|'

  'VPC_RES|BATCHCE|setup|configure Batch compute-environment networking|'
  'BATCHCE|BATCHQ|setup|attach compute environment to queue|'
  'BATCHQ|BATCH_JOB|architecture|receives submitted jobs|'
  'BATCHJD|BATCH_JOB|architecture|defines job parameters|'
  'BATCHJD|BATCH_IMG|setup|job definition selects container image|'
  'BATCH_IMG|ECRR|setup|use image from ECR repository|batch_ecr'
  'BATCHCE|EC2_RES|architecture|provisions EC2 compute capacity|batch_capacity'

  'FARM|DQUEUE|architecture|contains queue|'
  'FARM|FLEET|architecture|contains worker fleet|'
  'S3B|DQUEUE|setup|configure queue job-attachment bucket|'
  'DQUEUE|FLEET|setup|associate queue and fleet|'
  'FLEET|EC2_RES|architecture|runs workers on EC2 capacity|deadline_capacity'
  'FLEET|CWLG|architecture|writes worker logs|'

  'S3B|LAMBDAF|setup|configure S3 event trigger|s3_event'
  'ECRR|LAMBDAF|setup|configure ECR container image|lambda_ecr'
  'LAMBDAF|BEDROCK_CFG|architecture|invokes Bedrock Runtime API|'
  'LAMBDAF|CWLG|architecture|writes invocation logs|'

  'S3B|BEDROCK_KB|setup|configure S3 data source|bedrock_kb_s3'
  'S3VB|BEDROCK_KB|setup|use S3 Vectors as Bedrock vector store|bedrock_kb_vectors'

  'S3B|SMJOB|setup|set S3 input/output URI|sage_s3'
  'SMJOB|ECRR|setup|select SageMaker image|sage_ecr'
  'SMJOB|FSX|setup|use FSx as training input|sage_fsx'
  'SMJOB|CWLG|architecture|writes SageMaker logs|'
  'SMJOB|TRNNODE|architecture|uses Trainium compute|sage_trn'
  'SMJOB|INFNODE|architecture|uses Inferentia compute|sage_inf'

  'EC2_RES|CWMETRIC|architecture|publishes EC2 basic metrics|'
  'BATCHJD|CWLG|setup|configure awslogs log group|batch_logs'
  'BATCH_JOB|CWLG|architecture|writes container logs|batch_logs'

)

resource_edge_parts() {
  local entry="$1"
  RES_SRC="${entry%%|*}"
  local rest="${entry#*|}"
  RES_DST="${rest%%|*}"
  rest="${rest#*|}"
  RES_KIND="${rest%%|*}"
  rest="${rest#*|}"
  RES_LABEL="${rest%%|*}"
  RES_CONDITION="${rest#*|}"
}

resource_condition_ok() {
  case "$1" in
    '') true ;;
    NOPROJ) true ;;
    mac) [[ "$MAC_REQUIRED" == true ]] ;;
    s3_event) [[ "$S3_EVENT_SOURCE" == true ]] ;;
    lambda_s3) [[ "$REQ_LAMBDA" == true && "$REQ_S3" == true ]] ;;
    lambda_ecr) [[ "$REQ_LAMBDA" == true && "$REQ_ECR" == true ]] ;;
    lambda_bedrock) [[ "$REQ_LAMBDA" == true && "$REQ_BEDROCK" == true ]] ;;
    sage_s3) [[ "$REQ_SAGE" == true && "$REQ_S3" == true ]] ;;
    sage_ecr) [[ "$REQ_SAGE" == true && "$REQ_ECR" == true ]] ;;
    sage_fsx) [[ "$REQ_SAGE" == true && "$REQ_FSX" == true ]] ;;
    sage_logs) [[ "$REQ_SAGE" == true && "$REQ_CW" == true ]] ;;
    sage_trn) [[ "$REQ_SAGE" == true && "$REQ_TRN" == true ]] ;;
    sage_inf) [[ "$REQ_SAGE" == true && "$REQ_INF" == true ]] ;;
    bedrock_kb_role) [[ "$REQ_BEDROCK_ROLE" == true && "$REQ_BEDROCK" == true && "$VECTOR_SEARCH" == true ]] ;;
    bedrock_kb_s3) [[ "$REQ_BEDROCK" == true && "$REQ_S3" == true && "$VECTOR_SEARCH" == true ]] ;;
    bedrock_kb_vectors) [[ "$REQ_BEDROCK" == true && "$REQ_S3V" == true && "$VECTOR_SEARCH" == true ]] ;;
    batch_ecr) [[ "$REQ_BATCH" == true && "$REQ_ECR" == true ]] ;;
    batch_logs) [[ "$REQ_BATCH" == true && "$REQ_CW" == true ]] ;;
    batch_capacity) [[ "$REQ_BATCH" == true && "$REQ_EC2" == true ]] ;;
    pcs_fsx) [[ "$REQ_PCS" == true && "$REQ_FSX" == true ]] ;;
    pcs_capacity) [[ "$REQ_PCS" == true && "$REQ_EC2" == true ]] ;;
    pcs_trn) [[ "$REQ_PCS" == true && "$REQ_TRN" == true ]] ;;
    pcs_inf) [[ "$REQ_PCS" == true && "$REQ_INF" == true ]] ;;
    pc_fsx) [[ "$REQ_PC" == true && "$REQ_FSX" == true ]] ;;
    pc_capacity) [[ "$REQ_PC" == true && "$REQ_EC2" == true ]] ;;
    pc_trn) [[ "$REQ_PC" == true && "$REQ_TRN" == true ]] ;;
    pc_inf) [[ "$REQ_PC" == true && "$REQ_INF" == true ]] ;;
    deadline_capacity|deadline_worker) [[ "$REQ_DEADLINE" == true && "$REQ_EC2" == true ]] ;;
    deadline_queue_role) [[ "$REQ_DEADLINE_QUEUE_ROLE" == true ]] ;;
    deadline_s3) [[ "$REQ_DEADLINE" == true && "$REQ_S3" == true ]] ;;
    deadline_logs) [[ "$REQ_DEADLINE_FLEET_ROLE" == true && "$REQ_CW" == true ]] ;;
    *) print -u2 -r -- "Unknown resource-edge condition: $1"; return 1 ;;
  esac
}

typeset -A EDGE_SEEN
GRAPH_AUDIT_ERRORS=()
for rid in "${RESOURCE_IDS[@]}"; do
  owner="${RESOURCE_OWNER[$rid]:-}"
  [[ -n "$owner" ]] || GRAPH_AUDIT_ERRORS+=("resource $rid has no owner")
  if [[ -n "$owner" ]] && ! contains "$owner" "${GRAPH_SERVICE_IDS[@]}"; then
    GRAPH_AUDIT_ERRORS+=("resource $rid has unknown owner $owner")
  fi
  [[ -n "${RESOURCE_NAME[$rid]:-}" ]] || GRAPH_AUDIT_ERRORS+=("resource $rid has no display name")
  [[ -n "${RESOURCE_CATEGORY[$rid]:-}" ]] || GRAPH_AUDIT_ERRORS+=("resource $rid has no category")
  [[ -n "${RESOURCE_CLASS[$rid]:-}" ]] || GRAPH_AUDIT_ERRORS+=("resource $rid has no graph class")
done
for entry in "${RESOURCE_EDGES[@]}"; do
  resource_edge_parts "$entry"
  [[ -n "${RESOURCE_NAME[$RES_SRC]:-}" ]] || GRAPH_AUDIT_ERRORS+=("unknown resource endpoint $RES_SRC")
  [[ -n "${RESOURCE_NAME[$RES_DST]:-}" ]] || GRAPH_AUDIT_ERRORS+=("unknown resource endpoint $RES_DST")
  case "$RES_KIND" in setup|architecture) ;; *) GRAPH_AUDIT_ERRORS+=("bad edge kind '$RES_KIND' in $RES_SRC|$RES_DST") ;; esac
  pair="$RES_SRC|$RES_DST"
  if [[ -n "${EDGE_SEEN[$pair]+present}" ]]; then
    GRAPH_AUDIT_ERRORS+=("duplicate resource pair $pair")
  else
    EDGE_SEEN[$pair]=1
  fi
done
if (( ${#GRAPH_AUDIT_ERRORS[@]} > 0 )); then
  print -u2 -r -- "Graph model integrity errors:" 
  for x in "${GRAPH_AUDIT_ERRORS[@]}"; do print -u2 -r -- "  - $x"; done
  exit 1
fi


}
