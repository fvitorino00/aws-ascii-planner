aws_setup_init() {
  local src=${1:A}
  AWS_SETUP_ROOT=${src:h:h:h}
  local config_home=${XDG_CONFIG_HOME:-$HOME/.config}/pc-aws/local.env
  if [[ -n ${AWS_SETUP_CONFIG:-} && -f $AWS_SETUP_CONFIG ]]; then
    source $AWS_SETUP_CONFIG
  elif [[ -f $AWS_SETUP_ROOT/config/local.env ]]; then
    source $AWS_SETUP_ROOT/config/local.env
  elif [[ -f $config_home ]]; then
    source $config_home
  fi
  : ${AWS_SETUP_OUT:=$AWS_SETUP_ROOT/out}
  : ${AWS_SETUP_REGION:=}
  mkdir -p "$AWS_SETUP_OUT"
  if [[ -n $AWS_SETUP_REGION ]]; then
    export AWS_DEFAULT_REGION=$AWS_SETUP_REGION
  fi
}
