aws_plan_collect_questions() {
ask_choice \
  "What are you primarily trying to offload from this computer?" "1" \
  "1|One-off / manually launched heavy computation" \
  "2|Many repeated independent jobs" \
  "3|Containerized pipeline (Snakemake / Nextflow / Docker)" \
  "4|Interactive GUI / 3D workstation (Blender / Houdini / etc.)" \
  "5|3D render farm / many independent frames or tasks" \
  "6|Distributed HPC / multi-node calculation" \
  "7|ML training or self-hosted model inference" \
  "8|Call managed foundation models; do not host the model" \
  "9|Lightweight event-driven / serverless task"
WORKLOAD="$REPLY"

if [[ "$WORKLOAD" == "7" ]]; then
  if ask_yes_no \
    "Do you specifically want a managed ML platform instead of a minimal EC2-based ML environment?" \
    "Choose yes if you want to submit training jobs or host an endpoint while SageMaker manages the ML job and endpoint lifecycle. Choose no if you want to administer the operating system, install your own stack, and run the model directly on EC2."; then
    MANAGED_ML=true
  fi
fi

if [[ "$WORKLOAD" == "8" ]]; then
  BEDROCK_API=true
  add_service BEDROCK
  add_reason "You want model inference through a managed API, so the primary workload does not require you to host the model on EC2."

  ask_managed_model_options

elif [[ "$WORKLOAD" == "9" ]]; then
  EVENT_DRIVEN=true
  add_service LAMBDA
  add_reason "The primary workload is explicitly lightweight and event-driven, so a maintained EC2 machine would add unnecessary infrastructure."

  ask_yes_no \
    "Does the serverless task read or write files in S3?" \
    "Choose yes if the function reads uploaded documents or writes results that must remain after the function ends. Choose no if it only handles a short request and keeps no durable files; using S3 as storage does not make S3 the event source." && PERSISTENT_DATA=true
  ask_yes_no \
    "Should an object arriving in S3 invoke the function?" \
    "Choose yes if uploading a report or image should automatically start the function. Choose no if the function is started by an API call, schedule, or another service, even if it later reads or writes S3 objects." && S3_EVENT_SOURCE=true
  [[ "$S3_EVENT_SOURCE" == true ]] && PERSISTENT_DATA=true
fi

if [[ "$WORKLOAD" != "8" && "$WORKLOAD" != "9" ]]; then
  if [[ "$WORKLOAD" == "7" && "$MANAGED_ML" == true ]]; then
    ask_choice \
      "What compute resource does the ML workload primarily need?" "2" \
      "1|CPU" \
      "2|GPU" \
      "3|AWS ML accelerator (Trainium / Inferentia / Neuron)"
  else
    ask_choice \
      "What compute resource does the workload primarily need?" "1" \
      "1|CPU" \
      "2|GPU" \
      "3|AWS ML accelerator (Trainium / Inferentia / Neuron)" \
      "4|Not sure / mixed"
  fi
  COMPUTE="$REPLY"

  if [[ "$COMPUTE" == "4" ]]; then
    ask_choice \
      "What is the main bottleneck?" "1" \
      "1|CPU throughput" \
      "2|GPU acceleration" \
      "3|Large RAM / memory capacity" \
      "4|I may not need to host the model myself"
    case "$REPLY" in
      1) COMPUTE="1" ;;
      2) COMPUTE="2" ;;
      3) COMPUTE="1" ; RAM="large" ;;
      4) BEDROCK_API=true; COMPUTE="" ;;
    esac
  fi

  if [[ "$BEDROCK_API" == true ]]; then
    add_service BEDROCK
    add_reason "The workload may be better served by a managed model API than by operating your own model server."
    ask_managed_model_options
  else
    if [[ "$RAM" != "large" ]]; then
      ask_choice \
        "What rough RAM range does one execution need?" "2" \
        "1|Up to ~16 GiB" \
        "2|~16–64 GiB" \
        "3|~64–256 GiB" \
        "4|More than ~256 GiB"
      case "$REPLY" in
        1) RAM="small" ;;
        2) RAM="medium" ;;
        3) RAM="large" ;;
        4) RAM="xlarge" ;;
      esac
    fi

    if [[ "$COMPUTE" == "2" ]]; then
      GPU_DEFAULT="2"
      [[ "$WORKLOAD" == "4" ]] && GPU_DEFAULT="1"
      if [[ "$MANAGED_ML" == true ]]; then
        ask_choice \
          "What kind of GPU work is this?" "2" \
          "2|ML training / CUDA compute" \
          "3|ML inference / serving" \
          "4|High-VRAM workload; exact GPU family still needs sizing"
      else
        ask_choice \
          "What kind of GPU work is this?" "$GPU_DEFAULT" \
          "1|Interactive graphics / visualization" \
          "2|ML training / CUDA compute" \
          "3|ML inference / serving" \
          "4|High-VRAM workload; exact GPU family still needs sizing"
      fi
      GPU_KIND="$REPLY"
      case "$GPU_KIND" in
        2) TRAINING=true ;;
        3) INFERENCE=true ;;
      esac

      ask_choice \
        "What rough GPU-memory range is needed?" "2" \
        "1|Up to ~16 GiB" \
        "2|~16–48 GiB" \
        "3|~48–96 GiB" \
        "4|More than ~96 GiB"
      VRAM="$REPLY"
    elif [[ "$COMPUTE" == "3" ]]; then
      ask_choice \
        "Which accelerator workload is this?" "1" \
        "1|Training" \
        "2|Inference"
      case "$REPLY" in
        1) TRAINING=true ;;
        2) INFERENCE=true ;;
      esac
    fi

    if [[ "$WORKLOAD" == "6" ]]; then
      MULTI_NODE=true
    elif [[ "$WORKLOAD" == "2" || "$WORKLOAD" == "3" || "$WORKLOAD" == "5" ]]; then
      MULTI_NODE=false
    else
      ask_yes_no \
        "Can the calculation itself run efficiently on one cloud machine?" \
        "Choose yes if one run fits on one VM, even when you have many separate runs to process. Choose no only if one calculation must divide its work across machines, such as a large simulation whose workers exchange results while solving it." || MULTI_NODE=true
    fi

    if [[ "$MULTI_NODE" == true ]]; then
      ask_yes_no \
        "Does the multi-node calculation require tightly coupled communication?" \
        "Choose yes for MPI simulations or distributed training where workers repeatedly exchange data during each run and slow networking would hold the job back. Choose no for independent jobs that can work on separate inputs and only upload results when finished." && TIGHTLY_COUPLED=true
    fi

    if [[ "$MANAGED_ML" == true ]]; then
      INTERACTIVE=false
      MAC_REQUIRED=false
    elif [[ "$WORKLOAD" == "4" ]]; then
      INTERACTIVE=true
      ask_yes_no \
        "Does the workload specifically require macOS / Apple Silicon execution?" \
        "Choose yes if the application or a required plugin only runs on macOS, such as a Mac-only build tool or Apple-platform test. Choose no if a Linux build can run the workload; ordinary EC2 avoids the Mac-specific host and capacity requirements." && MAC_REQUIRED=true
    elif [[ "$WORKLOAD" == "5" ]]; then
      ask_yes_no \
        "Do you also need an interactive remote GUI for setup or previews?" \
        "Choose yes if an artist needs to open Blender or Houdini remotely to adjust a scene or inspect previews while the farm renders frames. Choose no if workers can render submitted jobs unattended and results can be reviewed later." && INTERACTIVE=true
      ask_yes_no \
        "Does the render workload specifically require macOS / Apple Silicon worker hosts?" \
        "Choose yes if the renderer or plugin must execute on macOS; Deadline then uses EC2 Mac worker capacity. Choose no for software that runs on Linux, avoiding the Mac-specific worker hosts and Dedicated Host capacity." && MAC_REQUIRED=true
    else
      ask_yes_no \
        "Do you need an interactive graphical desktop while the workload runs?" \
        "Choose yes if you need to use a remote GUI during the job, for example to operate CAD, inspect a 3D scene, or debug a graphical scientific application. Choose no for scripts, training jobs, and batch calculations that run unattended." && INTERACTIVE=true
      ask_yes_no \
        "Does the workload specifically require macOS / Apple Silicon execution?" \
        "Choose yes if the application or a required dependency only supports macOS, such as a Mac-only desktop app or Apple-platform build. Choose no if Linux is supported; standard EC2 is usually simpler and has more compute choices." && MAC_REQUIRED=true
    fi

    if [[ "$MULTI_NODE" == true && "$MANAGED_ML" == false && "$MAC_REQUIRED" == false ]]; then
      ask_yes_no \
        "Do you want a scheduler such as Slurm?" \
        "Choose yes if a team needs to submit multi-node jobs into queues, request node counts, and avoid jobs competing for the same cluster. Choose no if your application already manages its workers or you only need one machine." && SLURM=true

      if [[ "$SLURM" == true ]]; then
        ask_choice \
          "For Slurm, which operating model do you want?" "2" \
          "1|AWS-managed Slurm control plane (PCS)" \
          "2|CLI-driven cluster lifecycle (ParallelCluster)"
        [[ "$REPLY" == "1" ]] && MANAGED_SLURM=true
      fi
    fi

    ask_yes_no \
      "Can the workload safely be interrupted and restarted from durable state?" \
      "Choose yes if the program checkpoints to durable storage or can cheaply restart from the beginning, so losing a machine will not lose valuable progress. Choose no for a one-shot run, unsaved interactive work, or a service that must stay available without interruption." && INTERRUPTIBLE=true

    if [[ "$INTERRUPTIBLE" == true && "$MAC_REQUIRED" == false ]]; then
      if ask_yes_no \
        "When Spot is safe, should the planner prefer Spot over On-Demand?" \
        "Choose yes if lower compute cost is worth waiting for capacity and handling interruptions; this selects EC2 Spot or managed SageMaker Spot training. Choose no if you need more predictable availability or prefer to avoid interruption and retry complexity, even though the workload could tolerate it."; then
        PREFER_SPOT=true
      fi
    fi

    ask_yes_no \
      "Do inputs, checkpoints, or results need to survive the compute machine?" \
      "Choose yes if source files, checkpoints, or results must still be there after an instance or job ends; S3 is the default durable object store. Choose no if all data is temporary and can be recreated, and nothing needs to move between runs." && PERSISTENT_DATA=true

    if [[ "$MANAGED_ML" == true ]]; then
      CONTAINERIZED=true
    elif [[ "$WORKLOAD" == "3" ]]; then
      CONTAINERIZED=true
    elif [[ "$WORKLOAD" != "5" ]]; then
      ask_yes_no \
        "Would containerizing the workload materially improve reproducibility/portability?" \
        "Choose yes if the program needs a pinned runtime or many system libraries and you want the same environment on a laptop, worker, or CI system. Choose no for a small script with simple dependencies that can be installed directly; AWS Batch still requires a runnable container image." && CONTAINERIZED=true
    fi

    if [[ "$WORKLOAD" == "2" || "$WORKLOAD" == "5" ]]; then
      MANY_INDEPENDENT=true
    elif [[ "$WORKLOAD" == "3" ]]; then
      ask_yes_no \
        "Does this pipeline have enough independent jobs that queueing and automatic worker scaling would save significant manual work?" \
        "Choose yes if the pipeline has enough independent tasks that a queue and automatic worker scaling would replace manual starts and monitoring. Choose no if it is a small workflow you can run in one container on one instance; containers alone do not require Batch." && MANY_INDEPENDENT=true
    fi

    if [[ "$MANAGED_ML" == false && "$MANY_INDEPENDENT" == false && "$MULTI_NODE" == false ]]; then
      if ask_yes_no \
        "Do you need a separate EBS gp3 working volume attached to the cloud machine?" \
        "Choose yes if the working set needs a separate block device or filesystem beyond the root disk, such as a large application dataset or scratch volume that should survive a stop. Choose no if the root disk is enough or the data belongs in S3; local NVMe can be faster scratch but disappears when the instance stops or terminates."; then
        add_service EBS
        add_reason "A separate EBS gp3 working volume was explicitly requested."
      fi
    fi
  fi
fi


}
