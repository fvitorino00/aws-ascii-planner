aws_plan_graph_resources_init() {
  typeset -ga RESOURCE_IDS
  typeset -gA RESOURCE_NAME RESOURCE_OWNER RESOURCE_CATEGORY RESOURCE_CLASS
  typeset -g REQ_VPC REQ_SUBNET REQ_SG REQ_EC2 REQ_ROLE REQ_PROFILE REQ_DEDICATED_HOST REQ_LAMBDA_ROLE REQ_SAGE_ROLE REQ_BEDROCK_ROLE REQ_BATCH_ROLE REQ_PCS_ROLE REQ_PC_ROLE REQ_DEADLINE_HOST_ROLE REQ_DEADLINE_QUEUE_ROLE REQ_DEADLINE_FLEET_ROLE REQ_SSM REQ_LAMBDA REQ_S3 REQ_S3V REQ_S3EXP REQ_EBS REQ_FSX REQ_DCV REQ_EFA REQ_BATCH REQ_ECR REQ_DEADLINE REQ_PCS REQ_PC REQ_BEDROCK REQ_SAGE REQ_TRN REQ_INF REQ_BUDGET REQ_CW REQ_COSTEXP
RESOURCE_IDS=(
  VPC_RES SUBNET SG ROLE PROFILE LAMBDA_ROLE SAGE_ROLE BEDROCK_ROLE
  BATCH_ROLE PCS_ROLE PC_ROLE DEADLINE_HOST_ROLE DEADLINE_QUEUE_ROLE DEADLINE_FLEET_ROLE
  SSM_RES EC2_RES DEDICATED_HOST LAMBDAF
  S3B S3VB S3XB EBSV FSX S3EXP_EP
  DCVS
  PCSCL PCSNG PCSQ PCCL EFAI
  BATCHCE BATCHQ BATCHJD BATCH_JOB BATCH_IMG ECRR FARM DQUEUE FLEET
  BEDROCK_CFG BEDROCK_KB SMJOB TRNNODE INFNODE
  BUD CWLG CWMETRIC COST_VIEW
)
typeset -gA RESOURCE_NAME RESOURCE_OWNER RESOURCE_CATEGORY RESOURCE_CLASS

RESOURCE_NAME[VPC_RES]='VPC'; RESOURCE_OWNER[VPC_RES]='VPC'; RESOURCE_CATEGORY[VPC_RES]='security'; RESOURCE_CLASS[VPC_RES]='res_sec'
RESOURCE_NAME[SUBNET]='Subnet'; RESOURCE_OWNER[SUBNET]='VPC'; RESOURCE_CATEGORY[SUBNET]='security'; RESOURCE_CLASS[SUBNET]='res_sec'
RESOURCE_NAME[SG]='Security Group'; RESOURCE_OWNER[SG]='VPC'; RESOURCE_CATEGORY[SG]='security'; RESOURCE_CLASS[SG]='res_sec'
RESOURCE_NAME[ROLE]='EC2 workload IAM Role'; RESOURCE_OWNER[ROLE]='IAM'; RESOURCE_CATEGORY[ROLE]='security'; RESOURCE_CLASS[ROLE]='res_sec'
RESOURCE_NAME[PROFILE]='EC2 Instance Profile'; RESOURCE_OWNER[PROFILE]='IAM'; RESOURCE_CATEGORY[PROFILE]='security'; RESOURCE_CLASS[PROFILE]='res_sec'
RESOURCE_NAME[LAMBDA_ROLE]='Lambda execution IAM Role'; RESOURCE_OWNER[LAMBDA_ROLE]='IAM'; RESOURCE_CATEGORY[LAMBDA_ROLE]='security'; RESOURCE_CLASS[LAMBDA_ROLE]='res_sec'
RESOURCE_NAME[SAGE_ROLE]='SageMaker execution IAM Role'; RESOURCE_OWNER[SAGE_ROLE]='IAM'; RESOURCE_CATEGORY[SAGE_ROLE]='security'; RESOURCE_CLASS[SAGE_ROLE]='res_sec'
RESOURCE_NAME[BEDROCK_ROLE]='Bedrock Knowledge Base IAM Role'; RESOURCE_OWNER[BEDROCK_ROLE]='IAM'; RESOURCE_CATEGORY[BEDROCK_ROLE]='security'; RESOURCE_CLASS[BEDROCK_ROLE]='res_sec'
RESOURCE_NAME[BATCH_ROLE]='AWS Batch service/job IAM role'; RESOURCE_OWNER[BATCH_ROLE]='IAM'; RESOURCE_CATEGORY[BATCH_ROLE]='security'; RESOURCE_CLASS[BATCH_ROLE]='res_sec'
RESOURCE_NAME[PCS_ROLE]='PCS service-linked IAM role'; RESOURCE_OWNER[PCS_ROLE]='IAM'; RESOURCE_CATEGORY[PCS_ROLE]='security'; RESOURCE_CLASS[PCS_ROLE]='res_sec'
RESOURCE_NAME[PC_ROLE]='ParallelCluster IAM roles'; RESOURCE_OWNER[PC_ROLE]='IAM'; RESOURCE_CATEGORY[PC_ROLE]='security'; RESOURCE_CLASS[PC_ROLE]='res_sec'
RESOURCE_NAME[DEADLINE_HOST_ROLE]='Deadline worker-host IAM role'; RESOURCE_OWNER[DEADLINE_HOST_ROLE]='IAM'; RESOURCE_CATEGORY[DEADLINE_HOST_ROLE]='security'; RESOURCE_CLASS[DEADLINE_HOST_ROLE]='res_sec'
RESOURCE_NAME[DEADLINE_QUEUE_ROLE]='Deadline queue IAM role'; RESOURCE_OWNER[DEADLINE_QUEUE_ROLE]='IAM'; RESOURCE_CATEGORY[DEADLINE_QUEUE_ROLE]='security'; RESOURCE_CLASS[DEADLINE_QUEUE_ROLE]='res_sec'
RESOURCE_NAME[DEADLINE_FLEET_ROLE]='Deadline fleet IAM role'; RESOURCE_OWNER[DEADLINE_FLEET_ROLE]='IAM'; RESOURCE_CATEGORY[DEADLINE_FLEET_ROLE]='security'; RESOURCE_CLASS[DEADLINE_FLEET_ROLE]='res_sec'
RESOURCE_NAME[SSM_RES]='Systems Manager managed instance'; RESOURCE_OWNER[SSM_RES]='SSM'; RESOURCE_CATEGORY[SSM_RES]='security'; RESOURCE_CLASS[SSM_RES]='res_sec'

RESOURCE_NAME[EC2_RES]='EC2 capacity\n(type selected later)'; RESOURCE_OWNER[EC2_RES]='EC2'; RESOURCE_CATEGORY[EC2_RES]='compute'; RESOURCE_CLASS[EC2_RES]='res_compute'
RESOURCE_NAME[DEDICATED_HOST]='EC2 Mac Dedicated Host'; RESOURCE_OWNER[DEDICATED_HOST]='EC2'; RESOURCE_CATEGORY[DEDICATED_HOST]='compute'; RESOURCE_CLASS[DEDICATED_HOST]='res_compute'
RESOURCE_NAME[LAMBDAF]='Lambda Function'; RESOURCE_OWNER[LAMBDAF]='LAMBDA'; RESOURCE_CATEGORY[LAMBDAF]='compute'; RESOURCE_CLASS[LAMBDAF]='res_compute'

RESOURCE_NAME[S3B]='S3 Bucket'; RESOURCE_OWNER[S3B]='S3'; RESOURCE_CATEGORY[S3B]='storage'; RESOURCE_CLASS[S3B]='res_storage'
RESOURCE_NAME[S3VB]='S3 Vectors bucket'; RESOURCE_OWNER[S3VB]='S3'; RESOURCE_CATEGORY[S3VB]='storage'; RESOURCE_CLASS[S3VB]='res_storage'
RESOURCE_NAME[S3XB]='S3 Express directory bucket'; RESOURCE_OWNER[S3XB]='S3'; RESOURCE_CATEGORY[S3XB]='storage'; RESOURCE_CLASS[S3XB]='res_storage'
RESOURCE_NAME[EBSV]='EBS gp3 Volume'; RESOURCE_OWNER[EBSV]='EC2'; RESOURCE_CATEGORY[EBSV]='compute'; RESOURCE_CLASS[EBSV]='res_compute'
RESOURCE_NAME[FSX]='FSx for Lustre\nFile System'; RESOURCE_OWNER[FSX]='FSXLUSTRE'; RESOURCE_CATEGORY[FSX]='storage'; RESOURCE_CLASS[FSX]='res_storage'
RESOURCE_NAME[S3EXP_EP]='S3 Express VPC gateway endpoint'; RESOURCE_OWNER[S3EXP_EP]='VPC'; RESOURCE_CATEGORY[S3EXP_EP]='security'; RESOURCE_CLASS[S3EXP_EP]='res_sec'

RESOURCE_NAME[DCVS]='DCV Server Configuration'; RESOURCE_OWNER[DCVS]='DCV'; RESOURCE_CATEGORY[DCVS]='gui'; RESOURCE_CLASS[DCVS]='res_gui'

RESOURCE_NAME[PCSCL]='PCS Cluster'; RESOURCE_OWNER[PCSCL]='PCS'; RESOURCE_CATEGORY[PCSCL]='hpc'; RESOURCE_CLASS[PCSCL]='res_hpc'
RESOURCE_NAME[PCSNG]='PCS Compute Node Group'; RESOURCE_OWNER[PCSNG]='PCS'; RESOURCE_CATEGORY[PCSNG]='hpc'; RESOURCE_CLASS[PCSNG]='res_hpc'
RESOURCE_NAME[PCSQ]='PCS Queue'; RESOURCE_OWNER[PCSQ]='PCS'; RESOURCE_CATEGORY[PCSQ]='hpc'; RESOURCE_CLASS[PCSQ]='res_hpc'
RESOURCE_NAME[PCCL]='ParallelCluster'; RESOURCE_OWNER[PCCL]='PC'; RESOURCE_CATEGORY[PCCL]='hpc'; RESOURCE_CLASS[PCCL]='res_hpc'
RESOURCE_NAME[EFAI]='EFA Network Interface'; RESOURCE_OWNER[EFAI]='EC2'; RESOURCE_CATEGORY[EFAI]='compute'; RESOURCE_CLASS[EFAI]='res_compute'

RESOURCE_NAME[BATCHCE]='Batch Compute Environment'; RESOURCE_OWNER[BATCHCE]='BATCH'; RESOURCE_CATEGORY[BATCHCE]='pipeline'; RESOURCE_CLASS[BATCHCE]='res_pipe'
RESOURCE_NAME[BATCHQ]='Batch Job Queue'; RESOURCE_OWNER[BATCHQ]='BATCH'; RESOURCE_CATEGORY[BATCHQ]='pipeline'; RESOURCE_CLASS[BATCHQ]='res_pipe'
RESOURCE_NAME[BATCHJD]='Batch Job Definition'; RESOURCE_OWNER[BATCHJD]='BATCH'; RESOURCE_CATEGORY[BATCHJD]='pipeline'; RESOURCE_CLASS[BATCHJD]='res_pipe'
RESOURCE_NAME[BATCH_JOB]='AWS Batch Job'; RESOURCE_OWNER[BATCH_JOB]='BATCH'; RESOURCE_CATEGORY[BATCH_JOB]='pipeline'; RESOURCE_CLASS[BATCH_JOB]='res_pipe'
RESOURCE_NAME[BATCH_IMG]='Container Image Reference'; RESOURCE_OWNER[BATCH_IMG]='BATCH'; RESOURCE_CATEGORY[BATCH_IMG]='pipeline'; RESOURCE_CLASS[BATCH_IMG]='res_pipe'
RESOURCE_NAME[ECRR]='ECR Repository'; RESOURCE_OWNER[ECRR]='ECR'; RESOURCE_CATEGORY[ECRR]='pipeline'; RESOURCE_CLASS[ECRR]='res_pipe'
RESOURCE_NAME[FARM]='Deadline Farm'; RESOURCE_OWNER[FARM]='DEADLINE'; RESOURCE_CATEGORY[FARM]='pipeline'; RESOURCE_CLASS[FARM]='res_pipe'
RESOURCE_NAME[DQUEUE]='Deadline Queue'; RESOURCE_OWNER[DQUEUE]='DEADLINE'; RESOURCE_CATEGORY[DQUEUE]='pipeline'; RESOURCE_CLASS[DQUEUE]='res_pipe'
RESOURCE_NAME[FLEET]='Deadline Worker Fleet'; RESOURCE_OWNER[FLEET]='DEADLINE'; RESOURCE_CATEGORY[FLEET]='pipeline'; RESOURCE_CLASS[FLEET]='res_pipe'

RESOURCE_NAME[BEDROCK_CFG]='Bedrock model/API configuration'; RESOURCE_OWNER[BEDROCK_CFG]='BEDROCK'; RESOURCE_CATEGORY[BEDROCK_CFG]='ai'; RESOURCE_CLASS[BEDROCK_CFG]='res_ai'
RESOURCE_NAME[BEDROCK_KB]='Bedrock Knowledge Base'; RESOURCE_OWNER[BEDROCK_KB]='BEDROCK'; RESOURCE_CATEGORY[BEDROCK_KB]='ai'; RESOURCE_CLASS[BEDROCK_KB]='res_ai'
RESOURCE_NAME[SMJOB]='SageMaker Job / Endpoint'; RESOURCE_OWNER[SMJOB]='SAGE'; RESOURCE_CATEGORY[SMJOB]='ai'; RESOURCE_CLASS[SMJOB]='res_ai'
RESOURCE_NAME[TRNNODE]='Trainium Compute'; RESOURCE_OWNER[TRNNODE]='EC2'; RESOURCE_CATEGORY[TRNNODE]='compute'; RESOURCE_CLASS[TRNNODE]='res_compute'
RESOURCE_NAME[INFNODE]='Inferentia Compute'; RESOURCE_OWNER[INFNODE]='EC2'; RESOURCE_CATEGORY[INFNODE]='compute'; RESOURCE_CLASS[INFNODE]='res_compute'

RESOURCE_NAME[BUD]='AWS Budget'; RESOURCE_OWNER[BUD]='BUDGET'; RESOURCE_CATEGORY[BUD]='telemetry'; RESOURCE_CLASS[BUD]='res_telemetry'
RESOURCE_NAME[CWLG]='CloudWatch Log Group'; RESOURCE_OWNER[CWLG]='CW'; RESOURCE_CATEGORY[CWLG]='telemetry'; RESOURCE_CLASS[CWLG]='res_telemetry'
RESOURCE_NAME[CWMETRIC]='CloudWatch Metrics'; RESOURCE_OWNER[CWMETRIC]='CW'; RESOURCE_CATEGORY[CWMETRIC]='telemetry'; RESOURCE_CLASS[CWMETRIC]='res_telemetry'
RESOURCE_NAME[COST_VIEW]='Cost Explorer Spend View'; RESOURCE_OWNER[COST_VIEW]='COSTEXP'; RESOURCE_CATEGORY[COST_VIEW]='telemetry'; RESOURCE_CLASS[COST_VIEW]='res_telemetry'

if [[ "$MANAGED_ML" == true ]]; then
  RESOURCE_OWNER[TRNNODE]='SAGE'; RESOURCE_OWNER[INFNODE]='SAGE'
elif [[ "$MULTI_NODE" == true && "$MANAGED_SLURM" == true ]]; then
  RESOURCE_OWNER[TRNNODE]='PCS'; RESOURCE_OWNER[INFNODE]='PCS'
elif [[ "$MULTI_NODE" == true && "$SLURM" == true ]]; then
  RESOURCE_OWNER[TRNNODE]='PC'; RESOURCE_OWNER[INFNODE]='PC'
fi

for accelerator_id in TRNNODE INFNODE; do
  owner="${RESOURCE_OWNER[$accelerator_id]:-}"
  if [[ -n "$owner" ]]; then
    RESOURCE_CATEGORY[$accelerator_id]="${GRAPH_SERVICE_CATEGORY[$owner]}"
    case "${GRAPH_SERVICE_CLASS[$owner]}" in
      svc_compute) RESOURCE_CLASS[$accelerator_id]='res_compute' ;;
      svc_hpc) RESOURCE_CLASS[$accelerator_id]='res_hpc' ;;
      svc_ai) RESOURCE_CLASS[$accelerator_id]='res_ai' ;;
    esac
  fi
done

if [[ "$MAC_REQUIRED" == true ]]; then
  if [[ "$WORKLOAD" == "5" ]]; then
    RESOURCE_NAME[EC2_RES]='EC2 Mac worker instance(s)'
  elif [[ "$MULTI_NODE" == true ]]; then
    RESOURCE_NAME[EC2_RES]='EC2 Mac instance(s)'
  else
    RESOURCE_NAME[EC2_RES]='EC2 Mac Instance'
  fi
fi

purchase_mode='On-Demand'
contains SPOT "${SERVICES[@]}" && purchase_mode='Spot'
if contains BATCH "${SERVICES[@]}"; then
  RESOURCE_NAME[EC2_RES]="EC2 ${purchase_mode} worker instance(s)\nmanaged by Batch"
elif contains PCS "${SERVICES[@]}"; then
  RESOURCE_NAME[EC2_RES]="EC2 ${purchase_mode} compute node(s)\nmanaged by PCS"
elif contains PC "${SERVICES[@]}"; then
  RESOURCE_NAME[EC2_RES]="EC2 ${purchase_mode} cluster instance(s)\nmanaged by ParallelCluster"
elif contains DEADLINE "${SERVICES[@]}" && [[ "$MAC_REQUIRED" == true ]]; then
  RESOURCE_NAME[EC2_RES]='EC2 Mac worker instance(s)'
elif contains DEADLINE "${SERVICES[@]}"; then
  RESOURCE_NAME[EC2_RES]="EC2 ${purchase_mode} worker capacity\nmanaged by Deadline"
elif [[ "$MAC_REQUIRED" == false ]]; then
  if [[ "$COMPUTE" == "3" && "$MULTI_NODE" == false && "$MANAGED_ML" == false ]]; then
    accel="Trainium"
    [[ "$INFERENCE" == true ]] && accel="Inferentia"
    if [[ "$PREFER_SPOT" == true && "$INTERRUPTIBLE" == true ]]; then
      RESOURCE_NAME[EC2_RES]="EC2 Spot ${accel} Instance"
    else
      RESOURCE_NAME[EC2_RES]="EC2 ${accel} Instance"
    fi
  else
    case "$PREFER_SPOT:$INTERRUPTIBLE" in
      true:true) RESOURCE_NAME[EC2_RES]='EC2 Spot Instance\n(type selected later)' ;;
      *) RESOURCE_NAME[EC2_RES]='EC2 On-Demand Instance\n(type selected later)' ;;
    esac
  fi
fi

REQ_VPC=false; REQ_SUBNET=false; REQ_SG=false; REQ_EC2=false
REQ_ROLE=false; REQ_PROFILE=false; REQ_DEDICATED_HOST=false
REQ_LAMBDA_ROLE=false; REQ_SAGE_ROLE=false; REQ_BEDROCK_ROLE=false
REQ_BATCH_ROLE=false; REQ_PCS_ROLE=false; REQ_PC_ROLE=false; REQ_DEADLINE_HOST_ROLE=false; REQ_DEADLINE_QUEUE_ROLE=false; REQ_DEADLINE_FLEET_ROLE=false
REQ_SSM=false; REQ_LAMBDA=false; REQ_S3=false; REQ_S3V=false; REQ_S3EXP=false; REQ_EBS=false; REQ_FSX=false; REQ_DCV=false; REQ_EFA=false
REQ_BATCH=false; REQ_ECR=false; REQ_DEADLINE=false; REQ_PCS=false; REQ_PC=false; REQ_BEDROCK=false; REQ_SAGE=false; REQ_TRN=false; REQ_INF=false; REQ_BUDGET=false; REQ_CW=false; REQ_COSTEXP=false

contains VPC "${SERVICES[@]}" && REQ_VPC=true
if contains SPOT "${SERVICES[@]}" || contains OD "${SERVICES[@]}" || contains MACEC2 "${SERVICES[@]}" || contains BATCH "${SERVICES[@]}" || contains PCS "${SERVICES[@]}" || contains PC "${SERVICES[@]}" || contains DEADLINE "${SERVICES[@]}"; then
  REQ_EC2=true
fi
contains MACEC2 "${SERVICES[@]}" && REQ_EC2=true
contains S3 "${SERVICES[@]}" && REQ_S3=true
contains S3V "${SERVICES[@]}" && REQ_S3V=true
contains S3EXP "${SERVICES[@]}" && REQ_S3EXP=true
contains EBS "${SERVICES[@]}" && REQ_EBS=true
contains FSXLUSTRE "${SERVICES[@]}" && REQ_FSX=true
contains DCV "${SERVICES[@]}" && REQ_DCV=true
contains EFA "${SERVICES[@]}" && REQ_EFA=true
contains SSM "${SERVICES[@]}" && REQ_SSM=true
contains LAMBDA "${SERVICES[@]}" && REQ_LAMBDA=true
contains BATCH "${SERVICES[@]}" && REQ_BATCH=true
contains ECR "${SERVICES[@]}" && REQ_ECR=true
contains DEADLINE "${SERVICES[@]}" && REQ_DEADLINE=true
contains PCS "${SERVICES[@]}" && REQ_PCS=true
contains PC "${SERVICES[@]}" && REQ_PC=true
contains BEDROCK "${SERVICES[@]}" && REQ_BEDROCK=true
contains SAGE "${SERVICES[@]}" && REQ_SAGE=true
contains TRN "${SERVICES[@]}" && REQ_TRN=true
contains INF "${SERVICES[@]}" && REQ_INF=true
contains BUDGET "${SERVICES[@]}" && REQ_BUDGET=true
contains CW "${SERVICES[@]}" && REQ_CW=true
contains COSTEXP "${SERVICES[@]}" && REQ_COSTEXP=true

if [[ "$REQ_EC2" == true ]]; then
  REQ_SUBNET=true; REQ_SG=true
fi
if [[ "$MANAGED_ML" != true && ( "$REQ_FSX" == true || "$REQ_EFA" == true || "$REQ_BATCH" == true || "$REQ_PCS" == true || "$REQ_PC" == true ) ]]; then
  REQ_VPC=true
  REQ_SUBNET=true; REQ_SG=true
fi
if [[ "$MANAGED_ML" == true && "$REQ_EFA" == true ]]; then
  RESOURCE_OWNER[EFAI]='SAGE'
  RESOURCE_CATEGORY[EFAI]="${GRAPH_SERVICE_CATEGORY[SAGE]}"
  RESOURCE_CLASS[EFAI]='res_ai'
fi
if [[ "$REQ_EC2" == true && "$ORCHESTRATED" == false ]]; then
  REQ_ROLE=true; REQ_PROFILE=true
fi
if [[ "$REQ_EC2" == true && "$MAC_REQUIRED" == true ]]; then
  REQ_DEDICATED_HOST=true
fi
if [[ "$REQ_LAMBDA" == true ]]; then REQ_LAMBDA_ROLE=true; fi
if [[ "$REQ_SAGE" == true ]]; then REQ_SAGE_ROLE=true; fi
if [[ "$REQ_BEDROCK" == true && "$VECTOR_SEARCH" == true ]]; then REQ_BEDROCK_ROLE=true; fi
if [[ "$REQ_BATCH" == true ]]; then REQ_BATCH_ROLE=true; REQ_SUBNET=true; REQ_SG=true; fi
if [[ "$REQ_PCS" == true ]]; then REQ_PCS_ROLE=true; REQ_SUBNET=true; REQ_SG=true; fi
if [[ "$REQ_PC" == true ]]; then REQ_PC_ROLE=true; REQ_SUBNET=true; REQ_SG=true; fi
if [[ "$REQ_DEADLINE" == true ]]; then REQ_SUBNET=true; REQ_SG=true; REQ_DEADLINE_QUEUE_ROLE=true; REQ_DEADLINE_FLEET_ROLE=true; fi
if [[ "$REQ_DEADLINE" == true && "$REQ_EC2" == true ]]; then REQ_DEADLINE_HOST_ROLE=true; fi

is_graph_resource_emitted() {
  case "$1" in
    VPC_RES|SUBNET|SG) [[ "$REQ_VPC" == true && "$REQ_SUBNET" == true ]] || { [[ "$1" == VPC_RES && "$REQ_VPC" == true ]]; } ;;
    ROLE|PROFILE) [[ "$REQ_ROLE" == true ]] ;;
    LAMBDA_ROLE) [[ "$REQ_LAMBDA_ROLE" == true ]] ;;
    SAGE_ROLE) [[ "$REQ_SAGE_ROLE" == true ]] ;;
    BEDROCK_ROLE) [[ "$REQ_BEDROCK_ROLE" == true ]] ;;
    BATCH_ROLE) [[ "$REQ_BATCH_ROLE" == true ]] ;;
    PCS_ROLE) [[ "$REQ_PCS_ROLE" == true ]] ;;
    PC_ROLE) [[ "$REQ_PC_ROLE" == true ]] ;;
    DEADLINE_HOST_ROLE) [[ "$REQ_DEADLINE_HOST_ROLE" == true ]] ;;
    DEADLINE_QUEUE_ROLE) [[ "$REQ_DEADLINE_QUEUE_ROLE" == true ]] ;;
    DEADLINE_FLEET_ROLE) [[ "$REQ_DEADLINE_FLEET_ROLE" == true ]] ;;
    SSM_RES) [[ "$REQ_SSM" == true && "$REQ_EC2" == true && "$ORCHESTRATED" == false ]] ;;
    EC2_RES) [[ "$REQ_EC2" == true ]] ;;
    DEDICATED_HOST) [[ "$REQ_DEDICATED_HOST" == true ]] ;;
    LAMBDAF) [[ "$REQ_LAMBDA" == true ]] ;;
    S3B) [[ "$REQ_S3" == true ]] ;;
    S3VB) [[ "$REQ_S3V" == true ]] ;;
    S3XB) [[ "$REQ_S3EXP" == true ]] ;;
    EBSV) [[ "$REQ_EBS" == true && "$REQ_EC2" == true ]] ;;
    FSX) [[ "$REQ_FSX" == true ]] ;;
    S3EXP_EP) [[ "$REQ_S3EXP" == true && "$REQ_VPC" == true ]] ;;
    DCVS) [[ "$REQ_DCV" == true ]] ;;
    PCSCL|PCSNG|PCSQ) [[ "$REQ_PCS" == true ]] ;;
    PCCL) [[ "$REQ_PC" == true ]] ;;
    EFAI) [[ "$REQ_EFA" == true ]] ;;
    BATCHCE|BATCHQ|BATCHJD|BATCH_JOB|BATCH_IMG) [[ "$REQ_BATCH" == true ]] ;;
    ECRR) [[ "$REQ_ECR" == true ]] ;;
    FARM|DQUEUE|FLEET) [[ "$REQ_DEADLINE" == true ]] ;;
    BEDROCK_CFG) [[ "$REQ_BEDROCK" == true ]] ;;
    BEDROCK_KB) [[ "$REQ_BEDROCK" == true && "$VECTOR_SEARCH" == true ]] ;;
    SMJOB) [[ "$REQ_SAGE" == true ]] ;;
    TRNNODE)
      [[ "$REQ_TRN" == true ]] || return 1
      [[ "$MANAGED_ML" == false && "$MULTI_NODE" == false ]] && return 1
      return 0
      ;;
    INFNODE)
      [[ "$REQ_INF" == true ]] || return 1
      [[ "$MANAGED_ML" == false && "$MULTI_NODE" == false ]] && return 1
      return 0
      ;;
    BUD) [[ "$REQ_BUDGET" == true ]] ;;
    CWLG) [[ "$REQ_CW" == true ]] ;;
    CWMETRIC) [[ "$REQ_CW" == true && "$REQ_EC2" == true ]] ;;
    COST_VIEW) [[ "$REQ_COSTEXP" == true ]] ;;
    *) print -u2 -r -- "Unknown graph resource ID: $1"; return 1 ;;
  esac
}


}
