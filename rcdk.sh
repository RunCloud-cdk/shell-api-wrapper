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
readonly FUNC_DIR="$RCDK_CONF_DIR/functions"

# Color & font constants
readonly B='\033[0;30m'
readonly NC='\033[0m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[0;33m'
readonly GREEN='\033[0;32m'

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
  chmod +x rcdk && sudo cp rcdk /usr/local/bin/rcdk
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

# Generating string from input chars (Internal)
# Example: rcdk_str_gen $length $chars
function rcdk_str_gen {
  rcdk_args_check 2 "$@"
  local length=$1
  local chars=$2
  local password=`LC_ALL=C tr -dc ${chars} < /dev/urandom | head -c ${length}`
  echo $password
}

# Checking runcloud api connection
function rcdk_ping {
  local response=`rcdk_request "ping" "GET"`
  rcdk_parse "$response"
}

# Source files of rcdk functions
if [[ -d "$FUNC_DIR" ]]
then
  files=`ls ${FUNC_DIR}/`
  for file in $files
  do
    source "$FUNC_DIR/$file"
  done
else
  echo -e "${RED}Error: The main rcdk files were not found, please carry out the correct installation of the program!${NC}"
  exit 1
fi

# Init work with rcdk by server_id
# Example: rcdk_init $server_id
function rcdk_init {
  rcdk servers list 1; echo ""
  read -ep "Enter id of the server you want to work with: " server_id
  sed -i "s/server_id=.*/server_id=$server_id/" $API_CONFIG
  echo -e "${GREEN}Successfully switched on $server_id server."
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
  local db_user_pf='_'`rcdk_str_gen 5 'a-z0-9'`
  local db_user_pass=`rcdk_str_gen 32 'A-Za-z0-9_@%^#'`
  local db_username=$db_user$db_user_pf
  local db_name_pf='_'`rcdk_str_gen 5 'a-z0-9'`
  db_name+=$db_name_pf
  rcdk_dbusers_create $db_username $db_user_pass
  echo -e "${YELLOW}Password for user $db_username - $db_user_pass${NC}"
  rcdk_dbs_create $db_name $db_col
  local db_id=`rcdk_dbs_get_id $db_name`
  rcdk_dbusers_attach $db_username $db_id
  rcdk_apps_create
}

# Only run if we're not being sourced
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  rcdk "$@"
fi
