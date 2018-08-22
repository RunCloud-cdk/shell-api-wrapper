#!/bin/bash

# Runcloud API Shell Wrapper
# by Captain4eyes from CDK team
# https://github.com/RunCloud-cdk/shell-api-wrapper

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

# Init work with rcdk by server_id
function rcdk_init {

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
    SYMBOLS=""
    for symbol in {A..Z} {a..z} {0..9}; do SYMBOLS=$SYMBOLS$symbol; done
#    SYMBOLS=$SYMBOLS'!@#$%&*()?/\[]{}-+_=<>.,'
    SYMBOLS=$SYMBOLS'@%-_=.,'
    PWD_LENGTH=$1  # password length
    PASSWORD=""    # passwd variable
    RANDOM=256     # random generator init
    for i in `seq 1 $PWD_LENGTH`
    do
    PASSWORD=$PASSWORD${SYMBOLS:$(expr $RANDOM % ${#SYMBOLS}):1}
    done
    echo $PASSWORD
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
    echo $1 | jq -r '["DB_ID","DB_NAME"], ["=====","======="], (.data[] | [.id, .name]) | @tsv'
}

# Gets a list of all databases or searching info about current database through the name
# Example1: rcdk_dbs $page_number, $search_name
function rcdk_dbs_get {
    rcdk_args_check 1 "$@"
    if [ "$2" ]; then local name=$2; fi
    local response=`rcdk_request "servers/$server_id/databases?page=$1&name=$name" "GET"`
    rcdk_dbs_table "$response"
}

# Create database
# Example: rcdk dbs create $dbname $dbcollation
function rcdk_db_create {
    rcdk_args_check 1 "$@"
    local response=`rcdk_request "servers/$server_id/databases" "POST" "{\"databaseName\":\"$1\",\"databaseCollation\":\"$2\"}"`
    rcdk_parse "$response"
}


# Delete database by id
# Example: rcdk dbs delete $db_name $db_id
function rcdk_db_delete {
    rcdk_args_check 2 "$@"
    local response=`rcdk_request "servers/$server_id/databases/$2" "DELETE" "{\"databaseName\":\"$1\"}"`
    rcdk_parse "$response"
}

# Make a readable table from response data (Internal)
# Example: rcdk_dbusers_table "$response"
function rcdk_dbusers_table {
    rcdk_args_check 1 "$@"
    echo $1 | jq -r '["DB_USER_ID","DB_USER_NAME"], ["==========","============"], (.data[] | [.id, .name]) | @tsv'
}

# Gets a list of all db-users or searching info about current db-user through the name
# Example1: rcdk_dbusers $page_number, $search_name
function rcdk_dbusers_get {
    rcdk_args_check 1 "$@"
    if [ "$2" ]; then local name=$2; fi
    local response=`rcdk_request "servers/$server_id/databaseusers?page=$1&name=$name" "GET"`
    rcdk_dbusers_table "$response"
}

# Create new database user
# Example: rcdk dbusers create $db_user $db_pass
function rcdk_dbuser_create {
    rcdk_args_check 1 "$@"
    if [ ! $2 ]
    then
        pass=`rcdk_pass_gen 32`
        echo "Password for user $1 - $pass"
    else
        pass=$2
    fi
    local response=`rcdk_request "servers/$server_id/databaseusers" "POST" "{\"databaseUser\":\"$1\",\"password\":\"$pass\",\"verifyPassword\":\"$pass\"}"`
    rcdk_parse "$response"
}

# Delete database user by id
# Example: rcdk dbusers delete $db_user $db_user_id
function rcdk_dbuser_delete {
    rcdk_args_check 2 "$@"
    local response=`rcdk_request "servers/$server_id/databaseusers/$2" "DELETE" "{\"databaseUser\":\"$1\"}"`
    rcdk_parse "$response"
}

# Attach database user to database
# Example: rcdk dbusers attach $db_user $db_id
function rcdk_dbuser_attach {
    rcdk_args_check 2 "$@"
    local response=`rcdk_request "servers/$server_id/databases/$2/attachuser" "POST" "{\"databaseUser\":\"$1\"}"`
    rcdk_parse "$response"
}

# Revoke database user from database
# Example: rcdk dbusers revoke $db_user $db_id
function rcdk_dbuser_revoke {
    rcdk_args_check 2 "$@"
    local response=`rcdk_request "servers/$server_id/databases/$2/attachuser" "DELETE" "{\"databaseUser\":\"$1\"}"`
    rcdk_parse "$response"
}

# Change password of database user
# Example: rcdk dbusers passwd $db_user_id $ds_user_pass
function rcdk_dbuser_passwd {
    rcdk_args_check 1 "$@"
    if [ ! $2 ]
    then
        pass=`rcdk_pass_gen 32`
        echo "New password is $pass"
    else
        pass=$2
    fi
    local response=`rcdk_request "servers/$server_id/databaseusers/$1" "PATCH" "{\"password\":\"$pass\",\"verifyPassword\":\"$pass\"}"`
    rcdk_parse "$response"
}

# Make a readable table from response data (Internal)
# Example: rcdk_sysusers_table "$response"
function rcdk_sysusers_table {
    rcdk_args_check 1 "$@"
    echo $1 | jq -r '["USER_ID","USER_NAME"], ["==========","============"], (.data[] | [.id, .username]) | @tsv'
}

# Gets a list of all system users or searching info about current system user through the name
# Example1: rcdk_sysusers $page_number, $search_name
function rcdk_sysusers_get {
    rcdk_args_check 1 "$@"
    if [ "$2" ]; then local username=$2; fi
    local response=`rcdk_request "servers/$server_id/users?page=$1&username=$username" "GET"`
    rcdk_sysusers_table "$response"
}


# Create new system user
# Example: rcdk sysusers create $sys_user_name $sys_user__pass
function rcdk_sysusers_create {
    rcdk_args_check 1 "$@"
    if [ ! $2 ]
    then
        pass=`rcdk_pass_gen 16`
        echo "Password for user $1 - $pass"
    else
        pass=$2
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
        pass=`rcdk_pass_gen 16`
        echo "New password is $pass"
    else
        pass=$2
    fi
    local response=`rcdk_request "servers/$server_id/users/$1" "PATCH" "{\"password\":\"$pass\",\"verifyPassword\":\"$pass\"}"`
    rcdk_parse "$response"
}

# Make a readable table from response data (Internal)
# Example: rcdk_ssh_table "$response"
function rcdk_ssh_table {
    echo $1 | jq -r '["KEY_ID","LABEL"], ["======","====="], (.data[] | [.id, .label]) | @tsv'
}

# Gets a list of all ssh keys or searching info about current key through the name
# Example1: rcdk_ssh $page_number, $search_name
function rcdk_ssh_get {
    rcdk_args_check 1 "$@"
    if [ "$2" ]; then local search=$2; fi
    local response=`rcdk_request "servers/$server_id/sshcredentials?page=$1&search=$search" "GET"`
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
    echo -e "Runcloud Shell API \nusage: rcdk <command> [<args>] [<options>]\n"\
    "\nCommands\n" \
    "\n     ping\t\t check connection with API" \
    "\n     init\t\t select the server you want to work with" \
    "\n     sysusers\t\t work with system users" \
    "\n     servers\t\t work with servers" \
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
    "\n     list\t\t view one page of databases list or search databases by chars\n" \
    "\nArguments\n" \
    "\n     create\t\t [*db_name, db_collation]" \
    "\n     delete\t\t [*db_name, *db_id]" \
    "\n     list\t\t [*page_number, search_name]\n"
}

# Function for a db users help info
function rcdk_help_dbusers {
    echo -e "\nusage: rcdk dbusers <command> [<args>]\n"\
    "\nCommands\n" \
    "\n     create\t\t create a new database user" \
    "\n     delete\t\t delete exists database user" \
    "\n     list\t\t view one page of db users list or search users by chars" \
    "\n     attach\t\t attach database user to database" \
    "\n     revoke\t\t revoke database user from database" \
    "\n     passwd\t\t change password for the db user\n" \
    "\nArguments\n" \
    "\n     create\t\t [*db_user, db_user_pass]\t by default, a 32-character password will be generated" \
    "\n     delete\t\t [*db_user, *db_user_id]" \
    "\n     list\t\t [*page_number, search_name]" \
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
    "\n     list\t\t [*page_number, search_name]" \
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
    "\n     list\t\t [*page_number, search_name]\n"
}

# Namespace function for databases - Defaults to listing databases
function rcdk_dbs {
  case "$1" in
    "create") rcdk_db_create "${@:2}";;
    "delete") rcdk_db_delete "${@:2}";;
    "list") rcdk_dbs_get "${@:2}";;
    *) rcdk_help_dbs;;
  esac
}

# Namespace function for databases - Defaults to listing database users
function rcdk_dbusers {
  case "$1" in
    "create") rcdk_dbuser_create "${@:2}";;
    "delete") rcdk_dbuser_delete "${@:2}";;
    "attach") rcdk_dbuser_attach "${@:2}";;
    "revoke") rcdk_dbuser_revoke "${@:2}";;
    "passwd") rcdk_dbuser_passwd "${@:2}";;
    "list") rcdk_dbusers_get "${@:2}";;
    *) rcdk_help_dbusers;;
  esac
}

# Namespace function for system users - Defaults to listing system users
function rcdk_sysusers {
   case "$1" in
    "create") rcdk_sysusers_create "${@:2}";;
    "delete") rcdk_sysusers_delete "${@:2}";;
    "passwd") rcdk_sysusers_passwd "${@:2}";;
    "list") rcdk_sysusers_get "${@:2}";;
    *) rcdk_help_sysusers;;
  esac
}

# Namespace function for ssh keys - Defaults to listing ssh keys
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
    "init") rcdk_init"${@:2}";;
    "sysusers") rcdk_sysusers "${@:2}";;
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