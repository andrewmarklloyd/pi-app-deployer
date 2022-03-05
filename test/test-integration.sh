#!/bin/bash

# set -euo pipefail

os="Ubuntu"
homeDir="/home/runner"
envFile="${homeDir}/.pi-app-deployer-agent.env"

if [[ $(whoami) != "root" ]]; then
  echo "Script must be run as root"
  exit 1
fi

if [[ -z ${HEROKU_API_KEY} ]]; then
  echo "HEROKU_API_KEY env var not set, exiting now"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  apt-get update
  apt-get install jq -y
fi

if ! command -v curl &> /dev/null; then
  apt-get update
  apt-get install curl -y
fi

vars=$(curl -s -n https://api.heroku.com/apps/pi-app-deployer/config-vars \
  -H "Accept: application/vnd.heroku+json; version=3" \
  -H "Authorization: Bearer ${HEROKU_API_KEY}")

reqVars="GH_API_TOKEN
PI_APP_DEPLOYER_API_KEY
CLOUDMQTT_AGENT_USER
CLOUDMQTT_AGENT_PASSWORD
CLOUDMQTT_URL"

rm -f ${envFile}
echo "HEROKU_API_KEY=${HEROKU_API_KEY}" > ${envFile}
for key in ${reqVars}; do
  val=$(echo $vars | jq -r ".${key}")
  export "${key}=${val}"
  echo "${key}=${val}" >> ${envFile}
done

mv /home/runner/work/pi-app-deployer/pi-app-deployer-agent /home/runner
/home/runner/pi-app-deployer-agent --repo-name ${repo} --manifest-name ${manifestName} --install
pwd
ls -al ${homeDir}
ls -al /etc/systemd/system/
cat /etc/systemd/system/pi-app-deployer-agent.service
journalctl -u pi-app-deployer-agent.service -f &
sleep 10
#           XDG_RUNTIME_DIR=/run/user/$UID systemctl --user enable --now webserver.service
