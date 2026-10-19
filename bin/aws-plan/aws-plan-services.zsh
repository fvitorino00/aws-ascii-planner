aws_plan_services_init() {
  typeset -ga SERVICE_IDS
  typeset -gA SERVICE_NAME SERVICE_CATEGORY SERVICE_CLASS
SERVICE_IDS=(IAM VPC SSM SPOT OD MACEC2 LAMBDA S3 EBS S3V FSXLUSTRE S3EXP DCV PCS PC EFA BATCH ECR DEADLINE BEDROCK SAGE TRN INF BUDGET COSTEXP CW)
typeset -gA SERVICE_NAME SERVICE_CATEGORY SERVICE_CLASS

SERVICE_NAME[IAM]="AWS IAM"
SERVICE_NAME[VPC]="AWS VPC"
SERVICE_NAME[SSM]="AWS Systems Manager Session Manager"
SERVICE_NAME[SPOT]="EC2 Spot Instances"
SERVICE_NAME[OD]="EC2 On-Demand Instances"
SERVICE_NAME[MACEC2]="EC2 Mac Instances"
SERVICE_NAME[LAMBDA]="AWS Lambda"
SERVICE_NAME[S3]="Amazon S3"
SERVICE_NAME[EBS]="Amazon EBS gp3"
SERVICE_NAME[S3V]="Amazon S3 Vectors"
SERVICE_NAME[FSXLUSTRE]="Amazon FSx for Lustre"
SERVICE_NAME[S3EXP]="S3 Express One Zone"
SERVICE_NAME[DCV]="Amazon DCV"
SERVICE_NAME[PCS]="AWS Parallel Computing Service (PCS)"
SERVICE_NAME[PC]="AWS ParallelCluster"
SERVICE_NAME[EFA]="Elastic Fabric Adapter (EFA)"
SERVICE_NAME[BATCH]="AWS Batch"
SERVICE_NAME[ECR]="Amazon ECR"
SERVICE_NAME[DEADLINE]="AWS Deadline Cloud"
SERVICE_NAME[BEDROCK]="Amazon Bedrock"
SERVICE_NAME[SAGE]="Amazon SageMaker AI"
SERVICE_NAME[TRN]="AWS Trainium / Neuron"
SERVICE_NAME[INF]="AWS Inferentia / Neuron"
SERVICE_NAME[BUDGET]="AWS Budgets"
SERVICE_NAME[COSTEXP]="AWS Cost Explorer"
SERVICE_NAME[CW]="Amazon CloudWatch"

for id in "${SERVICE_IDS[@]}"; do SERVICE_CLASS[$id]='svc_sec'; SERVICE_CATEGORY[$id]='security'; done
for id in SPOT OD MACEC2 LAMBDA; do SERVICE_CLASS[$id]='svc_compute'; SERVICE_CATEGORY[$id]='compute'; done
for id in S3 EBS S3V FSXLUSTRE S3EXP; do SERVICE_CLASS[$id]='svc_storage'; SERVICE_CATEGORY[$id]='storage'; done
SERVICE_CLASS[DCV]='svc_gui'; SERVICE_CATEGORY[DCV]='gui'
for id in PCS PC EFA; do SERVICE_CLASS[$id]='svc_hpc'; SERVICE_CATEGORY[$id]='hpc'; done
for id in BATCH ECR DEADLINE; do SERVICE_CLASS[$id]='svc_pipe'; SERVICE_CATEGORY[$id]='pipeline'; done
for id in BEDROCK SAGE TRN INF; do SERVICE_CLASS[$id]='svc_ai'; SERVICE_CATEGORY[$id]='ai'; done
for id in BUDGET COSTEXP CW; do SERVICE_CLASS[$id]='svc_telemetry'; SERVICE_CATEGORY[$id]='telemetry'; done

add_service() {
  local id="$1"
  [[ -n "${SERVICE_NAME[$id]:-}" ]] || { print -u2 -r -- "Unknown service ID: $id"; return 1; }
  contains "$id" "${SERVICES[@]}" || SERVICES+=("$id")
}

add_optional() { OPTIONAL+=("$1"); }
add_avoid()    { AVOID+=("$1"); }
add_reason()   { REASONS+=("$1"); }

ask_managed_model_options() {
  if ask_yes_no \
    "Do you need event-driven glue around the model call?" \
    "Choose yes if an upload should trigger a short function that validates or transforms a file and then calls the model. Choose no if the application calls the model API directly and needs no event-driven processing; Lambda is orchestration glue, not the model itself."; then
    EVENT_DRIVEN=true
    add_service LAMBDA
    add_reason "Lambda is selected as the event-driven glue around the managed model call."
  fi

  ask_yes_no \
    "Will the model workflow read or write files in S3?" \
    "Choose yes if the model workflow needs durable documents, images, datasets, or generated files—for example a document assistant that retrieves source PDFs from S3. Choose no if the call only sends text and returns a response that the caller handles elsewhere." && PERSISTENT_DATA=true

  if [[ "$EVENT_DRIVEN" == true ]]; then
    ask_yes_no \
      "Should an object arriving in S3 invoke the function?" \
      "Choose yes if each new S3 object should start the function, such as processing a newly uploaded invoice. Choose no if a user request or schedule starts the function and it only reads or writes S3 as storage." && S3_EVENT_SOURCE=true
    [[ "$S3_EVENT_SOURCE" == true ]] && PERSISTENT_DATA=true
  fi
}



}
