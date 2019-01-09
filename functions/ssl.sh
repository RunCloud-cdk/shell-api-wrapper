#!/usr/bin/env bash

# Render SSL info of application (Internal)
function rcdk_ssl_table {
  rcdk_args_check 1 "$@"
  local ssl_id=`echo $1 | jq -r .id`
  if [[ $ssl_id = 'null' ]]
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