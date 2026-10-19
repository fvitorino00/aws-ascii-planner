resource_display_label() {
  if [[ "$RES_SRC|$RES_DST" == "EC2_RES|S3B" ]]; then
    if [[ $MAC_REQUIRED == true ]]; then
      print -r -- "configure S3 access via AWS CLI/SDK"
    elif [[ $ORCHESTRATED == false ]]; then
      print -r -- "Mountpoint for S3: /mnt/s3"
    else
      print -r -- "$RES_LABEL"
    fi
  elif [[ "$RES_SRC|$RES_DST" == "SG|EFAI" ]]; then
    if [[ $REQ_FSX == true ]]; then
      print -r -- "allow EFA/Lustre traffic"
    else
      print -r -- "allow EFA traffic"
    fi
  else
    print -r -- "$RES_LABEL"
  fi
}
