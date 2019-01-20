#!/usr/bin/env bash

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
  if [[ $1 ]]
  then
    rcdk_args_check 3 "$@"
    local label=$1
    local user_name=$2
    local pub_key=$3
    local response=`rcdk_request "servers/$server_id/sshcredentials/" "POST" "{\"label\":\"$label\",\"user\":\"$user_name\",\"publicKey\":\"$pub_key\"}"`
    rcdk_parse "$response"
  else
    local a='y'
    while [[ $a == 'y' ]]
    do
      if [[ -f $KEY_PATH ]]
      then
        local key_file=`cat $KEY_PATH`
        local count=2
        echo -e "${B}=== Add keys to system user ===${NC}"
        echo "1) All"
        while read key
        do
          echo "$count) $key" | awk '{ print $1" "$2 }'
          (( count++ ))
        done < "$KEY_PATH"
        read -ep "Select key numbers to add: " num
        read -ep "Enter a system user name: " user_name
        if [[ $num == '1' ]]
        then
          while read file_line
          do
            local label=`echo "$file_line" | awk '{ print $1 }'`"-$user_name"
            local pub_key=`echo "$file_line" | awk '{ print $2" "$3" "$4 }'`
            local response=`rcdk_request "servers/$server_id/sshcredentials/" "POST" "{\"label\":\"$label\",\"user\":\"$user_name\",\"publicKey\":\"$pub_key\"}"`
            rcdk_parse "$response"
          done < "$KEY_PATH"
        else
          local str_num=$((num-1))
          local str=`sed "${str_num}q;d" "$KEY_PATH"`
          local label=`echo "$str" | awk '{ print $1 }'`"-$user_name"
          local pub_key=`echo "$str" | awk '{ print $2" "$3" "$4 }'`
          local response=`rcdk_request "servers/$server_id/sshcredentials/" "POST" "{\"label\":\"$label\",\"user\":\"$user_name\",\"publicKey\":\"$pub_key\"}"`
          rcdk_parse "$response"
        fi
        read -ep "Add another keys? Type 'y' or 'n': " a
      else
        echo -e "${RED}There are no keys in the vault storage${NC}"
        exit 1
      fi
    done
  fi
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

# Function for add ssh keys to the store
function rcdk_ssh_store_add {
  local a='y'
  while [[ $a == 'y' ]]
  do
    echo -e "${B}=== Add keys to the storage ===${NC}"
    read -ep "Enter a label for the new key: " label
    read -ep "Enter the key: " key
    if [[ -f $KEY_PATH ]]
    then
      echo "$label $key" >> "$KEY_PATH"
    else
      touch $KEY_PATH
      echo "$label $key" >> "$KEY_PATH"
    fi
    echo -e ${GREEN}Key was successfully deleted from storage! ${NC}
    read -ep "Enter another key? Type 'y' or 'n': " a
  done
}

# Function for delete ssh keys from the store
function rcdk_ssh_store_del {
  local a='y'
  while [[ $a == 'y' ]]
  do
    if [[ -f $KEY_PATH ]]
    then
      IFS=$'\n'
      local key_file=`cat $KEY_PATH`
      local count=1
      echo -e "${B}=== Delete keys from the storage ===${NC}"
      for key in $key_file
      do
        echo "$count) $key" | awk '{ print $1" "$2 }'
        (( count++ ))
      done
      read -ep "Select key numbers for delete: " num
      sed -i -e "$num d" "$KEY_PATH"
      echo -e ${GREEN}Key $label successfully added to storage! ${NC}
      read -ep "Enter another key? Type 'y' or 'n': " a
    else
      echo -e "${RED}There are no keys in the vault storage${NC}"
      exit 1
    fi
  done
}

# Main function for ssh keys store
function rcdk_ssh_store {
  echo -e "${B}=== SSH keys store ===${NC}"
  echo -e "${B}1 Add ssh key${NC}"
  echo -e "${B}2 Delete ssh key${NC}"
  read -ep "Enter a command number: " action

  case "$action" in
    "1") rcdk_ssh_store_add "${@:2}";;
    "2") rcdk_ssh_store_del "${@:2}";;
  esac
}