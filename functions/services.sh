#!/usr/bin/env bash

# Gets a list of all server's services
# Example: rcdk services list
function rcdk_services_get {
  local response=`rcdk_request "servers/$server_id/services" "GET"`
  echo -e "$response" | jq -r '["SERVICE_NAME ","RUNNING  ","VERSION"],
   ["------------","-------","----------------------"],
    (.data[] | [.realName, .Running, .Version]) | @tsv'
}

# The action will be one of these: start,stop,restart,reload
# Example: rcdk services start nginx-rc
function rcdk_services_action {
  rcdk_args_check 2 "$@"
  local action=$1
  local real_name=$2
  local name=''
  case $real_name in
    "nginx-rc") name+='NGiNX';;
    "apache2-rc") name+='HTTPD\/Apache';;
    "mysql") name+='MariaDB';;
    "supervisord") name+='Supervisord';;
    "redis-server") name+='Redis';;
    "memcached") name+='Memcached';;
    "beanstalkd") name+='Beanstalkd';;
    *) echo -e "This service does'nt exists!";;
  esac

  local data="{\"action\":\"$action\",\"realName\":\"$real_name\",\"name\":\"$name\"}"
  local response=`rcdk_request "servers/$server_id/services" "PATCH" $data`
  rcdk_parse "$response"
}