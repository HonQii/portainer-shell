# Bash scripts to interact with Portainer

# reference from [Stack Update](https://github.com/docker-how-to/portainer-bash-scripts)

Requires:
* bash (or sh)
* jq
* curl

Usage:

* Set the following environmental variables or edit file and set the authentication details
```bash
P_USER="root" 
P_PASS="password" 
P_URL="http://example.com:9000" 
P_PRUNE="false"
```

* run with
```bash
export P_USER="root" 
export P_PASS="password" 
export P_URL="http://example.com:9000" 
export P_PRUNE="false"
./stack-update.sh mqtt mqtt/docker-compose.yml
```
