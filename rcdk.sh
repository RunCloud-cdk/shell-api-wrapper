#!/usr/bin/env bash

# Runcloud API Shell Wrapper
# by Captain4eyes from CDK team
# https://github.com/RunCloud-cdk/shell-api-wrapper

# Stop script execution in case of error
set -o errexit

# RCDK constants
readonly RCDK_NAME='Runcloud Shell API Wrapper'
readonly RCDK_VERSION="1.0"
readonly RCDK_CONF_DIR="$HOME/rcdkConfigs"
readonly API_CONFIG="$RCDK_CONF_DIR/api.conf"

# Color & font constants
readonly B="\033[0;30m"
readonly NC="\033[0m"
readonly RED="\033[0;31m"
readonly YELLOW="\033[0;33m"
readonly GREEN="\033[0;32m"

# Configurating a connection with API
function rcdk_config {
  read -ep "Enter api key: " api_key
  read -ep "Enter api secret key: " api_secret_key
  if [[ -e $API_CONFIG ]]
  then
    sed -i "s/api_key=.*/api_key=$api_key/" $API_CONFIG
    sed -i "s/api_secret_key=.*/api_secret_key=$api_secret_key/" $API_CONFIG
    echo -e "${GREEN}Configuration file was successfully updated!${NC}"
  else
    mkdir $RCDK_CONF_DIR
    printf 'api_key="'$api_key'"\napi_secret_key="'$api_secret_key'"\nserver_id=' > $API_CONFIG
    echo -e "${GREEN}Configuration file was successfully created!${NC}"
  fi
}

# Updating rcdk from Github
function rcdk_update {
  cd && curl -sSL https://raw.githubusercontent.com/RunCloud-cdk/shell-api-wrapper/master/rcdk.sh > rcdk
  chmod +x rcdk && sudo cp -u rcdk /usr/local/bin/rcdk
  rm rcdk
  echo -e "${GREEN}Updating Shell wrapper done${NC}"
  wget https://raw.githubusercontent.com/RunCloud-cdk/shell-api-wrapper/master/rcdk && sudo cp rcdk /etc/bash_completion.d/
  rm rcdk
  echo -e "${GREEN}Updating Bash completion done${NC}"
}

# Check if api creds have been set. If not, check if they're in the config file.
if [[ ! "$api_key" || ! "$api_secret_key" ]]
then
  if [[ -e $API_CONFIG ]]
  then
    . "$API_CONFIG"
  else
    rcdk_config
  fi
fi

# Checks if required args are set (Internal)
# Example: rcdk_args_check 1 "$@"
function rcdk_args_check {
  local a=("${@:2}")
  local c="$1"
  if [ "${#a[@]}" -lt "$c" ]; then
    echo -e "${RED}Error: Missing required arguments. Use 'rcdk help' command for help${NC}"
    exit 1
  fi
}

# Parse response message to the simple raw format (Internal)
# Example: rcdk_data_parse "$response"
function rcdk_parse {
  local result=`echo $1 | jq -rc ".message"`
  echo -e "${GREEN}$result${NC}"
}

# Request construct API function (Internal)
# Example: rcdk_request "servers/$server_id/webapps" "POST"
function rcdk_request {
  rcdk_args_check 2 "$@"
  if [[ $2 ]]; then local t="-X $2"; fi
  if [[ $3 ]]; then local d="-d $3"; fi
  local response=`curl -s $t https://manage.runcloud.io/base-api/$1 -u $api_key:$api_secret_key \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" "$d"`
  if [[ ! $response ]]; then response='{"error":{"message":"No response from Runcloud."}}'; fi
  echo $response | tr '\n' ' '
}

# Generating secure passwords with a-z, A-Z, 0-9 and special chars (Internal)
# Example: rcdk_pass_gen $length
function rcdk_pass_gen {
  rcdk_args_check 1 "$@"
  local symbols=""
  for symbol in {A..Z} {a..z} {0..9}; do symbols=$symbols$symbol; done
  symbols=$symbols'@%-_=.,'
  local pwd_length=$1  # password length
  local password=""    # passwd variable
  RANDOM=256     # random generator init
  for i in `seq 1 $pwd_length`
  do
    password=$password${symbols:$(expr $RANDOM % ${#symbols}):1}
  done
  echo $password
}

# Generating postfix with a-z, 0-9 (Internal)
# Example: rcdk_postfix_gen $length
function rcdk_postfix_gen {
  rcdk_args_check 1 "$@"
  local symbols=""
  for symbol in {a..z} {0..9}; do symbols=$symbols$symbol; done
  local pfix_length=$1  # postfix length
  local postfix="_"    # postfix variable
  RANDOM=256     # random generator init
  for i in `seq 1 $pfix_length`
  do
    postfix=$postfix${symbols:$(expr $RANDOM % ${#symbols}):1}
  done
  echo $postfix
}

# Checking runcloud api connection
function rcdk_ping {
  local response=`rcdk_request "ping" "GET"`
  rcdk_parse "$response"
}

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
    local pf=`rcdk_postfix_gen 5`
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
    local pass=`rcdk_pass_gen 32`
    local postfix=`rcdk_postfix_gen 5`
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
    local pass=`rcdk_pass_gen 32`
    echo -e "${YELLOW}New password is ${WHITE}${B}$pass"
  else
    local pass=$2
  fi
  local response=`rcdk_request "servers/$server_id/databaseusers/$1" "PATCH" "{\"password\":\"$pass\",\"verifyPassword\":\"$pass\"}"`
  rcdk_parse "$response"
}

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
    local pass=`rcdk_pass_gen 16`
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
    local pass=`rcdk_pass_gen 16`
    echo "New password is $pass"
  else
    local pass=$2
  fi
  local response=`rcdk_request "servers/$server_id/users/$1" "PATCH" "{\"password\":\"$pass\",\"verifyPassword\":\"$pass\"}"`
  rcdk_parse "$response"
}

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

# Render SSL info of application (Internal)
function rcdk_ssl_table {
  rcdk_args_check 1 "$@"
  local ssl_id=`echo $1 | jq -r .id`
  if [ $ssl_id = 'null' ]
  then
    echo -e "SSL INFO\n========\n${YELLOW}SSL is uninstalled for this application"
  else
    local method=`echo $1 | jq -r .method_humanize`
    local renewal_date=`echo $1 | jq -r .renewal_date`
    local cert=`echo $1 | jq -r .certificate`
    echo -e "SSL INFO\n========\nSSL id: $ssl_id\nSSL method: $method\nRenewal date: $renewal_date"
  fi
}

# Get SSL info of application
# Example: rcdk apps ssl info web_app_id
function rcdk_ssl_info {
  rcdk_args_check 1 "$@"
  local app_id=$1
  local response=`rcdk_request "servers/$server_id/webapps/$app_id/ssl" "GET"`
  rcdk_ssl_table "$response"
}

# Install ssl for the web application
# Example: rcdk apps ssl on web_app_id
function rcdk_ssl_on {
  rcdk_args_check 1 "$@"
  local app_id=$1
  read -ep "Select 'letsencrypt' or 'custom' provider ( by default letsencrypt ): " provider
  if [[ $provider = '' ]]
  then
    provider+='letsencrypt'
  fi
  read -ep "Enable HTTP Access ? ( type 'false' or press enter for the 'true' value ): " http
  if [[ $http = '' ]]
  then
    http+='true'
  fi
  read -ep "Enable HSTS ? ( type 'false' or press enter for the 'true' value ): " hsts
  if [[ $hsts = '' ]]
  then
    hsts+='true'
  fi
  local data="{\"provider\":\"$provider\",\"enableHttp\":$http,\"enableHsts\":$hsts"

  if [[ $provider = 'letsencrypt' ]];
  then
    read -ep "Select autorizaton method 'http-01' or 'dns-01' ( by default - http-01 ): " auth_method
    if [[ $auth_method = '' ]]
    then
      auth_method+='http-01'
    fi
    data+=",\"authorizationMethod\":\"$auth_method\","
    if [[ auth_method = 'dns-01' ]]
    then
      read -ep "Type id of the 3rd Party API to use: " third_id
      data+="\"externalApi\":\"$third_id\","
    fi
    read -ep "Select 'live' or 'staging' environment ( by default - live ): " env
    if [[ $env = '' ]]
    then
      env+='live'
    fi
    data+="\"environment\":\"$env\""
  else
    read -ep "Type a private key from custom provider: " private_key
    read -ep "Type a certificate: " certificate
    data+=",\"privateKey\":\"$private_key\",\"certificate\":\"$certificate\""
  fi

  data+="}"
  local response=`rcdk_request "servers/$server_id/webapps/$app_id/ssl" "POST" $data`
  rcdk_parse "$response"
}

# Update ssl for the web application
# Example: rcdk apps ssl update $web_app_id $ssl_id
function rcdk_ssl_update {
  rcdk_args_check 2 "$@"
  local ssl_info=rcdk_ssl_info $app_id
  echo -e "Type 'true' or 'false'\n"
  read -ep "Enable HTTP?: " http
  read -ep "Enable HSTS?: " hsts
  local data="{\"enableHttp\":\"$http\",\"enableHsts\":\"$hsts\"}"
  local response=`rcdk_request "servers/$server_id/webapps/$1/ssl/$2" "PATCH" $data`
  rcdk_parse "$response"
}

# Uninstall ssl for the web application
# Example: rcdk apps ssl off $web_app_id $ssl_id
function rcdk_ssl_off {
  rcdk_args_check 2 "$@"
  local app_id=$1
  local ssl_id=$2
  local response=`rcdk_request "servers/$server_id/webapps/$app_id/ssl/$ssl_id" "DELETE"`
  rcdk_ssl_table "$response"
}

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
  if [ -n $3 ]
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

# Init work with rcdk by server_id
# Example: rcdk_init $server_id
function rcdk_init {
  rcdk servers list 1; echo ""
  read -ep "Enter id of the server you want to work with: " server_id
  sed -i "s/server_id=.*/server_id=$server_id/" $API_CONFIG
  echo -e "${GREEN}Successfully switched on $server_id server."
}

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

# Function to create a full web application with a database, ssl, etc.
function rcdk_bundle {
  read -ep "Type name of the database user: " db_user
  read -sp "Type the password for the database user ( by default, a 32-character password will be generated ): " db_user_pass; echo ""
  read -ep "Type name of the database ( by default such as database username ): " db_name
  read -ep "Type database collation (not required): " db_col
  if [[ $db_name == '' ]]
  then
    db_name+=$db_user
  fi
  local db_user_pf=`rcdk_postfix_gen 5`
  local db_user_pass=`rcdk_pass_gen 32`
  local db_username=$db_user$db_user_pf
  local db_name_pf=`rcdk_postfix_gen 5`
  db_name+=$db_name_pf
  rcdk_dbusers_create $db_username $db_user_pass
  echo -e "${YELLOW}Password for user $db_username - $db_user_pass${NC}"
  rcdk_dbs_create $db_name $db_col
  local db_id=`rcdk_dbs_get_id $db_name`
  rcdk_dbusers_attach $db_username $db_id
  rcdk_apps_create
}

# A function of generating help info
#function rcdk_help_gen {
#
#}

# Namespace function for help info
function rcdk_help {
  echo -e "\n$RCDK_NAME\n \nusage: rcdk <command> [<args>] [<options>]\n"\
  "\nCommands\n" \
  "\n     ping\t\t check connection with API" \
  "\n     config\t\t configurating connection with API" \
  "\n     init\t\t select the server you want to work with" \
  "\n     bundle\t\t create a full web application with a database, ssl, etc" \
  "\n     update\t\t update rcdk to the last version from github" \
  "\n     sysusers\t\t work with system users" \
  "\n     servers\t\t work with servers" \
  "\n     services\t\t work with web application services" \
  "\n     apps\t\t work with web applications" \
  "\n     ssl\t\t work with ssl of web application" \
  "\n     dns\t\t work with domains of web application" \
  "\n     dbs\t\t work with databases" \
  "\n     dbusers\t\t work with databases users" \
  "\n     ssh\t\t work with ssh keys\n" \
  "\nOptions\n" \
  "\n     -v, --version\t checking rcdk api shell version\n"
}

# Function for a dbs help info
function rcdk_help_dbs {
  echo -e "\nusage: rcdk dbs <command> [<args>]\n"\
  "\nCommands\n" \
  "\n     create\t\t create a new database" \
  "\n     delete\t\t delete exists database" \
  "\n     list\t\t view one page of databases list or search them by chars\n" \
  "\nArguments\n" \
  "\n     create\t\t [*db_name, db_collation]" \
  "\n     delete\t\t [*db_name, *db_id]" \
  "\n     list\t\t [*page_number || *search_name]\n"
}

# Function for a servers help info
function rcdk_help_apps {
  echo -e "\nusage: rcdk apps <command> [<args>]\n"\
  "\nCommands\n" \
  "\n     create\t\t create a new web application" \
  "\n     delete\t\t delete exists web application" \
  "\n     list\t\t view one page of web application list or search them by chars\n" \
  "\nArguments\n" \
  "\n     create\t\t this function asks you for all the arguments" \
  "\n     delete\t\t [*app_name, *app_id]" \
  "\n     list\t\t [*page_number || *search_name]\n"
}

# Function for a ssl help info
function rcdk_help_ssl {
  echo -e "\nusage: rcdk ssl <command> [<args>]\n"\
  "\nCommands\n" \
  "\n     info\t\t show application ssl credentials" \
  "\n     on\t\t\t install ssl for the application" \
  "\n     update\t\t update ssl for the application" \
  "\n     off\t\t uninstall ssl for the application\n" \
  "\nArguments\n" \
  "\n     info\t\t [*web_app_id]" \
  "\n     on\t\t\t [*web_app_id]" \
  "\n     update\t\t [*web_app_id, *ssl_id]" \
  "\n     off\t\t [*web_app_id, *ssl_id]\n"
}

# Function for a dns help info
function rcdk_help_dns {
  echo -e "\nusage: rcdk dns <command> [<args>]\n"\
  "\nCommands\n" \
  "\n     list\t\t show list of domains for the web application" \
  "\n     add\t\t add new domain names for the web application" \
  "\n     delete\t\t delete domain name from the web application by id\n" \
  "\nArguments\n" \
  "\n     list\t\t [*web_app_id]" \
  "\n     add\t\t [*web_app_id, *domain_name-1, domain_name-n]" \
  "\n     delete\t\t [*web_app_id, *domain_id]\n"
}

# Function for a servers help info
function rcdk_help_servers {
  echo -e "\nusage: rcdk servers <command> [<args>]\n"\
  "\nCommands\n" \
  "\n     create\t\t create a new server" \
  "\n     delete\t\t delete exists server" \
  "\n     info\t\t show server hardware info" \
  "\n     list\t\t view one page of servers list or search them by chars\n" \
  "\nArguments\n" \
  "\n     create\t\t [*srv_name, *srv_ip, provider]" \
  "\n     delete\t\t [*srv_id]" \
  "\n     list\t\t [*page_number || *search_name]\n"
}

# Function for a services help info
function rcdk_help_services {
  echo -e "\nusage: rcdk services <command> [<args>]\n"\
  "\nCommands\n" \
  "\n     list\t\t list of all server's services" \
  "\n     [action]\t\t perform the action for the service\n\t\t\t the action will be one of these: start,stop,restart,reload" \
  "\nArguments\n" \
  "\n     [action]\t\t perform the action for the service\n\t\t\t the action will be one of these: start, stop, restart, reload"
}

# Function for a db users help info
function rcdk_help_dbusers {
  echo -e "\nusage: rcdk dbusers <command> [<args>]\n"\
  "\nCommands\n" \
  "\n     create\t\t create a new database user" \
  "\n     delete\t\t delete exists database user" \
  "\n     list\t\t view one page of db users list or search them by chars" \
  "\n     attach\t\t attach database user to database" \
  "\n     revoke\t\t revoke database user from database" \
  "\n     passwd\t\t change password for the db user\n" \
  "\nArguments\n" \
  "\n     create\t\t [*db_user, db_user_pass]\t by default, a 32-character password will be generated" \
  "\n     delete\t\t [*db_user, *db_user_id]" \
  "\n     list\t\t [*page_number || *search_name]" \
  "\n     attach\t\t [*db_user, *db_id]" \
  "\n     revoke\t\t [*db_user, *db_id]" \
  "\n     passwd\t\t [*db_user_id, db_user_pass]\t by default, a 32-character password will be generated\n"
}

# Function for a system users help info
function rcdk_help_sysusers {
  echo -e "\nusage: rcdk sysusers <command> [<args>]\n"\
  "\nCommands\n" \
  "\n     create\t\t create a new system user" \
  "\n     delete\t\t delete exists system user" \
  "\n     list\t\t view one page of system users list or search users by chars" \
  "\n     passwd\t\t change password for the system user\n" \
  "\nArguments\n" \
  "\n     create\t\t [*sysuser_name, sysuser_pass]\t by default, a 16-character password will be generated" \
  "\n     delete\t\t [*sysuser_name, *sysuser_id]" \
  "\n     list\t\t [*page_number || *search_name]" \
  "\n     passwd\t\t [*sysuser_id, sysuser_pass]\t by default, a 16-character password will be generated\n"
}

# Function for a dbs help info
function rcdk_help_ssh {
  echo -e "\nusage: rcdk dbs <command> [<args>]\n"\
  "\nCommands\n" \
  "\n     add\t\t add new ssh key for the system user" \
  "\n     delete\t\t delete exists ssh key" \
  "\n     list\t\t view one page of keys list or search keys by chars\n" \
  "\nArguments\n" \
  "\n     add\t\t [*label, *sys_user_name, *pub_key]\t !add pub_key in apostrophes!" \
  "\n     delete\t\t [*label, *key_id]" \
  "\n     list\t\t [*page_number || *search_name]\n"
}

# Namespace function for databases
function rcdk_dbs {
  case "$1" in
    "create") rcdk_dbs_create "${@:2}";;
    "delete") rcdk_dbs_delete "${@:2}";;
    "list") rcdk_dbs_get "${@:2}";;
    *) rcdk_help_dbs;;
  esac
}

# Namespace function for database users
function rcdk_dbusers {
  case "$1" in
    "create") rcdk_dbusers_create "${@:2}";;
    "delete") rcdk_dbusers_delete "${@:2}";;
    "attach") rcdk_dbusers_attach "${@:2}";;
    "revoke") rcdk_dbusers_revoke "${@:2}";;
    "passwd") rcdk_dbusers_passwd "${@:2}";;
    "list") rcdk_dbusers_get "${@:2}";;
    *) rcdk_help_dbusers;;
  esac
}

# Namespace function for servers
function rcdk_servers {
  case "$1" in
    "info") rcdk_servers_info "${@:2}";;
    "add") rcdk_servers_add "${@:2}";;
    "delete") rcdk_servers_delete "${@:2}";;
    "list") rcdk_servers_get "${@:2}";;
    *) rcdk_help_servers;;
  esac
}

# Namespace function for services
function rcdk_services {
  case "$1" in
    "list") rcdk_services_get "${@:2}";;
    "start") rcdk_services_action start "${@:2}";;
    "stop") rcdk_services_action stop "${@:2}";;
    "restart") rcdk_services_action restart "${@:2}";;
    "reload") rcdk_services_action reload "${@:2}";;
    *) rcdk_help_services;;
  esac
}

# Namespace function for system users
function rcdk_sysusers {
  case "$1" in
    "create") rcdk_sysusers_create "${@:2}";;
    "delete") rcdk_sysusers_delete "${@:2}";;
    "passwd") rcdk_sysusers_passwd "${@:2}";;
    "list") rcdk_sysusers_get "${@:2}";;
    *) rcdk_help_sysusers;;
  esac
}

# Namespace function for apps
function rcdk_apps {
  case "$1" in
    "create") rcdk_apps_create "${@:2}";;
    "delete") rcdk_apps_delete "${@:2}";;
    "list") rcdk_apps_get "${@:2}";;
    *) rcdk_help_apps;;
  esac
}

# Namespace function for ssl
function rcdk_ssl {
  case "$1" in
    "info") rcdk_ssl_info "${@:2}";;
    "on") rcdk_ssl_on "${@:2}";;
    "update") rcdk_ssl_update "${@:2}";;
    "off") rcdk_ssl_off "${@:2}";;
    *) rcdk_help_ssl;;
  esac
}

# Namespace function for domain names
function rcdk_dns {
  case "$1" in
    "list") rcdk_dns_get "${@:2}";;
    "add") rcdk_dns_add "${@:2}";;
    "delete") rcdk_dns_delete "${@:2}";;
    *) rcdk_help_dns;;
  esac
}

# Namespace function for ssh keys
function rcdk_ssh {
  case "$1" in
    "add") rcdk_ssh_add "${@:2}";;
    "delete") rcdk_ssh_delete "${@:2}";;
    "list") rcdk_ssh_get "${@:2}";;
    *) rcdk_help_ssh;;
  esac
}

# Main function for everything
function rcdk {
  case "$1" in
    "-v") echo "Runcloud API Shell Wrapper  Ver $RCDK_VERSION"
      exit 0;;
    "--version") echo "Runcloud API Shell Wrapper  Ver $RCDK_VERSION"
      exit 0;;
    "help") rcdk_help;;
    "ping") rcdk_ping;;
    "config") rcdk_config;;
    "init") rcdk_init "${@:2}";;
    "update") rcdk_update;;
    "bundle") rcdk_bundle "${@:2}";;
    "sysusers") rcdk_sysusers "${@:2}";;
    "apps") rcdk_apps "${@:2}";;
    "ssl") rcdk_ssl "${@:2}";;
    "dns") rcdk_dns "${@:2}";;
    "servers") rcdk_servers "${@:2}";;
    "services") rcdk_services "${@:2}";;
    "dbs") rcdk_dbs "${@:2}";;
    "dbusers") rcdk_dbusers "${@:2}";;
    "ssh") rcdk_ssh "${@:2}";;
    *) echo -e "${RED}Error: Command not found. Use the 'rcdk help' command for detailed information.";;
  esac
}

# Only run if we're not being sourced
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  rcdk "$@"
fi
