#!/usr/bin/env bash

# Make a readable table from response data (Internal)
# Example: rcdk_servers_table "$response"
function rcdk_servers_table {
  echo $1 | jq -r '["SERVER_ID","SERVER_NAME","IP_ADDRESS"], ["============","===========","============="],
   (.data[] | [.id, .serverName, .ipAddress]) | @tsv'
}

# Gets a list of all servers or searching info about current server through the name
# Example: rcdk servers list 1
function rcdk_servers_get {
  rcdk_args_check 1 "$@"
  if [ -z "${1//[0-9]/}" ] # if arg is number
  then
    local page_num=$1
    local response=`rcdk_request "servers?page=$page_num" "GET"`
  else
    local src_name=$1
    local response=`rcdk_request "servers?page=1&search=$src_name" "GET"`
  fi
  rcdk_servers_table "$response"
}

# Create new runcloud server
# Example: rcdk servers create $srv_name $srv_ip $provider
function rcdk_servers_add {
  rcdk_args_check 2 "$@"
  local data="{\"serverName\":\"$1\",\"ipAddress\":\"$2\""
  if [[ $3 ]]
  then
    local provider=$3
    data+=",\"serverProvider\":\"$provider\""
  fi
  data+="}"
  local response=`rcdk_request "servers" "POST" $data`
  rcdk_parse "$response"
}

# Show hardware info about runcloud server
function rcdk_servers_info_table {
  rcdk_args_check 1 "$@"
  local kernel_v=`echo $1 | jq -r .kernelVersion`
  local proc_name=`echo $1 | jq -r .processorName`
  local cpu_cores=`echo $1 | jq -r .totalCPUCore`
  local mem_total=`echo $1 | jq -r .totalMemory | cut -c1-4`
  local mem_free=`echo $1 | jq -r .freeMemory | cut -c1-4`
  local disk_total=`echo $1 | jq -r .diskTotal | cut -c1-5`
  local disk_free=`echo $1 | jq -r .diskFree | cut -c1-5`
  local load_avg=`echo $1 | jq -r .loadAvg`
  local uptime=`echo $1 | jq -r .uptime`
  local response=`rcdk_request "servers/$server_id//show/data" "GET"`
  echo -e "Hardware info\n=============\nKernel version: $kernel_v\nProcessor: $proc_name, cores - $cpu_cores" \
  "\nMemory: total - $mem_total"GB", ${GREEN}free - $mem_free"GB"${NC}" \
  "\nDisk: total - $disk_total"GB", ${GREEN}free - $disk_free"GB"${NC}" \
  "\nLoad avg: $load_avg\nUptime: ${GREEN}$uptime${NC}"
}

# Show hardware info about runcloud server
function rcdk_servers_info {
  local response=`rcdk_request "servers/$server_id/show/data" "GET"`
  rcdk_servers_info_table "$response"
}

# Check current runcloud server
# Example: rcdk servers check
function rcdk_servers_check {
  local response=`rcdk_request "servers/$server_id" "GET"`
  local srv_name=`echo $response | jq -r .serverName`
  local ipAddress=`echo $response | jq -r .ipAddress`
  local id=`echo $response | jq -r .id`
  echo -e "Current server is ${GREEN}$srv_name ($ipAddress)${NC}\nID - ${GREEN}$id${NC}"
}

# Delete exists server from runcloud
# Example: rcdk servers delete $srv_id
function rcdk_servers_delete {
  rcdk_args_check 1 "$@"
  echo -n "Are you sure want to delete this server? Say 'y' or 'n': "
  read accept
  if [ $accept -eq "y" ]
  then
    local response=`rcdk_request "servers" "DELETE" "{\"typeYes\":\"YES\",\"certifyToDeleteServer\":\"true\",
    \"proceedToDeletion\":\"true\",\"lastWarning\":\"true\"}"`
    rcdk_parse "$response"
  else
    exit 1
  fi
}