#!/usr/bin/env bash

# Make a readable table from response data (Internal)
# Example: rcdk_dbs_table "$response"
function rcdk_dbs_table {
  rcdk_args_check 1 "$@"
  echo $1 | jq -r '["DATABASE_ID","DATABASE_NAME"], ["============","=============="], (.data[] | [.id, .name]) | @tsv'
}

# Get the id of the database by name (Internal)
# Example: rcdk_dbusers_get_id $name
function rcdk_dbs_get_id {
  rcdk_args_check 1 "$@"
  local src_name=$1
  local response=`rcdk_request "servers/$server_id/databases?page=1&name=$src_name" "GET"`
  echo $response | jq -r .data[].id
}

# Gets a list of all databases or searching info about current database through the name
# Example1: rcdk_dbs $page_number, $search_name
function rcdk_dbs_get {
  rcdk_args_check 1 "$@"
  if [ -z "${1//[0-9]/}" ] # if arg is number
  then
    local page_num=$1
    local response=`rcdk_request "servers/$server_id/databases?page=$page_num" "GET"`
  else
    local src_name=$1
    local response=`rcdk_request "servers/$server_id/databases?page=1&name=$src_name" "GET"`
  fi
  rcdk_dbs_table "$response"
}

# Create database
# Example: rcdk dbs create $dbname $dbcollation
function rcdk_dbs_create {
  rcdk_args_check 1 "$@"
  local db_name=$1
  if echo "$db_name" | grep -q "_"
  then
    local response=`rcdk_request "servers/$server_id/databases" "POST" "{\"databaseName\":\"$db_name\",\"databaseCollation\":\"$2\"}"`
    rcdk_parse "$response"
  else
    local pf='_'`rcdk_str_gen 5 'a-z0-9'`
    local response=`rcdk_request "servers/$server_id/databases" "POST" "{\"databaseName\":\"$db_name$pf\",\"databaseCollation\":\"$2\"}"`
    rcdk_parse "$response"
  fi
}

# Delete database by id
# Example: rcdk dbs delete $db_name $db_id
function rcdk_dbs_delete {
  rcdk_args_check 2 "$@"
  local response=`rcdk_request "servers/$server_id/databases/$2" "DELETE" "{\"databaseName\":\"$1\"}"`
  rcdk_parse "$response"
}