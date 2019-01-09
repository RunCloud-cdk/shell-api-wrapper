#!/usr/bin/env bash

# Make a readable table from response data (Internal)
# Example: rcdk_sysusers_table "$response"
function rcdk_sysusers_table {
  rcdk_args_check 1 "$@"
  echo $1 | jq -r '["SYS_USER_ID","SYS_USER_NAME"], ["============", "============="], (.data[] | [.id, .username]) | @tsv'
}

# Gets a list of all system users or searching info about current system user through the name
# Example1: rcdk_sysusers list $page_number, $search_name
function rcdk_sysusers_get {
  rcdk_args_check 1 "$@"
  if [ -z "${1//[0-9]/}" ] # if arg is number
  then
    local page_num=$1
    local response=`rcdk_request "servers/$server_id/users?page=$page_num" "GET"`
  else
    local username=$1
    local response=`rcdk_request "servers/$server_id/users?page=1&username=$username" "GET"`
  fi
  rcdk_sysusers_table "$response"
}

# Create new system user
# Example: rcdk sysusers create $sys_user_name $sys_user__pass
function rcdk_sysusers_create {
  rcdk_args_check 1 "$@"
  if [ ! $2 ]
  then
    local pass=`rcdk_str_gen 16 'A-Za-z0-9_@%^#'`
    echo "Password for user $1 - $pass"
  else
    local pass=$2
  fi
  local response=`rcdk_request "servers/$server_id/users/" "POST" "{\"username\":\"$1\",\"password\":\"$pass\",\"verifyPassword\":\"$pass\"}"`
  rcdk_parse "$response"
}

# Delete system user by id
# Example: rcdk sysusers delete $sys_user_name $sys_user_id
function rcdk_sysusers_delete {
  rcdk_args_check 2 "$@"
  local response=`rcdk_request "servers/$server_id/users/$2" "DELETE" "{\"username\":\"$1\"}"`
  rcdk_parse "$response"
}

# Change password of system user
# Example: rcdk sysusers passwd $sys_user_id $sys_user_pass
function rcdk_sysusers_passwd {
  rcdk_args_check 1 "$@"
  if [ ! $2 ]
  then
    local pass=`rcdk_str_gen 16 'A-Za-z0-9_@%^#'`
    echo "New password is $pass"
  else
    local pass=$2
  fi
  local response=`rcdk_request "servers/$server_id/users/$1" "PATCH" "{\"password\":\"$pass\",\"verifyPassword\":\"$pass\"}"`
  rcdk_parse "$response"
}