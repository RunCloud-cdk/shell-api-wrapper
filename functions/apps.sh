#!/usr/bin/env bash

# Make a readable table from response data (Internal)
# Example: rcdk_apps_table "$response"
function rcdk_apps_table {
  echo $1 | jq -r '["WEB_APP_ID","WEB_APP_NAME"], ["============","============"], (.data[] | [.id, .name]) | @tsv'
}

# Get the id of the web application by name (Internal)
# Example: rcdk_apps_get_id $app_name
function rcdk_apps_get_id {
  rcdk_args_check 1 "$@"
  local src_name=$1
  local response=`rcdk_request "servers/$server_id/webapps?page=1&search=$src_name" "GET"`
  echo $response | jq -r .data[].id
}

# Gets a list of all servers or searching info about current server through the name
# Example: rcdk_apps list 1
function rcdk_apps_get {
  rcdk_args_check 1 "$@"
  if [ -z "${1//[0-9]/}" ] # if arg is number
  then
    local page_num=$1
    local response=`rcdk_request "servers/$server_id/webapps?page=$page_num" "GET"`
  else
    local src_name=$1
    local response=`rcdk_request "servers/$server_id/webapps?page=1&search=$src_name" "GET"`
  fi
  rcdk_apps_table "$response"
}

# Create new runcloud web application
function rcdk_apps_create {
  echo -e "Create web application step by step"
  while [[ $app_name = '' ]]
  do
    read -ep "Enter a web application name: " app_name
  done
  while [[ $domain_name = '' ]]
  do
    read -ep "Enter a domain name for web application: " domain_name
  done
  read -ep "Choose owner of this web application (user runcloud by default): " user_name
  read -ep "Enter the public path: " public_path
  read -ep "Choose PHP version (type 'php70rc' or 'php71rc', 'php72rc' by default): " php_version
  read -ep "Choose a web stack (type 'hybrid', 'nativenginx' by default): " stack
  read -ep "Choose a stack mode (type 'development', 'production' by default): " stack_mode
  read -ep "Choose a timezone (leave empty for default: Asia/Jerusalem): " timezone
  read -ep "Enable SSL for this application? Type 'y' or 'n': " ssl_on
  if [[ $user_name = '' ]]
  then
    user_name+='runcloud'
  fi
  local first=`echo $public_path | head -c 1`
  if [[ $public_path != '' && $first != '/' ]]
  then
    public_path="/$public_path"
  fi
  if [[ $php_version = '' ]]
  then
    php_version+='php72rc'
  fi
  if [[ $stack = '' ]]
  then
    stack+='nativenginx'
  fi
  if [[ $stack_mode = '' ]]
  then
    stack_mode+='production'
  fi
  local data=""
  if [[ $timezone = '' ]]
  then
    timezone+='Asia/Jerusalem'
  fi
  local data=""
    data+="{\"webApplicationName\":\"$app_name\",\"domainName\":\"$domain_name\",\"user\":\"$user_name\","
    data+="\"publicPath\":\"$public_path\",\"phpVersion\":\"$php_version\",\"stack\":\"$stack\",\"stackMode\":\"$stack_mode\","
    data+="\"clickjackingProtection\":true,\"xssProtection\":true,\"mimeSniffingProtection\":true,"
    data+="\"processManager\":\"ondemand\",\"processManagerMaxChildren\":50,\"processManagerMaxRequests\":500,"
    data+="\"openBasedir\":\"/home/$user_name/webapps/$app_name:/var/lib/php/session:/tmp\",\"timezone\":\"$timezone\","
    data+="\"disableFunctions\":\"getmyuid,passthru,leak,listen,diskfreespace,tmpfile,link,ignore_user_abord,shell_exec,dl,"
    data+="set_time_limit,exec,system,highlight_file,source,show_source,fpassthru,virtual,posix_ctermid,posix_getcwd,"
    data+="posix_getegid,posix_geteuid,posix_getgid,posix_getgrgid,posix_getgrnam,posix_getgroups,posix_getlogin,"
    data+="posix_getpgid,posix_getpgrp,posix_getpid,posix,_getppid,posix_getpwuid,posix_getrlimit,posix_getsid,posix_getuid,"
    data+="posix_isatty,posix_kill,posix_mkfifo,posix_setegid,posix_seteuid,posix_setgid,posix_setpgid,posix_setsid,"
    data+="posix_setuid,posix_times,posix_ttyname,posix_uname,proc_open,proc_close,proc_nice,proc_terminate,escapeshellcmd,"
    data+="ini_alter,popen,pcntl_exec,socket_accept,socket_bind,socket_clear_error,socket_close,socket_connect,symlink,"
    data+="posix_geteuid,ini_alter,socket_listen,socket_create_listen,socket_read,socket_create_pair,stream_socket_server\","
    data+="\"maxExecutionTime\":30,\"maxInputTime\":60,\"maxInputVars\":1000,\"memoryLimit\":256,\"postMaxSize\":256,"
    data+="\"uploadMaxFilesize\":256,\"sessionGcMaxlifetime\":1440,\"allowUrlFopen\":true}"
  local response=`rcdk_request "servers/$server_id/webapps" "POST" $data`
  rcdk_parse "$response"
  if [[ ssl_on = 'y' ]]
  then
    local app_id=`rcdk_apps_get_id $app_name`
    rcdk_ssl_on $app_id
  fi
}

# Delete exists web application from runcloud
# Example: rcdk apps delete $web_app_name $web_app_id
function rcdk_apps_delete {
  rcdk_args_check 2 "$@"
  local app_name=$1
  local app_id=$2
  read -p "Are you sure want to delete this application? Say 'y' or 'n': " accept
  if [ "$accept" == "y" ]
  then
    local response=`rcdk_request "servers/$server_id/webapps/$app_id" "DELETE" "{\"webApplicationName\":\"$app_name\"}"`
    rcdk_parse "$response"
  else
    echo "Deleting application $app_name was canceled!"
  fi
}