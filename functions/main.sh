#!/usr/bin/env bash

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
    "check") rcdk_servers_check "${@:2}";;
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
    "store") rcdk_ssh_store "${@:2}";;
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
    *) echo -e "${RED}Error: Command not found. Use the 'rcdk help' command for detailed information.${NC}";;
  esac
}