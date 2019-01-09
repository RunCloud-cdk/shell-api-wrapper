#!/usr/bin/env bash

# Make a readable table from response data (Internal)
# Example: rcdk_ssh_table "$response"
function rcdk_ssh_table {
  echo $1 | jq -r '["PUB_KEY_ID","LABEL"], ["----------","------"], (.data[] | [.id, .label]) | @tsv'
}

# Gets a list of all ssh keys or searching info about current key through the name
# Example1: rcdk_ssh $page_number, $search_name
function rcdk_ssh_get {
  rcdk_args_check 1 "$@"
  if [ -z "${1//[0-9]/}" ] # if arg is number
  then
    local page_num=$1
    local response=`rcdk_request "servers/$server_id/sshcredentials?page=$page_num" "GET"`
  else
    local src_name=$1
    local response=`rcdk_request "servers/$server_id/sshcredentials?page=1&search=$src_name" "GET"`
  fi
  rcdk_ssh_table "$response"
}

# Add new ssh key
# Example: rcdk ssh add $label $sys_user_name $pub_key
function rcdk_ssh_add {
  rcdk_args_check 3 "$@"
  local label=$1
  local user_name=$2
  local pub_key=$3
  local response=`rcdk_request "servers/$server_id/sshcredentials/" "POST" "{\"label\":\"$label\",\"user\":\"$user_name\",\"publicKey\":\"$pub_key\"}"`
  rcdk_parse "$response"
}

# Delete ssh key by id
# Example: rcdk ssh delete $label $key_id
function rcdk_ssh_delete {
  rcdk_args_check 2 "$@"
  local label=$1
  local key_id=$2
  local response=`rcdk_request "servers/$server_id/sshcredentials/$key_id" "DELETE" "{\"label\":\"$label\"}"`
  rcdk_parse "$response"
}