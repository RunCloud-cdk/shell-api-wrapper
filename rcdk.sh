#!/bin/bash

# Runcloud API Shell Wrapper
# by Captain4eyes from CDK team
# https://github.com/RunCloud-cdk/shell-api-wrapper

rcdk_name='Runcloud Shell API Wrapper'
rcdk_version="1.0"

# Check if api creds have been set. If not, check if they're in the config file.
if [[ ! "$api_key" || ! "$api_secret_key" ]]; then
rcdk_config="api.conf"
  if [ -e "$rcdk_config" ]; then
    . "$rcdk_config"
  elif [ -e "$HOME/$rcdk_config" ]; then
    . "$HOME/$rcdk_config"
  fi
fi

# Checks if required args are set
# Example: rcdk_args_check 1 "$@"
function rcdk_args_check {
  local a=("${@:2}")
  local c="$1"
  if [ "${#a[@]}" -lt "$c" ]; then
    echo "Error: Missing required arguments. Use 'rcdk -h' command for help "
    exit 1
  fi
}

# Parse response message to the simple raw format (Internal)
# Example: rcdk_data_parse "$response"
function rcdk_parse {
  echo $1 | jq -rc '.message'
}

# Request construct API function (Internal)
# Example: rcdk_request "servers/$server_id/webapps" "POST"
function rcdk_request {
  rcdk_args_check 2 "$@"
  if [ "$2" ]; then local t="-X $2"; fi
  if [ "$3" ]; then local d="-d $3"; fi
  local response=`curl -s $t https://manage.runcloud.io/base-api/$1 -u $api_key:$api_secret_key -H "Content-Type: application/json" "$d"`
  if [ ! "$response" ]; then response='{"error":{"message":"No response from Runcloud."}}'; fi
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

# Generating postfix with a-z, A-Z, 0-9 (Internal)
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

# Init work with rcdk by server_id
# Example: rcdk_init $server_id
function rcdk_init {
  read -p "Enter id of the server you want to work with: " server_id
  sed -i "s/server_id=.*/server_id=$server_id/" $rcdk_config
  echo "Successfully switched on $server_id server."
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
  echo $1 | jq -r '["DATABASE_ID","DATABASE_NAME"], ["------------","--------------"], (.data[] | [.id, .name]) | @tsv'
}

# Gets a list of all databases or searching info about current database through the name
# Example1: rcdk_dbs $page_number, $search_name
function rcdk_dbs_get {
  rcdk_args_check 1 "$@"
  if [ -z "${1//[0-9]/}" ] # if arg is number
  then
    local p_num=$1
    local response=`rcdk_request "servers/$server_id/databases?page=$p_num" "GET"`
  else
    local name=$1
    local response=`rcdk_request "servers/$server_id/databases?page=1&name=$name" "GET"`
  fi
  rcdk_dbs_table "$response"
}

# Create database
# Example: rcdk dbs create $dbname $dbcollation
function rcdk_dbs_create {
  rcdk_args_check 1 "$@"
  local postfix=`rcdk_postfix_gen 5`
  local response=`rcdk_request "servers/$server_id/databases" "POST" "{\"databaseName\":\"$1$postfix\",\"databaseCollation\":\"$2\"}"`
  rcdk_parse "$response"
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
  echo $1 | jq -r '["DB_USER_ID","DB_USER_NAME"], ["------------","---------------"], (.data[] | [.id, .name]) | @tsv'
}

# Gets a list of all db-users or searching info about current db-user through the name
# Example1: rcdk_dbusers $page_number, $search_name
function rcdk_dbusers_get {
  rcdk_args_check 1 "$@"
  if [ -z "${1//[0-9]/}" ] # if arg is number
  then
    local p_num=$1
    local response=`rcdk_request "servers/$server_id/databaseusers?page=$p_num" "GET"`
  else
    local name=$1
    local response=`rcdk_request "servers/$server_id/databaseusers?page=1&name=$name" "GET"`
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
    echo "Password for user $1 - $pass"
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
  local response=`rcdk_request "servers/$server_id/databaseusers/$2" "DELETE" "{\"databaseUser\":\"$1\"}"`
  rcdk_parse "$response"
}

# Attach database user to database
# Example: rcdk dbusers attach $db_user $db_id
function rcdk_dbusers_attach {
  rcdk_args_check 2 "$@"
  local response=`rcdk_request "servers/$server_id/databases/$2/attachuser" "POST" "{\"databaseUser\":\"$1\"}"`
  rcdk_parse "$response"
}

# Revoke database user from database
# Example: rcdk dbusers revoke $db_user $db_id
function rcdk_dbusers_revoke {
  rcdk_args_check 2 "$@"
  local response=`rcdk_request "servers/$server_id/databases/$2/attachuser" "DELETE" "{\"databaseUser\":\"$1\"}"`
  rcdk_parse "$response"
}

# Change password of database user
# Example: rcdk dbusers passwd $db_user_id $ds_user_pass
function rcdk_dbusers_passwd {
  rcdk_args_check 1 "$@"
  if [ ! $2 ]
  then
    local pass=`rcdk_pass_gen 32`
    echo "New password is $pass"
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
  echo $1 | jq -r '["SYS_USER_ID","SYS_USER_NAME"], ["------------", "------------"], (.data[] | [.id, .username]) | @tsv'
}

# Gets a list of all system users or searching info about current system user through the name
# Example1: rcdk_sysusers $page_number, $search_name
function rcdk_sysusers_get {
  rcdk_args_check 1 "$@"
  if [ -z "${1//[0-9]/}" ] # if arg is number
  then
    local p_num=$1
    local response=`rcdk_request "servers/$server_id/users?page=$p_num" "GET"`
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
  echo $1 | jq -r '["WEB_APP_ID","WEB_APP_NAME"], ["----------","-------"], (.data[] | [.id, .name]) | @tsv'
}

# Gets a list of all servers or searching info about current server through the name
# Example: rcdk_apps list 1
function rcdk_apps_get {
  rcdk_args_check 1 "$@"
  if [ -z "${1//[0-9]/}" ] # if arg is number
  then
    local p_num=$1
    local response=`rcdk_request "servers/$server_id/webapps?page=$p_num" "GET"`
  else
    local search=$1
    local response=`rcdk_request "servers/$server_id/webapps?page=1&search=$search" "GET"`
  fi
  rcdk_apps_table "$response"
}

# Create new runcloud web application
function rcdk_apps_create {
  echo -e "Create web application step by step\n"
  read -p "Enter a web application name: " app_name
  read -p "Enter a domain name for web application: " domain_name
  read -p "Choose owner of this web application ( if dosen't exists, will be created ): " user_name
  read -p "Enter a public path ( leave empty for the root path ): " public_path
  read -p "Choose PHP version ( write 'php70rc', 'php71rc' or 'php72rc' ): " php_version
  read -p "Choose a web stack ( write 'hybrid' or 'nativenginx' ): " stack
  read -p "Choose a timezone ( example: Europe/Moscow ): " timezone

  local data=""
    data+="{\"webApplicationName\":\"$app_name\",\"domainName\":\"$domain_name\",\"user\":\"$user_name\","
    data+="\"publicPath\":\"$public_path\",\"phpVersion\":\"$php_version\",\"stack\":\"$stack\","
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
}

# Delete exists web application from runcloud
# Example: rcdk apps delete $web_app_name $web_app_id
function rcdk_apps_delete {
  rcdk_args_check 2 "$@"
  read -p "Are you sure want to delete this application? Say 'y' or 'n': " accept
  if [ "$accept" == "y" ]
  then
      local app_id=$2
      local response=`rcdk_request "servers/$server_id/webapps/$app_id" "DELETE" "{\"webApplicationName\":\"$1\"}"`
      rcdk_parse "$response"
  else
      echo "Deleting application $1 was canceled!"
  fi
}

# Make a readable table from response data (Internal)
# Example: rcdk_servers_table "$response"
function rcdk_servers_table {
  echo $1 | jq -r '["SERVER_ID","SERVER_NAME","IP_ADDRESS"], ["---------","-----------","---------"], (.data[] | [.id, .serverName, .ipAddress]) | @tsv'
}

# Gets a list of all servers or searching info about current server through the name
# Example: rcdk servers list 1
function rcdk_servers_get {
  rcdk_args_check 1 "$@"
  if [ -z "${1//[0-9]/}" ] # if arg is number
  then
    local p_num=$1
    local response=`rcdk_request "servers?page=$p_num" "GET"`
  else
    local search=$1
    local response=`rcdk_request "servers?page=1&search=$search" "GET"`
  fi
  rcdk_servers_table "$response"
}

# Create new runcloud server
# Example: rcdk servers create $srv_name $srv_ip $provider
function rcdk_servers_create {
  rcdk_args_check 2 "$@"
  local data="{\"serverName\":\"$1\",\"ipAddress\":\"$2\"}"
  if [ -n $3 ]
  then
      local provider=$3
      data+=",\"serverProvider\":\"$provider\""
  fi
  local response=`rcdk_request "servers" "POST" $data`
  rcdk_parse "$response"
}

# Delete exists server from runcloud
# Example: rcdk servers delete $srv_id
function rcdk_servers_delete {
  rcdk_args_check 1 "$@"
  echo -n "Are you sure want to delete this server? Say 'yes' or 'no': "
  read accept
  if [ $accept -eq "yes" ]
  then
      local response=`rcdk_request "servers" "DELETE" "{\"typeYes\":\"YES\",\"certifyToDeleteServer\":\"true\",
      \"proceedToDeletion\":\"true\",\"lastWarning\":\"true\"}"`
      rcdk_parse "$response"
  else
      exit 1
  fi
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
    local p_num=$1
    local response=`rcdk_request "servers/$server_id/sshcredentials?page=$p_num" "GET"`
  else
    local search=$1
    local response=`rcdk_request "servers/$server_id/sshcredentials?page=1&search=$search" "GET"`
  fi
  rcdk_ssh_table "$response"
}

# Add new ssh key
# Example: rcdk ssh add $label $sys_user_name $pub_key
function rcdk_ssh_add {
  rcdk_args_check 3 "$@"
  local response=`rcdk_request "servers/$server_id/sshcredentials/" "POST" "{\"label\":\"$1\",\"user\":\"$2\",\"publicKey\":\"$3\"}"`
  rcdk_parse "$response"
}

# Delete ssh key by id
# Example: rcdk ssh delete $label $key_id
function rcdk_ssh_delete {
  rcdk_args_check 2 "$@"
  local response=`rcdk_request "servers/$server_id/sshcredentials/$2" "DELETE" "{\"label\":\"$1\"}"`
  rcdk_parse "$response"
}

# Namespace function for help info
function rcdk_help {
  echo -e "$rcdk_name\n \nusage: rcdk <command> [<args>] [<options>]\n"\
  "\nCommands\n" \
  "\n     ping\t\t check connection with API" \
  "\n     init\t\t select the server you want to work with" \
  "\n     sysusers\t\t work with system users" \
  "\n     servers\t\t work with servers" \
  "\n     dbs\t\t work with databases" \
  "\n     dbusers\t\t work with databases users" \
  "\n     ssh\t\t work with ssh keys\n" \
  "\nOptions\n" \
  "\n     -v, --version\t checking rcdk api shell version"
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

# Function for a servers help info
function rcdk_help_servers {
  echo -e "\nusage: rcdk servers <command> [<args>]\n"\
  "\nCommands\n" \
  "\n     create\t\t create a new server" \
  "\n     delete\t\t delete exists server" \
  "\n     list\t\t view one page of servers list or search them by chars\n" \
  "\nArguments\n" \
  "\n     create\t\t [*srv_name, *srv_ip, provider]" \
  "\n     delete\t\t [*srv_id]" \
  "\n     list\t\t [*page_number || *search_name]\n"
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
  "\n     passwd\t\t [*db_user_id, ds_user_pass]\t by default, a 32-character password will be generated\n"
}

# Function for a system users help info
function rcdk_help_sysusers {
  echo -e "\nusage: rcdk sysusers <command> [<args>]\n"\
  "\nCommands\n" \
  "\n     create\t\t create a new database" \
  "\n     delete\t\t delete exists database" \
  "\n     list\t\t view one page of system users list or search users by chars" \
  "\n     passwd\t\t change password for the system user\n" \
  "\nArguments\n" \
  "\n     create\t\t [*sysuser_name, sysuser_pass]\t by default, a 16-character password will be generated" \
  "\n     delete\t\t [*sysuser_name, *sysuser_id]" \
  "\n     list\t\t [*page_number || *search_name]" \
  "\n     passwd\t\t [*db_user_id, ds_user_pass]\t by default, a 16-character password will be generated\n"
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
    "create") rcdk_servers_create "${@:2}";;
    "delete") rcdk_servers_delete "${@:2}";;
    "list") rcdk_servers_get "${@:2}";;
    *) rcdk_help_servers;;
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
    "-v") echo "Runcloud API Shell Wrapper  Ver $rcdk_version"
      exit 0;;
    "--version") echo "Runcloud API Shell Wrapper  Ver $rcdk_version"
      exit 0;;
    "ping") rcdk_ping;;
    "init") rcdk_init "${@:2}";;
    "sysusers") rcdk_sysusers "${@:2}";;
    "apps") rcdk_apps "${@:2}";;
    "servers") rcdk_servers "${@:2}";;
    "dbs") rcdk_dbs "${@:2}";;
    "dbusers") rcdk_dbusers "${@:2}";;
    "ssh") rcdk_ssh "${@:2}";;
    *)
      rcdk_help;;
  esac
}

# Only run if we're not being sourced
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  rcdk "$@"
fi