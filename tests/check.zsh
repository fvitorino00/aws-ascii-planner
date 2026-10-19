#!/usr/bin/env zsh
set -euo pipefail

ROOT=${0:A:h:h}
PLAN=$ROOT/bin/aws-plan/aws-plan
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

fail() {
  print -u2 -r -- "FAIL: $*"
  exit 1
}

run_plan() {
  local name=$1 answers=$2
  local out=$WORKDIR/$name
  local empty=$WORKDIR/empty.env
  : > "$empty"
  mkdir -p "$out"
  if ! env NO_COLOR=1 AWS_REGION=us-east-1 AWS_DEFAULT_REGION=us-east-1 \
      AWS_SETUP_OUT=$out AWS_SETUP_CONFIG=$empty \
      "$PLAN" >"$out/stdout.log" 2>"$out/stderr.log" <<< "${answers}"$'\nn'; then
    print -u2 -r -- "----- $name stdout log -----"
    tail -n 60 "$out/stdout.log" >&2
    print -u2 -r -- "----- $name stderr log -----"
    tail -n 60 "$out/stderr.log" >&2
    fail "$name exited non-zero"
  fi
  [[ -s $out/plan.json ]] || fail "$name did not write plan.json"
  [[ -s $out/architecture.txt ]] || fail "$name did not write architecture.txt"
  grep -q 'command not found' "$out/stderr.log" && fail "$name reported a missing command"
  grep -q 'Failed to write the plan file' "$out/stderr.log" && fail "$name failed to write the plan"
  print -r -- "$out"
}

assert_ascii_only() {
  local file=$1
  if LC_ALL=C grep -q '[^[:print:][:space:]]' "$file"; then
    fail "non-ASCII bytes in ${file:t}"
  fi
}

assert_has() {
  local file=$1 needle=$2
  grep -F -q -- "$needle" "$file" || fail "missing [$needle] in ${file:t}"
}

assert_lacks() {
  local file=$1 needle=$2
  if grep -F -q -- "$needle" "$file"; then
    fail "unexpected [$needle] in ${file:t}"
  fi
}

# Needles with no producer in the planner (pure guard rails) must be absent
# from the whole run: the pre-split helper checked one merged stream, so keep
# that exact meaning by screening both split streams.
assert_lacks_any_stream() {
  local needle=$1; shift
  local file
  for file in "$@"; do
    assert_lacks "$file" "$needle"
  done
}

assert_json() {
  local file=$1 expression=$2
  jq -e "$expression" "$file" >/dev/null || fail "JSON condition failed for ${file:t}: $expression"
}

assert_no_mermaid_artifacts() {
  local out=$1
  for artifact in architecture.mmd architecture.svg architecture.png mermaid.log; do
    [[ ! -f $out/$artifact ]] || fail "unexpected Mermaid artifact $artifact in $out"
  done
}

# Host-neutral mtime reads. `stat -f %m` is BSD-only (GNU stat treats -f as
# --file-system and exits 1 on '%m'); `stat -c %Y` is GNU-only and fails on
# macOS. The zsh/stat module returns integer mtime on any host, and zsh is
# already a hard requirement of this harness. If the module cannot load, say
# so explicitly instead of dying cryptically under set -e.
zmodload zsh/stat || fail "zsh/stat module is required by tests/check.zsh"

empty=$WORKDIR/empty-default.env
: > "$empty"
parent_out=${ROOT:h}/out
parent_stamp=""
[[ -d $parent_out ]] && parent_stamp=$(zstat +mtime "$parent_out")
default_out=$(env -u AWS_SETUP_OUT NO_COLOR=1 AWS_SETUP_CONFIG=$empty zsh -c '
  source "'"$ROOT"'/bin/aws-plan/aws-plan-setup-lib.zsh"
  aws_setup_init "'"$ROOT"'/bin/aws-plan/aws-plan"
  print -r -- "$AWS_SETUP_OUT"
')
[[ $default_out == $ROOT/out ]] || fail "default output is $default_out"
if [[ -n $parent_stamp ]]; then
  [[ $(zstat +mtime "$parent_out") == $parent_stamp ]] || fail "default setup touched $parent_out"
fi

spot=$(run_plan spot $'1\n\n\ny\nn\nn\ny\ny\ny\nn\nn\nn\nn')
assert_no_mermaid_artifacts $spot
assert_json $spot/plan.json '.schema == "pc-aws-plan/v2" and .workload.execution_model == "DIRECT_EC2"'
assert_json $spot/plan.json '[.decision.selected_services[].id] | index("SPOT") != null'
assert_json $spot/plan.json '[.architecture.service_relationships[] | select(.from == "VPC" and .to == "EC2")] | length > 0'
assert_json $spot/plan.json '[.architecture.service_relationships[] | select(.from == "EC2" and .to == "CW")] | length > 0'
assert_has $spot/plan.json '"service_relationships"'
assert_has $spot/plan.json '"relationships"'
assert_lacks $spot/plan.json '"deployment"'
assert_lacks_any_stream 'falling back' $spot/stdout.log $spot/stderr.log
assert_lacks_any_stream 'Graphviz' $spot/stdout.log $spot/stderr.log
assert_lacks_any_stream 'Mermaid' $spot/stdout.log $spot/stderr.log
assert_lacks $spot/stdout.log 'rendering skipped'
assert_has $spot/stdout.log 'Plan:'
assert_has $spot/architecture.txt 'AWS Unified Architecture Graph'
assert_has $spot/architecture.txt 'VPC --[contains subnet]--> Subnet'
assert_has $spot/architecture.txt '..[launch EC2 in subnet]..>'
assert_has $spot/architecture.txt 'Mountpoint for S3: /mnt/s3'
assert_lacks $spot/architecture.txt 'configure S3 event trigger'
assert_ascii_only $spot/architecture.txt
assert_has $spot/graph-audit.md 'AWS Unified Graph Audit'
assert_has $spot/graph-audit.md 'Service-level relationships'

gpu=$(run_plan gpu $'1\n2\n\n1\n\ny\ny\nn\nn\ny\nn\nn\nn\nn')
assert_no_mermaid_artifacts $gpu
assert_json $gpu/plan.json '.requirements.dcv == true and .requirements.gpu_kind == "1"'
assert_has $gpu/architecture.txt 'install/configure DCV server'
assert_has $gpu/architecture.txt 'DCV Server Configuration'
assert_ascii_only $gpu/architecture.txt

api=$(run_plan api $'8\nn\ny\nn\nn')
assert_no_mermaid_artifacts $api
assert_json $api/plan.json '.workload.execution_model == "MANAGED_API" and ([.decision.selected_services[].id] | index("BEDROCK") != null)'
assert_lacks $api/architecture.txt 'configure S3 event trigger'
assert_ascii_only $api/architecture.txt

lambda_files=$(run_plan lambda-files $'9\ny\nn\nn\nn\nn')
assert_no_mermaid_artifacts $lambda_files
assert_json $lambda_files/plan.json '.requirements.s3 == true'
assert_lacks $lambda_files/architecture.txt 'configure S3 event trigger'
assert_has $lambda_files/architecture.txt 'Lambda Function'
assert_has $lambda_files/architecture.txt 'S3 Bucket'
assert_ascii_only $lambda_files/architecture.txt

lambda_events=$(run_plan lambda-events $'9\nn\ny\nn\nn\nn')
assert_no_mermaid_artifacts $lambda_events
assert_has $lambda_events/architecture.txt 'S3 Bucket ..[configure S3 event trigger]..> Lambda Function'
assert_json $lambda_events/plan.json '.requirements.s3 == true'
assert_ascii_only $lambda_events/architecture.txt

pcs=$(run_plan pcs $'6\n3\n\n1\ny\nn\nn\ny\n1\nn\nn\nn\nn')
assert_no_mermaid_artifacts $pcs
assert_json $pcs/plan.json '.workload.execution_model == "MULTI_NODE_PCS"'
assert_has $pcs/architecture.txt 'PCS Cluster'
assert_has $pcs/architecture.txt 'PCS Compute Node Group'
assert_has $pcs/architecture.txt 'Trainium Compute'
assert_has $pcs/architecture.txt 'allow EFA traffic'
# NOPROJ edges must still appear as concrete resource setup actions in ASCII.
assert_has $pcs/architecture.txt 'Security Group ..[allow EFA traffic]..> EFA Network Interface'
assert_lacks $pcs/architecture.txt 'EFA/Lustre'
assert_ascii_only $pcs/architecture.txt

# CLI-driven ParallelCluster (WORKLOAD 6, Slurm operating model 2): the sibling
# of pcs above, differing by exactly that one answer. Covers the execution mode
# MULTI_NODE_PARALLELCLUSTER and the PC/ParallelCluster graph path (PCCL node,
# PC service circle, PC-issued cluster capacity), which no other scenario asserts.
pc=$(run_plan pc $'6\n\n\ny\nn\nn\ny\n2\nn\nn\nn\nn\nn')
assert_no_mermaid_artifacts $pc
assert_json $pc/plan.json '.workload.execution_model == "MULTI_NODE_PARALLELCLUSTER"'
assert_json $pc/plan.json '[.decision.selected_services[].id] | index("PC") != null'
assert_json $pc/plan.json '[.decision.selected_services[].id] | index("PCS") == null'
assert_has $pc/architecture.txt 'ParallelCluster'
assert_has $pc/architecture.txt 'provisions EC2 cluster capacity'
assert_has $pc/architecture.txt 'allow EFA traffic'
assert_lacks $pc/architecture.txt 'EFA/Lustre'
assert_lacks $pc/architecture.txt 'PCSNG'
assert_lacks $pc/architecture.txt 'PCSQ'
assert_ascii_only $pc/architecture.txt

sage=$(run_plan sage $'7\ny\n3\n\n1\nn\ny\ny\ny\nn\nn\nn')
assert_no_mermaid_artifacts $sage
assert_json $sage/plan.json '.workload.execution_model == "MANAGED_ML"'
assert_has $sage/architecture.txt 'SageMaker Job / Endpoint'
assert_has $sage/architecture.txt 'Trainium Compute'
assert_has $sage/architecture.txt 'enable EFA'
assert_lacks $sage/architecture.txt 'VPC --[contains subnet]--> Subnet'
assert_ascii_only $sage/architecture.txt

trn=$(run_plan trn $'7\nn\n3\n\n1\ny\nn\nn\nn\nn\nn\nn')
assert_no_mermaid_artifacts $trn
assert_has $trn/architecture.txt 'AWS Unified Architecture Graph'
assert_lacks $trn/architecture.txt 'TRNNODE'
assert_lacks $trn/architecture.txt 'type selected later'
assert_ascii_only $trn/architecture.txt

batch=$(run_plan batch $'2\n\n\nn\nn\ny\ny\ny\nn\nn\nn\nn')
assert_no_mermaid_artifacts $batch
assert_json $batch/plan.json '.workload.execution_model == "BATCH"'
assert_has $batch/architecture.txt 'configure S3 access'
assert_lacks $batch/architecture.txt 'Mountpoint for S3'
assert_ascii_only $batch/architecture.txt

# Regression: ASCII output write failure must be reported clearly and the
# CLI must exit non-zero, while leaving earlier plan JSON / graph audit
# writes intact. Pre-create architecture.txt as a directory so the redirect
# in the ASCII renderer fails.
ascii_fail=$WORKDIR/ascii-fail
mkdir -p "$ascii_fail/architecture.txt"
if env NO_COLOR=1 AWS_REGION=us-east-1 AWS_DEFAULT_REGION=us-east-1 \
    AWS_SETUP_OUT=$ascii_fail AWS_SETUP_CONFIG=$empty \
    "$PLAN" >"$ascii_fail/stdout.log" 2>"$ascii_fail/stderr.log" \
    <<< $'1\n\n\ny\nn\nn\ny\ny\ny\nn\nn\nn\nn'$'\nn'; then
  fail "ASCII write failure did not exit non-zero"
fi
grep -q 'Failed to write the ASCII architecture file' "$ascii_fail/stderr.log" || fail "missing ASCII failure message"
[[ -s $ascii_fail/plan.json ]] || fail "plan.json missing despite ASCII failure"
[[ -s $ascii_fail/graph-audit.md ]] || fail "graph-audit.md missing despite ASCII failure"
assert_no_mermaid_artifacts $ascii_fail

print -r -- "ok"
