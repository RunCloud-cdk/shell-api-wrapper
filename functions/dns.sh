#!/usr/bin/env bash

# Get domains list of application
# Example: rcdk dns list $web_app_id
function rcdk_dns_get {
  rcdk_args_check 1 "$@"
  local app_id=$1
  local response=`rcdk_request "servers/$server_id/webapps/$app_id/domainname" "GET"`
  echo "$response"| jq -r '["DOMAIN_ID","DOMAIN_NAME"], ["============","=============="], (.data[] | [.id, .name]) | @tsv'
}

# Add new domain name for the application
# Example: rcdk dns add $web_app_id $domain_name_1 $domain_name_n
function rcdk_dns_add {
  rcdk_args_check 2 "$@"
  local app_id=$1
  declare -a domains=("${@:2}")
  for d in "${domains[@]}"
  do
    local data="{\"domainName\":\"$d\"}"
    local response=`rcdk_request "servers/$server_id/webapps/$app_id/domainname" "POST" $data`
    rcdk_parse "$response"
  done
}

# Get domains list of application
# Example: rcdk dns elete web_app_id $domain_id
function rcdk_dns_delete {
  rcdk_args_check 2 "$@"
  local app_id=$1
  local domain_id=$2
  local response=`rcdk_request "servers/$server_id/webapps/$app_id/domainname/$domain_id" "DELETE"`
  rcdk_parse "$response"
}