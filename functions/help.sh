#!/usr/bin/env bash

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