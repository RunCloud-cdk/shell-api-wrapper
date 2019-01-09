#!/usr/bin/env bash

# Color constants
readonly NC='\033[0m'
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'

# Path constants
readonly RCDK_DIR="$HOME/rcdkConfigs"
readonly FUNC_DIR="$RCDK_DIR/functions"

echo -e "${CYAN}Runcloud Shell API Wrapper installation:${NC}"
read -ep "Enter your API KEY: " ak
read -ep "Enter your API SECRET KEY: " ask

# Download and install shell api wrapper
cd && curl -sSL https://raw.githubusercontent.com/RunCloud-cdk/shell-api-wrapper/master/rcdk.sh > rcdk && chmod +x rcdk && sudo mv rcdk /usr/local/bin/rcdk
mkdir ~/rcdkConfigs
printf 'api_key="'$ak'"\napi_secret_key="'$ask'"\nserver_id=' > ~/rcdkConfigs/api.conf

# Copy function files and change permissions
cp -R ./functions $FUNC_DIR

files=`ls ${FUNC_DIR/}`

for file in $files
do
  if [[ -f $file ]]
  then
    chmod +x $file
  fi
done

echo -e "${GREEN}Runcloud Shell API Wrapper was installed successfully!${NC}"

# Check OS for Ubuntu/Debian and install bash completion
ubuntu_check=`cat /etc/os-release | grep "ID=ubuntu"`
debian_check=`cat /etc/os-release | grep "ID=debian"`
if [[ ubuntu_check == '' && debian_check == '' ]]
then
  echo -e "${RED}This script supporting only Ubuntu/Debian bash completion. See manual about your OS bash completion!${NC}"
else
  wget https://raw.githubusercontent.com/RunCloud-cdk/shell-api-wrapper/master/rcdk && sudo mv rcdk /etc/bash_completion.d/
  echo -e "${GREEN}Bash completion was installed successfully!${NC}"
fi

echo -e "${GREEN}This script has been removed from your system!${NC}"
rm -f "$0"