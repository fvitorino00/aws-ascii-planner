aws_plan_report() {
say
hr
say "${B}${G}RECOMMENDED ARCHITECTURE${R}"
hr

say "${B}Workload:${R}"
case "$WORKLOAD" in
  1) say "  One-off / manually launched heavy computation" ;;
  2) say "  Many repeated independent jobs" ;;
  3) say "  Containerized pipeline" ;;
  4) say "  Interactive GUI / 3D workstation" ;;
  5) say "  3D render farm" ;;
  6) say "  Distributed HPC / multi-node calculation" ;;
  7) say "  ML training / self-hosted inference" ;;
  8) say "  Managed foundation-model API" ;;
  9) say "  Lightweight event-driven serverless task" ;;
esac

say "${B}Execution model:${R}"
case "$EXECUTION_MODE" in
  MANAGED_API) say "  Managed API" ;;
  SERVERLESS) say "  Serverless function" ;;
  MANAGED_ML) say "  Managed SageMaker AI" ;;
  DEADLINE) say "  Deadline Cloud render farm" ;;
  BATCH) say "  Queued/scaled batch execution" ;;
  MULTI_NODE_PCS) say "  Multi-node compute — AWS PCS / managed Slurm" ;;
  MULTI_NODE_PARALLELCLUSTER) say "  Multi-node compute — ParallelCluster / Slurm" ;;
  MULTI_NODE_DIRECT) say "  Multi-machine compute without Slurm" ;;
  EC2_MAC) say "  EC2 Mac / Dedicated Host" ;;
  INTERACTIVE_EC2) say "  Remote interactive EC2 workstation" ;;
  *) say "  Single EC2 machine" ;;
esac

print_ram() {
  case "$RAM" in
    small) say "  RAM: Up to ~16 GiB" ;;
    medium) say "  RAM: ~16–64 GiB" ;;
    large) say "  RAM: ~64–256 GiB" ;;
    xlarge) say "  RAM: More than ~256 GiB" ;;
  esac
}
print_vram() {
  case "$VRAM" in
    1) say "  GPU VRAM: Up to ~16 GiB" ;;
    2) say "  GPU VRAM: ~16–48 GiB" ;;
    3) say "  GPU VRAM: ~48–96 GiB" ;;
    4) say "  GPU VRAM: More than ~96 GiB" ;;
  esac
}
print_gpu_kind() {
  [[ "$COMPUTE" == "2" ]] || return 0
  case "$GPU_KIND" in
    1) say "  GPU workload: Interactive graphics / visualization" ;;
    2) say "  GPU workload: ML training / CUDA compute" ;;
    3) say "  GPU workload: ML inference / serving" ;;
    4) say "  GPU workload: High-VRAM workload / exact GPU family to be sized" ;;
  esac
}

say "${B}Compute profile:${R}"
if [[ "$BEDROCK_API" == true || "$WORKLOAD" == "9" ]]; then
  say "  No general-purpose EC2 compute required by the primary workload"
elif [[ "$MANAGED_ML" == true ]]; then
  say "  Managed SageMaker AI compute"
  case "$COMPUTE" in
    1) say "  Compute: CPU" ;;
    2) say "  Compute: GPU" ;;
    3)
      if [[ "$TRAINING" == true ]]; then say "  Compute: Trainium / Neuron"; elif [[ "$INFERENCE" == true ]]; then say "  Compute: Inferentia / Neuron"; else say "  Compute: AWS ML accelerator"; fi
      ;;
  esac
  print_ram
  print_vram
  print_gpu_kind
  [[ "$MANAGED_SPOT_TRAINING" == true ]] && say "  Capacity mode: SageMaker Managed Spot Training"
else
  case "$COMPUTE" in
    1) say "  CPU" ;;
    2) say "  GPU" ;;
    3) say "  AWS accelerator" ;;
  esac
  print_ram
  print_vram
  print_gpu_kind
fi
say "${B}Configured AWS CLI Region:${R} $REGION"


print
say "${B}${G}Services to use${R}"
for s in "${SERVICES[@]}"; do say "  ${G}✓${R} ${SERVICE_NAME[$s]}"; done

if (( ${#GUIDANCE[@]} > 0 )); then
  print
  say "${B}${C}Compute sizing guidance${R}"
  for x in "${GUIDANCE[@]}"; do say "  • $x"; done
fi

if (( ${#REASONS[@]} > 0 )); then
  print
  say "${B}${C}Why they appeared${R}"
  for x in "${REASONS[@]}"; do say "  • $x"; done
fi

if (( ${#OPTIONAL[@]} > 0 )); then
  print
  say "${B}${Y}Optional / add later${R}"
  for x in "${OPTIONAL[@]}"; do say "  ○ $x"; done
fi

if (( ${#AVOID[@]} > 0 )); then
  print
  say "${B}${M}Do not add unless the workload changes${R}"
  for x in "${AVOID[@]}"; do say "  – $x"; done
fi

print
hr
say "${B}Operational guardrails${R}"
if contains SPOT "${SERVICES[@]}"; then
  say "  • Spot requires restart/checkpoint design; interruption does not automatically resume arbitrary processes."
  if [[ "$TIGHTLY_COUPLED" == true ]]; then
    say "  • Tightly coupled multi-node jobs on Spot lose the whole run if any one node is interrupted; consider On-Demand for the coupled part."
  fi
elif contains SAGE "${SERVICES[@]}" && [[ "$PREFER_SPOT" == true && "$TRAINING" == true ]]; then
  say "  • SageMaker Managed Spot Training can interrupt training jobs; use checkpointing for recoverability."
fi
if contains SPOT "${SERVICES[@]}" || contains OD "${SERVICES[@]}" || contains MACEC2 "${SERVICES[@]}"; then
  say "  • Compute can continue to incur charges while it is running. Include a stop time or automatic shutdown in the operating plan."
fi
if contains MACEC2 "${SERVICES[@]}"; then
  say "  • EC2 Mac runs on Dedicated Hosts with a minimum allocation period (24 hours at the time of writing); you pay for the host, not just the instance."
fi
if contains BUDGET "${SERVICES[@]}"; then
  say "  • AWS Budgets sends alerts; it does not cap or stop spending on its own unless you attach budget actions."
fi
if contains SSM "${SERVICES[@]}"; then
  say "  • Session Manager needs an instance profile with AmazonSSMManagedInstanceCore and either outbound internet (public IP/NAT) or SSM VPC endpoints. If you build a custom private VPC, NAT gateways bill hourly."
fi
if contains S3 "${SERVICES[@]}"; then
  say "  • S3 is the durable boundary; keep disposable compute separate from durable inputs/results/checkpoints."
fi
if contains S3EXP "${SERVICES[@]}"; then
  say "  • S3 Express One Zone is single-AZ; run compute in the same Availability Zone as the directory bucket."
fi
if contains FSXLUSTRE "${SERVICES[@]}"; then
  say "  • FSx for Lustre scratch filesystems are not replicated; keep irreplaceable outputs in S3 or another persistent store."
fi
if contains EFA "${SERVICES[@]}"; then
  say "  • EFA works only on supported instance types and performs best in a cluster placement group in a single Availability Zone."
fi
if contains DCV "${SERVICES[@]}"; then
  say "  • DCV is the remote-display layer; the underlying EC2 machine still supplies CPU/GPU compute."
fi
if contains BATCH "${SERVICES[@]}" || contains DEADLINE "${SERVICES[@]}" || contains PCS "${SERVICES[@]}" || contains PC "${SERVICES[@]}" || contains FSXLUSTRE "${SERVICES[@]}"; then
  say "  • Queueing/cluster/filesystem services add complexity; use them because this workload requires them, not merely because they are available."
fi
say "  • Check current instance types, pricing, regional availability, quotas, and service limits before implementing the plan."
hr


}
