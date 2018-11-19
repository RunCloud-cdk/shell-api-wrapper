# shell-api-wrapper
Shell wrapper for the runcloud.io API https://runcloud.io/

## Requirements
- [Curl](https://github.com/curl/curl)
- [jq](https://github.com/stedolan/jq) (version 1.5 or later)

## Installation
Run installation command and follow the instructions:
```bash
wget https://raw.githubusercontent.com/RunCloud-cdk/shell-api-wrapper/master/install.sh && chmod +x install.sh && ./install.sh
```
After the installation will be created a config file named `rcdk.conf` in the user home directory.\
Now you can run `rcdk ping` to test the API connection.

## Initialization
The Runcloud API requires you to pass the `server_id` on each request (in addition to the `ping` command and some of the `servers` commands).
Therefore it was decided that before you start working with the API it is better to initialize work with a specific server.

Run `rcdk init`. The program will show the first page of server list and offer to choose one of them by entering `server id`.
To show any page watch [List of all your servers](https://github.com/RunCloud-cdk/shell-api-wrapper#list-of-all-your-servers)`.

## Bash completion
This function supporting only Ubuntu/Debian users with bash interpreter.\
See [GNU documentation](https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion.html) for more info about bash completion.

## Available features
After the server has been selected, you can start working with most of the features from the API:

### System users
- [Create new system user](https://github.com/RunCloud-cdk/shell-api-wrapper#create-new-system-user)
- [Delete exists system user](https://github.com/RunCloud-cdk/shell-api-wrapper#delete-exists-system-user)
- [Get list of all system users](https://github.com/RunCloud-cdk/shell-api-wrapper#get-list-of-all-system-users)
- [Change passwd for a system user](https://github.com/RunCloud-cdk/shell-api-wrapper#change-passwd-for-a-system-user)

### Servers
- [Add new server to Runcloud](https://github.com/RunCloud-cdk/shell-api-wrapper#add-new-server-to-runcloud)
- [Delete exists server from Runcloud](https://github.com/RunCloud-cdk/shell-api-wrapper#delete-exists-server-from-runcloud)
- [Show server hardware info](https://github.com/RunCloud-cdk/shell-api-wrapper#show-server-hardware-info)
- [List of all your servers](https://github.com/RunCloud-cdk/shell-api-wrapper#list-of-all-your-servers)

### Services
- [List of all services installed on a selected server](https://github.com/RunCloud-cdk/shell-api-wrapper#list-of-all-services-installed-on-a-selected-server)
- [Actions with services](https://github.com/RunCloud-cdk/shell-api-wrapper#actions-with-services)

### Apps
- [Create a new web application](https://github.com/RunCloud-cdk/shell-api-wrapper#create-a-new-web-application)
- [Delete exists web application](https://github.com/RunCloud-cdk/shell-api-wrapper#delete-exists-web-application)
- [View one page of web application list](https://github.com/RunCloud-cdk/shell-api-wrapper#view-one-page-of-web-application-list)

### Databases
- [Create a new database](https://github.com/RunCloud-cdk/shell-api-wrapper#create-a-new-database)
- [Delete exists database](https://github.com/RunCloud-cdk/shell-api-wrapper#delete-exists-database)
- [View one page of databases list](https://github.com/RunCloud-cdk/shell-api-wrapper#view-one-page-of-databases-list)

### Database users
- [Create a new database user](https://github.com/RunCloud-cdk/shell-api-wrapper#create-a-new-database-user)
- [Delete exists database user](https://github.com/RunCloud-cdk/shell-api-wrapper#delete-exists-database-user)
- [view one page of database users list](https://github.com/RunCloud-cdk/shell-api-wrapper#view-one-page-of-database-users-list)
- [Attach database user to database](https://github.com/RunCloud-cdk/shell-api-wrapper#attach-database-user-to-database)
- [Revoke database user from database](https://github.com/RunCloud-cdk/shell-api-wrapper#revoke-database-user-from-database)
- [Change password for the database user](https://github.com/RunCloud-cdk/shell-api-wrapper#change-password-for-the-database-user)

### Domains
- [Show list of domains for the web application](https://github.com/RunCloud-cdk/shell-api-wrapper#show-list-of-domains-for-the-web-application)
- [Add new domain names for the web application](https://github.com/RunCloud-cdk/shell-api-wrapper#add-new-domain-names-for-the-web-application)
- [Delete domain name from the web application by id](https://github.com/RunCloud-cdk/shell-api-wrapper#delete-domain-name-from-the-web-application-by-id)

### SSL certificates
- [Show info about SSL sertificate](https://github.com/RunCloud-cdk/shell-api-wrapper#show-info-about-ssl-sertificate)
- [On SSL for the web application](https://github.com/RunCloud-cdk/shell-api-wrapper#on-ssl-for-the-web-application)
- [Update SSL for the web application](https://github.com/RunCloud-cdk/shell-api-wrapper#update-ssl-for-the-web-application)
- [Off SSL for the web application](https://github.com/RunCloud-cdk/shell-api-wrapper#off-ssl-for-the-web-application)

### SSH keys
- [Add SSH public key to the system user of selected server](https://github.com/RunCloud-cdk/shell-api-wrapper#add-ssh-public-key-to-the-system-user-of-selected-server)
- [Delete exists public key by id](https://github.com/RunCloud-cdk/shell-api-wrapper#delete-exists-public-key-by-id)
- [Show list of all pubic keys of the selected server](https://github.com/RunCloud-cdk/shell-api-wrapper#show-list-of-all-pubic-keys-of-the-selected-server)

## System users
### Create new system user
```bash
rcdk sysusers create $name $password
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| name | Name of the system user. | yes |
| password | Password for the system user. If leave blank this field then password will be generated automaticly. | no |
### Delete exists system user
```bash
rcdk sysusers delete $name $id
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| name | Name of the system user. | yes |
| id | ID of the system user. | yes |
### Get list of all system users
```bash
rcdk sysusers list $string || rcdk sysusers list $number
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| string | Search string for the list. | yes |
| number | The page number of the list. | yes |
### Change passwd for a system user
```bash
rcdk sysusers passwd $id $password
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| id | ID of the system user. | yes |
| password | Password for the system user. If leave blank this field then password will be generated automaticly. | no |

## Servers
### Add new server to Runcloud
```bash
rcdk servers add $name $ip $provider
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| name | Server name. | yes |
| ip |IP address of the new server. | yes |
| provider | Hoster of the new server. | no |
### Delete exists server from Runcloud
```bash
rcdk servers delete $id
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| id | ID of the server. | yes |
### Show server hardware info
```bash
rcdk servers info
```
### List of all your servers
```bash
rcdk servers list $string || rcdk servers list $number
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| string | Search string for the list. | yes |
| number | The page number of the list. | yes |

## Services
### List of all services installed on a selected server
```bash
rcdk services list
```
### Actions with services
```bash
rcdk services $action
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| action | A command for a service like `start`, `stop`, `restart` or `reload`. | yes |

## Apps
### Create a new web application
```bash
rcdk apps create
```
This command asks you for all the arguments.
### Delete exists web application
```bash
rcdk apps delete $name $id
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| name | Name of the web application. | yes |
| id | ID of the web application. | yes |
### View one page of web application list
```bash
rcdk apps list $string || rcdk apps list $number
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| string | Search string for the list. | yes |
| number | The page number of the list. | yes |

## Databases
### Create a new database
```bash
rcdk dbs create $name $collation
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| name | Name of the database. | yes |
| collation | Collation of the database. | no |
### Delete exists database
```bash
rcdk dbs delete $name $id
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| name | Name of the database. | yes |
| id | ID of the database. | no |
### View one page of databases list
```bash
rcdk dbs list $string || rcdk dbs list $number
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| string | Search string for the list. | yes |
| number | The page number of the list. | yes |

## Database users
### Create a new database user
```bash
rcdk dbusers create $name $pass
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| name | Name of the database user. | yes |
| pass | Password for the database user. If leave blank this field then password will be generated automaticly. | no |
### Delete exists database user
```bash
rcdk dbusers delete $name $id
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| name | Name of the database user. | yes |
| id | ID of the database user. | yes |
### view one page of database users list
```bash
rcdk dbusers list $string || rcdk dbusers list $number
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| string | Search string for the list. | yes |
| number | The page number of the list. | yes |
### Attach database user to database
```bash
rcdk dbusers attach $name $id
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| name | Name of the database user. | yes |
| id | ID of the database. | yes |
### Revoke database user from database
```bash
rcdk dbusers revoke $name $id
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| name | Name of the database user. | yes |
| id | ID of the database. | yes |
### Change password for the database user
```bash
rcdk dbusers passwd $id $pass
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| id | ID of the database user. | yes |
| pass | Password for the database user. If leave blank this field then password will be generated automaticly. | no |

## Domains
### Show list of domains for the web application
```bash
rcdk dns list $id
```
| parameter | Description | Required |
|:----:|:----:|:----------:|
| id | ID of the web application. | yes |
### Add new domain names for the web application
```bash
rcdk dns add $id $name_1 $name_n
```
| parameter | Description | Required |
|:----:|:----:|:----------:|
| id | ID of the web application. | yes |
| name | New domain name for the application. | yes |
### Delete domain name from the web application by id
```bash
rcdk dns delete $app_id $domain_id
```
| parameter | Description | Required |
|:----:|:----:|:----------:|
| app_id | ID of the web application. | yes |
| domain_id | ID of the domain name. | yes |

## SSL certificates
### Show info about SSL sertificate
```bash
rcdk ssl info $id
```
| parameter | Description | Required |
|:----:|:----:|:----------:|
| id | ID of the web application. | yes |
### On SSL for the web application
```bash
rcdk ssl on $id
```
| parameter | Description | Required |
|:----:|:----:|:----------:|
| id | ID of the web application. | yes |
### Update SSL for the web application
```bash
rcdk ssl update $app_id $ssl_id
```
| parameter | Description | Required |
|:----:|:----:|:----------:|
| app_id | ID of the web application. | yes |
| ssl_id | ID of the ssl sertficate for the web application. | yes |
### Off SSL for the web application
```bash
rcdk ssl off $app_id $ssl_id
```
| parameter | Description | Required |
|:----:|:----:|:----------:|
| app_id | ID of the web application. | yes |
| ssl_id | ID of the ssl sertficate for the web application. | yes |

## SSH keys
### Add SSH public key to the system user of selected server
```bash
rcdk  ssh add $label $name $pub_key
```
| parameter | Description | Required |
|:----:|:----:|:----------:|
| label | Label of this key in the web interface. | yes |
| name | The name of the system user to which the public key will bound. | yes |
| pub_key | Public key. WARNING: The key must be written in apostrophes!. | yes |
### Delete exists public key by id
```bash
rcdk ssh delete $label $key_id
```
| parameter | Description | Required |
|:----:|:----:|:----------:|
| label | Label of this key in the web interface. | yes |
| key_id | ID of the ssh key. | yes |
### Show list of all pubic keys of the selected server
```bash
rcdk ssh list $string || rcdk ssh list $number
```
| parameter | Description |Required|
|:----:|:----:|:----------:|
| string | Search string for the list. | yes |
| number | The page number of the list. | yes |