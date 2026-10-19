aws_plan_derive() {
  typeset -ga GUIDANCE
HAS_COMPUTE_PATH=true
if [[ "$WORKLOAD" == "8" || "$WORKLOAD" == "9" || "$BEDROCK_API" == true ]]; then
  HAS_COMPUTE_PATH=false
fi

ORCHESTRATED=false
if [[ "$HAS_COMPUTE_PATH" == true && "$MANAGED_ML" == false && "$MAC_REQUIRED" == false ]]; then
  if [[ "$MANY_INDEPENDENT" == true ]]; then
    ORCHESTRATED=true
  elif [[ "$MULTI_NODE" == true && "$SLURM" == true ]]; then
    ORCHESTRATED=true
  fi
fi

EXECUTION_MODE="DIRECT_EC2"
if [[ "$BEDROCK_API" == true ]]; then
  EXECUTION_MODE="MANAGED_API"
elif [[ "$WORKLOAD" == "9" ]]; then
  EXECUTION_MODE="SERVERLESS"
elif [[ "$MANAGED_ML" == true ]]; then
  EXECUTION_MODE="MANAGED_ML"
elif [[ "$WORKLOAD" == "5" && "$MANY_INDEPENDENT" == true ]]; then
  EXECUTION_MODE="DEADLINE"
elif [[ "$MANY_INDEPENDENT" == true && "$MAC_REQUIRED" == false ]]; then
  EXECUTION_MODE="BATCH"
elif [[ "$MULTI_NODE" == true && "$MANAGED_SLURM" == true ]]; then
  EXECUTION_MODE="MULTI_NODE_PCS"
elif [[ "$MULTI_NODE" == true && "$SLURM" == true ]]; then
  EXECUTION_MODE="MULTI_NODE_PARALLELCLUSTER"
elif [[ "$MULTI_NODE" == true ]]; then
  EXECUTION_MODE="MULTI_NODE_DIRECT"
elif [[ "$MAC_REQUIRED" == true ]]; then
  EXECUTION_MODE="EC2_MAC"
elif [[ "$INTERACTIVE" == true ]]; then
  EXECUTION_MODE="INTERACTIVE_EC2"
fi

if [[ "$PERSISTENT_DATA" == true ]]; then
  add_service S3
  if [[ "$MANAGED_ML" == true ]]; then
    add_reason "S3 is selected for durable data used by the managed ML workflow."
  elif [[ "$MAC_REQUIRED" == true ]]; then
    add_reason "S3 is selected for durable data; on an EC2 Mac host, access should use the AWS CLI/SDK or another supported client rather than the Linux Mountpoint for S3 client."
  else
    add_reason "S3 separates durable inputs/results/checkpoints from disposable compute, which makes replacement of cloud machines much safer."
  fi

  ask_yes_no \
    "Do you need vector similarity search as an application data layer?" \
    "Choose yes if users ask questions in natural language and the application must retrieve semantically similar document passages, as in a retrieval-augmented assistant. Choose no for ordinary file downloads, keyword search, or a workflow that only sends a prompt to a model; those do not need a vector store." && VECTOR_SEARCH=true

  ask_yes_no \
    "Do you have a measured object-access latency bottleneck that justifies specialized low-latency S3?" \
    "Choose yes only if measurements show ordinary S3 request latency is a real bottleneck—for example, an interactive application repeatedly loads many small objects and needs lower latency. Choose no for backups, bulk datasets, or workloads where you have not measured an S3 latency problem; S3 Express is specialized and single-AZ." && EXTREME_OBJECT_IO=true
fi

if [[ "$MULTI_NODE" == true && "$MAC_REQUIRED" == false ]]; then
  ask_yes_no \
    "Do multiple compute nodes need a shared high-performance POSIX filesystem?" \
    "Choose yes if multiple training or simulation nodes must read and write the same files at high throughput during a tightly coupled run; that can justify FSx for Lustre. Choose no for one machine, independent jobs, or ordinary shared files; if you only need a simple shared directory, EFS is usually a better fit." && SHARED_POSIX=true
fi

if [[ "$HAS_COMPUTE_PATH" == true && "$MANAGED_ML" != true ]]; then
  if [[ "$MAC_REQUIRED" == true ]]; then
    add_service MACEC2
    if [[ "$WORKLOAD" == "5" ]]; then
      add_reason "macOS render workers are EC2 Mac capacity attached to the Deadline Cloud fleet."
    else
      add_reason "macOS is a hard runtime requirement for this direct-compute path, so a Mac-specific EC2 host is required."
    fi
  elif [[ "$ORCHESTRATED" == true ]]; then
    add_reason "EC2 capacity is launched and scaled by the queue/scheduler service below, so you do not manage a standalone instance."
  else
    add_reason "EC2 is the default elastic cloud computer for a solo workload because it gives direct control without imposing a larger orchestration layer."
  fi

  if [[ "$MAC_REQUIRED" == true ]]; then
    add_avoid "EC2 Spot for this Mac EC2 path"
  elif [[ "$INTERRUPTIBLE" == true && "$PREFER_SPOT" == true ]]; then
    add_service SPOT
    add_reason "The workload is restartable and you explicitly preferred Spot when it is safe."
  else
    add_service OD
    if [[ "$INTERRUPTIBLE" == false ]]; then
      add_reason "The workload is not safely interruptible, so On-Demand avoids adding interruption/restart complexity."
    else
      add_reason "The workload is interruptible, but you explicitly preferred On-Demand over Spot."
    fi
  fi

  if [[ "$ORCHESTRATED" == false ]]; then
    add_service SSM
    add_reason "Session Manager provides a remote shell for the EC2 instance without making an exposed SSH server the default access path."
  else
    add_optional "Session Manager — only needed if you later want a shell on individual worker instances; the orchestration service normally manages them for you."
  fi
  add_service VPC
fi

if [[ "$MANAGED_ML" == true && "$MULTI_NODE" == true && "$TIGHTLY_COUPLED" == true ]]; then
  add_service EFA
  add_reason "The managed SageMaker workload is multi-node and tightly coupled, so EFA is enabled for supported distributed training."
fi

if [[ "$MANAGED_ML" == true ]]; then
  add_service SAGE
  if [[ "$PREFER_SPOT" == true && "$TRAINING" == true ]]; then
    MANAGED_SPOT_TRAINING=true
    add_reason "You preferred interruptible capacity for managed ML training, so SageMaker Managed Spot Training is the execution mode."
  else
    add_reason "You explicitly requested managed ML infrastructure rather than the minimal EC2 path."
  fi
fi

add_service IAM
add_service BUDGET

if [[ "$HAS_COMPUTE_PATH" == true ]] && ! contains EBS "${SERVICES[@]}"; then
  add_optional "EBS gp3 — use/size an attached working volume according to the actual working set and block-I/O needs."
fi

if [[ "$INTERACTIVE" == true && "$MANAGED_ML" == false ]]; then
  add_service DCV
  if [[ "$MAC_REQUIRED" == true ]]; then
    add_reason "The workload needs a remote graphical session on an Apple silicon EC2 Mac; Amazon DCV Server supports macOS on Apple silicon EC2 Mac instances."
  else
    add_reason "The workload needs a remote graphical session; DCV is the display/interaction layer, not the underlying compute."
  fi
elif [[ "$HAS_COMPUTE_PATH" == true ]]; then
  add_avoid "Amazon DCV for headless workloads unless interactive access later becomes necessary"
fi

if [[ "$MANY_INDEPENDENT" == true && "$MANAGED_ML" == false && "$BEDROCK_API" == false ]]; then
  if [[ "$WORKLOAD" == "5" ]]; then
    add_service DEADLINE
    if [[ "$MAC_REQUIRED" == true ]]; then
      add_reason "The render workload requires macOS, and Deadline Cloud can use macOS customer-managed worker fleets."
    fi
    add_reason "Independent render frames/tasks are a render-farm workload, so a managed render-farm layer can replace manual worker management."
  elif [[ "$MAC_REQUIRED" == false ]]; then
    add_service BATCH
    BATCH_IMAGE_REQUIRED=true
    add_reason "There are enough independent jobs for queues and automatic compute scaling to save manual EC2 management."
  else
    add_avoid "AWS Batch is not selected for macOS workloads; use a compatible execution path such as direct Mac compute or Deadline Cloud for render-farm workloads."
  fi
elif [[ "$HAS_COMPUTE_PATH" == true && "$MANAGED_ML" != true ]]; then
  if [[ "$WORKLOAD" != "5" ]]; then
    add_avoid "AWS Batch unless independent-job volume makes manual execution cumbersome"
    add_avoid "Deadline Cloud unless you actually need a multi-worker render farm"
  fi
fi

if [[ "$CONTAINERIZED" == true && "$MANY_INDEPENDENT" == false ]]; then
  add_optional "Docker on EC2 — useful when reproducibility/portability matters without requiring AWS Batch."
fi

if [[ "$MULTI_NODE" == true && "$MAC_REQUIRED" == false && "$MANAGED_ML" == false && "$BEDROCK_API" == false ]]; then
  if [[ "$SLURM" == true ]]; then
    if [[ "$MANAGED_SLURM" == true ]]; then
      add_service PCS
      add_reason "You explicitly selected AWS-managed Slurm control for the multi-node workload."
    else
      add_service PC
      add_reason "You explicitly selected CLI-driven Slurm cluster lifecycle management."
    fi
  else
    add_optional "Multiple EC2 instances with application-managed workers — suitable when a workload spans machines but does not need Slurm."
    add_avoid "PCS / ParallelCluster unless you actually need a scheduler and cluster lifecycle layer"
  fi

  if [[ "$TIGHTLY_COUPLED" == true ]]; then
    add_service EFA
    add_reason "The nodes are tightly coupled, making specialized low-latency/high-throughput interconnect potentially relevant."
  else
    add_avoid "EFA for independent jobs that do not need tight inter-node communication"
  fi
else
  if [[ "$HAS_COMPUTE_PATH" == true && "$MANAGED_ML" != true ]]; then
    if [[ "$MAC_REQUIRED" == true ]]; then
      if [[ "$MULTI_NODE" == true ]]; then
        add_optional "Multiple EC2 Mac worker instances + application-specific coordination — this planner does not impose a Linux HPC scheduler on macOS."
      else
        add_avoid "PCS / ParallelCluster / EFA / FSx for Lustre are not selected for the macOS execution path"
      fi
    else
      add_avoid "AWS PCS / ParallelCluster for single-machine work"
      add_avoid "EFA for single-node or embarrassingly parallel work"
    fi
  fi
fi

if [[ "$COMPUTE" == "3" ]]; then
  if [[ "$TRAINING" == true ]]; then
    add_service TRN
    add_reason "You explicitly selected an AWS training accelerator; verify framework/model compatibility with the current Neuron stack before committing to it."
  elif [[ "$INFERENCE" == true ]]; then
    add_service INF
    add_reason "You explicitly selected an AWS inference accelerator; verify framework/model compatibility with the current Neuron stack before committing to it."
  fi
else
  if [[ "$WORKLOAD" == "7" && "$MANAGED_ML" == false ]]; then
    add_avoid "Trainium / Inferentia unless the model and software stack specifically justify AWS Neuron accelerators"
  elif [[ "$HAS_COMPUTE_PATH" == true && "$WORKLOAD" != "7" ]]; then
    add_avoid "Trainium / Inferentia unless the model and software stack specifically justify AWS Neuron accelerators"
  fi
fi

if [[ "$MANAGED_ML" == false && "$WORKLOAD" == "7" ]]; then
  add_avoid "SageMaker AI unless its managed ML features are the reason you need it"
fi

if [[ "$VECTOR_SEARCH" == true ]]; then
  add_service S3V
  add_reason "You explicitly need vector storage/querying; this is a specialized vector data capability rather than a generic S3 switch."
fi

if [[ "$EXTREME_OBJECT_IO" == true ]]; then
  add_service S3EXP
  add_reason "You identified object-access latency as a real bottleneck and explicitly accepted a specialized single-AZ storage option."
else
  if [[ "$HAS_COMPUTE_PATH" == true ]]; then
    add_avoid "S3 Express One Zone unless ordinary S3 performance is demonstrated to be a bottleneck"
  fi
fi

if [[ "$SHARED_POSIX" == true && "$MAC_REQUIRED" == false ]]; then
  add_service FSXLUSTRE
  add_reason "You explicitly need a shared high-performance POSIX filesystem across compute nodes."
else
  if [[ "$HAS_COMPUTE_PATH" == true ]]; then
    add_avoid "FSx for Lustre unless a shared high-performance filesystem is actually required"
  fi
  if [[ "$MULTI_NODE" == true && "$MAC_REQUIRED" == false && "$MANAGED_ML" == false ]]; then
    add_optional "Amazon EFS — a simpler shared POSIX directory across nodes when you do not need Lustre-class throughput."
  fi
fi

if [[ "$HAS_COMPUTE_PATH" == true && "$MANAGED_ML" == false ]]; then
  if [[ "$ORCHESTRATED" == false && "$MAC_REQUIRED" == false ]]; then
    add_optional "Instance-store NVMe — on instance families that include it, free local scratch that is often faster than an extra EBS volume; data is lost on stop/terminate, so keep anything durable in S3."
  fi
  if [[ "$COMPUTE" == "2" && "$GPU_KIND" != "1" && "$MAC_REQUIRED" == false ]]; then
    add_optional "AWS Deep Learning AMI — preinstalled NVIDIA drivers, CUDA, and common frameworks; usually the quickest route to a working GPU ML instance."
  elif [[ "$COMPUTE" == "3" ]]; then
    add_optional "AWS Neuron Deep Learning AMI / containers — preinstalled Neuron SDK for Trainium/Inferentia instances."
  fi
fi
if contains VPC "${SERVICES[@]}" && [[ "$ORCHESTRATED" == false ]]; then
  add_optional "Default VPC — for a solo workload you can usually launch into the account's default VPC/subnet instead of creating a custom network."
fi

IMAGE_REGISTRY_RELEVANT=false
if [[ "$BATCH_IMAGE_REQUIRED" == true || "$CONTAINERIZED" == true || "$MANAGED_ML" == true || "$EVENT_DRIVEN" == true ]]; then
  IMAGE_REGISTRY_RELEVANT=true
fi
if [[ "$IMAGE_REGISTRY_RELEVANT" == true ]]; then
  if [[ "$EVENT_DRIVEN" == true && "$BATCH_IMAGE_REQUIRED" == false && "$MANAGED_ML" == false && "$CONTAINERIZED" == false ]]; then
    if ask_yes_no \
      "Do you want to package the Lambda function as a container image stored in Amazon ECR?" \
      "Choose yes if the function has native libraries, a large dependency stack, or an existing container build that you want to reuse for Lambda. Choose no for a small handler that fits the normal ZIP deployment model; Lambda does not require an image."; then
      add_service ECR
      add_reason "The Lambda function will use a container image stored in Amazon ECR."
    fi
  else
    if ask_yes_no \
      "Do you want Amazon ECR as the private container-image registry?" \
      "Choose yes if you want AWS's private registry integrated with Batch, Lambda container images, or SageMaker custom images. Choose no if your organization already publishes images to another supported registry and you want to keep using it."; then
      add_service ECR
      add_reason "Amazon ECR was explicitly selected as the private container-image registry."
    else
      add_optional "A container image registry is still required by this path; use another supported image source instead of ECR."
    fi
  fi
fi

if [[ "$HAS_COMPUTE_PATH" == true || "$EVENT_DRIVEN" == true || "$MANAGED_ML" == true || "$MANY_INDEPENDENT" == true || "$MULTI_NODE" == true ]]; then
  add_service CW
else
  add_optional "Amazon CloudWatch — useful when you want centralized logs/metrics beyond the terminal."
fi
add_optional "AWS Cost Explorer — useful for reviewing actual spend after jobs run."
if ask_yes_no \
  "Would you like an AWS Cost Explorer view for reviewing spend after jobs run?" \
  "Choose yes if you want to inspect actual service and usage charges after workloads run, for example comparing GPU or storage spend by month. Choose no if you do not need those reports; Cost Explorer does not stop spending or replace an AWS Budget alert."; then
  add_service COSTEXP
  add_reason "You asked for a Cost Explorer view to review actual spend after jobs run."
fi

GUIDANCE=()

if [[ "$MANAGED_ML" == true ]]; then
  case "$COMPUTE" in
    1) GUIDANCE+=("SageMaker CPU workload: size the managed ML instance family from RAM, vCPU, and workload throughput requirements.") ;;
    2) GUIDANCE+=("SageMaker GPU workload: select a current supported GPU-backed ML instance from the required VRAM and framework requirements.") ;;
    3)
      if [[ "$TRAINING" == true ]]; then
        GUIDANCE+=("SageMaker Trainium training: verify current Neuron/framework support, quotas, and supported training instance types.")
      elif [[ "$INFERENCE" == true ]]; then
        GUIDANCE+=("SageMaker Inferentia inference: verify current Neuron/framework support, endpoint compatibility, quotas, and supported inference instance types.")
      fi
      ;;
  esac
  [[ "$MANAGED_SPOT_TRAINING" == true ]] && GUIDANCE+=("Managed Spot Training requires checkpointing/recoverability because training jobs can be interrupted.")
elif [[ "$HAS_COMPUTE_PATH" == true ]]; then
  if [[ "$MAC_REQUIRED" == true ]]; then
    GUIDANCE+=("Use an EC2 Mac instance only when the software truly requires macOS; verify current Mac-instance availability and Dedicated Host economics in the chosen Region.")
  elif [[ "$COMPUTE" == "1" ]]; then
    if [[ "$RAM" == "large" || "$RAM" == "xlarge" ]]; then
      GUIDANCE+=("CPU + large RAM: begin instance selection from memory capacity, then check vCPU and I/O requirements.")
    else
      GUIDANCE+=("CPU: start with general-purpose EC2; move toward compute-optimized when CPU throughput dominates the workload.")
    fi
  elif [[ "$COMPUTE" == "2" ]]; then
    if [[ "$GPU_KIND" == "1" ]]; then
      GUIDANCE+=("GPU graphics: select an EC2 GPU family intended for visualization/graphics and size CPU/RAM/GPU count to the application.")
    else
      GUIDANCE+=("GPU ML: select a GPU family compatible with the framework/CUDA stack; size primarily from VRAM and throughput requirements.")
    fi
    [[ "$VRAM" == "3" || "$VRAM" == "4" ]] && GUIDANCE+=("High VRAM: choose the exact GPU SKU from the current regional catalog rather than hard-coding an instance family in this planner.")
  elif [[ "$COMPUTE" == "3" ]]; then
    GUIDANCE+=("AWS accelerator: select a current Trainium/Inferentia instance supported by the model and current Neuron software; verify quotas and regional availability.")
  fi
fi


}
