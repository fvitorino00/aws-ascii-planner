aws_plan_ui_init() {
  typeset -g B C G Y M R D
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
  B=$'\033[1m'
  C=$'\033[36m'
  G=$'\033[32m'
  Y=$'\033[33m'
  M=$'\033[35m'
  R=$'\033[0m'
  D=$'\033[2m'
else
  B=''; C=''; G=''; Y=''; M=''; R=''; D=''
fi

say() { print -r -- "$@"; }
hr()  { say "${D}--------------------------------------------------------------------------${R}"; }

aws_plan_header() {
  clear 2>/dev/null || true
  say "${B}==========================================================================${R}"
  say "${B}                     AWS WORKLOAD & COMPUTE PLANNER${R}"
  say "${B}==========================================================================${R}"
  say "${D}Goal: move heavy work off a personal computer without building an enterprise stack.${R}"
  say "${D}Rule: every specialized service must be justified by a workload requirement.${R}"
  say
  say "${Y}This script recommends architecture; it does not create AWS resources.${R}"
  say
}

abort_input_closed() {
  print -u2
  print -u2 -r -- "Input closed before all questions were answered; aborting."
  exit 1
}

ask_yes_no() {
  local prompt="$1"
  local explanation="$2"
  local reply

  while true; do
    print -n -- "${B}${C}[?] ${prompt} (y/n/e): ${R}"
    if [[ -t 0 ]]; then
      read -k 1 reply || abort_input_closed
      print
    else
      read -r reply || abort_input_closed
      reply=${reply[1]:-}
      [[ -n $reply ]] || reply="?"
    fi
    case "$reply" in
      [yY]) return 0 ;;
      [nN]) return 1 ;;
      [eE])
        print
        hr
        say "${M}YES / NO USE CASES${R}"
        say "$explanation"
        hr
        print
        ;;
      *) say "${Y}Please press y, n, or e.${R}" ;;
    esac
  done
}

ask_choice() {
  local prompt="$1" default="$2"
  shift 2
  local options=("$@")
  local item num label choice

  while true; do
    say "${B}${C}${prompt}${R}"
    for item in "${options[@]}"; do
      num="${item%%|*}"
      label="${item#*|}"
      if [[ "$num" == "$default" ]]; then
        say "  ${G}${num})${R} ${label} ${D}(default)${R}"
      else
        say "  ${num}) ${label}"
      fi
    done

    print -n -- "${B}Choice [${default}]: ${R}"
    read -r choice || abort_input_closed
    [[ -z "$choice" ]] && choice="$default"

    for item in "${options[@]}"; do
      num="${item%%|*}"
      if [[ "$choice" == "$num" ]]; then
        REPLY="$choice"
        return 0
      fi
    done
    say "${Y}Invalid choice.${R}"
    print
  done
}

contains() {
  local needle="$1" item
  shift
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}


}
