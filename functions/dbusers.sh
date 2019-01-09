#!/usr/bin/env bash

# Make a readable table from response data (Internal)
# Example: rcdk_dbusers_table "$response"
function rcdk_dbusers_table {
  rcdk_args_check 1 "$@"
  echo $1 | jq -r '["DB_USER_ID","DB_USER_NAME"], ["============","==============="], (.data[] | [.id, .name]) | @tsv'
}

# Get the name with a postfix of the database user by name (Internal)
# Example: rcdk_dbusers_get_name $name
function rcdk_dbusers_get_name {
  rcdk_args_check 1 "$@"
  local src_name=$1
  local response=`rcdk_request "servers/$server_id/databaseusers?page=1&name=$src_name" "GET"`
  echo $response | jq -r .data[].name
}

# Gets a list of all db-users or searching info about current db-user through the name
# Example1: rcdk_dbusers $page_number, $search_name
function rcdk_dbusers_get {
  rcdk_args_check 1 "$@"
  if [ -z "${1//[0-9]/}" ] # if arg is number
  then
    local page_num=$1
    local response=`rcdk_request "servers/$server_id/databaseusers?page=$page_num" "GET"`
  else
    local src_name=$1
    local response=`rcdk_request "servers/$server_id/databaseusers?page=1&name=$src_name" "GET"`
  fi
  rcdk_dbusers_table "$response"
}

# Create new database user
# Example: rcdk dbusers create $db_user $db_pass
function rcdk_dbusers_create {
  rcdk_args_check 1 "$@"
  if [ ! $2 ]
  then
    local pass=`rcdk_str_gen 32 'A-Za-z0-9_@%^#'`
    local postfix='_'`rcdk_str_gen 5 'a-z0-9'`
    echo -e "${YELLOW}Password for user $1${NC} - ${B}$pass"
  else
    local pass=$2
  fi
  local response=`rcdk_request "servers/$server_id/databaseusers" "POST" "{\"databaseUser\":\"$1$postfix\",\"password\":\"$pass\",\"verifyPassword\":\"$pass\"}"`
  rcdk_parse "$response"
}

# Delete database user by id
# Example: rcdk dbusers delete $db_user $db_user_id
function rcdk_dbusers_delete {
  rcdk_args_check 2 "$@"
  local db_user_name=$1
  local db_user_id=$2
  local response=`rcdk_request "servers/$server_id/databaseusers/$db_user_id" "DELETE" "{\"databaseUser\":\"$db_user_name\"}"`
  rcdk_parse "$response"
}

# Attach database user to database
# Example: rcdk dbusers attach $db_user $db_id
function rcdk_dbusers_attach {
  rcdk_args_check 2 "$@"
  local db_user_name=$1
  local db_id=$2
  local response=`rcdk_request "servers/$server_id/databases/$db_id/attachuser" "POST" "{\"databaseUser\":\"$db_user_name\"}"`
  rcdk_parse "$response"
}

# Revoke database user from database
# Example: rcdk dbusers revoke $db_user $db_id
function rcdk_dbusers_revoke {
  rcdk_args_check 2 "$@"
  local db_user_name=$1
  local db_id=$2
  local response=`rcdk_request "servers/$server_id/databases/$db_id/attachuser" "DELETE" "{\"databaseUser\":\"$db_user_name\"}"`
  rcdk_parse "$response"
}

# Change password of database user
# Example: rcdk dbusers passwd $db_user_id $ds_user_pass
function rcdk_dbusers_passwd {
  rcdk_args_check 1 "$@"
  if [ ! $2 ]
  then
    local pass=`rcdk_str_gen 32 'A-Za-z0-9_@%^#'`
    echo -e "${YELLOW}New password is ${WHITE}${B}$pass"
  else
    local pass=$2
  fi
  local response=`rcdk_request "servers/$server_id/databaseusers/$1" "PATCH" "{\"password\":\"$pass\",\"verifyPassword\":\"$pass\"}"`
  rcdk_parse "$response"
}