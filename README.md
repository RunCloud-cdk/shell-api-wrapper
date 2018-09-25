# shell-api-wrapper
Shell wrapper for the runcloud.io API https://runcloud.io/

## ToDo
- [ ] Main sections
  - [x] Requirements
  - [ ] Authentication
  - [x] Installation
  - [x] Initialization
  - [x] List of features
  - [ ] List of commands and arguments

## Requirements
- [Curl](https://github.com/curl/curl)
- [jq](https://github.com/stedolan/jq) (version 1.5 or later)

## Installation
Replace `API KEY` and `API SECRET KEY` to your credentials, then run the following commands:
```bash
$ cd && curl -sSL https://raw.githubusercontent.com/RunCloud-cdk/shell-api-wrapper/master/rcdk.sh > rcdk && chmod +x rcdk && sudo cp rcdk /usr/local/bin/rcdk
$ ak="API KEY"; ask="API SECRET KEY"; printf '\nexport api_key="'$ak'"\nexport api_secret_key="'$ask'"\nexport server_id=' >> .bashrc && source .bashrc
```
Empty `server_id` in a second command will needed for the next step.\
Next you can run `rcdk ping` for a testing connection with API.

## Initialization
The Runcloud API requires you to pass the `server_id` on each request (in addition to the `ping` command and some of the `servers` commands).
Therefore it was decided that before you start working with the API it is better to initialize work with a specific server.

Run `rcdk init`. The program will show the list of servers and offer to choose one of them by entering `server id`.

##Features
After the server has been selected, you can start working with most of the features from the API:

### System users
- Create new system user
- Delete exists system user
- Get list of all system users
- Change passwd for a system user

### Servers
- Add new server to Runcloud
- Delete exists server from Runcloud
- List of all your servers

### Services
- List of all services installed on a selected server
- Actions with services

### Apps
- Create a new web application
- Delete exists web application
- View one page of web application list or search them by chars

### Databases
- Create a new database
- Delete exists database
- View one page of databases list or search them by chars

### Database users
- Create a new database user
- Delete exists database user
- view one page of database users list or search them by chars
- Attach database user to database
- Revoke database user from database
- change password for the database user

### Domains
- Show list of domains for the web application
- Add new domain name for the web application
- Delete domain name from the web application by id

### SSL certificates
- Show info about SSL sertificate
- On SSL for the web application
- Update SSL for the web application
- Off SSL for the web application

### SSH keys
- Add SSH public key to the system user of selected server
- Delete exists public key by id
- Show list of all pubic keys of the selected server