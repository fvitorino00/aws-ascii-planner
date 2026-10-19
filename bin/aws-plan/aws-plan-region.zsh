aws_plan_region() {
  typeset -g REGION
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
if [[ -z "$REGION" ]] && command -v aws >/dev/null 2>&1; then
  REGION="$(aws configure get region 2>/dev/null || true)"
fi
[[ -z "$REGION" ]] && REGION="not configured"


}
