#!/usr/bin/env bash
# Color constants
readonly NC="\e[39m"
readonly RED="\e[31m"
readonly GREEN="\e[92m"
readonly CYAN="\e[36m"

echo -e "${CYAN}Runcloud Shell API Wrapper installation:${NC}"
read -ep "Enter your API KEY: " ak
read -ep "Enter your API SECRET KEY: " ask

# Download and install shell api wrapper
cd && curl -sSL https://raw.githubusercontent.com/RunCloud-cdk/shell-api-wrapper/master/rcdk.sh > rcdk && chmod +x rcdk && sudo mv rcdk /usr/local/bin/rcdk
printf 'api_key="'$ak'"\napi_secret_key="'$ask'"\nserver_id=' > ~/rcdk.conf
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