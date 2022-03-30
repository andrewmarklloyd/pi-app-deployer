#!/bin/bash

set -euo pipefail

# TODO: move this to install script?

workDir="/home/runner/work/pi-app-deployer/pi-app-deployer"
envFile="/usr/local/src/.pi-app-deployer-agent.env"

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

rm -f ${envFile}
echo "HEROKU_API_KEY=${HEROKU_API_KEY}" > ${envFile}

mv ${workDir}/pi-app-deployer-agent /usr/local/src/
/usr/local/src/pi-app-deployer-agent install --appUser runneradmin --repoName ${repo} --manifestName ${manifestName} --envVar MY_CONFIG=testing --logForwarding

grep "MY_CONFIG\=testing" /usr/local/src/.pi-test-amd64.env >/dev/null
diff test/test-int-appconfigs.yaml /usr/local/src/.pi-app-deployer.appconfigs.yaml

sleep 10
journalctl -u pi-app-deployer-agent.service
journalctl -u pi-test-amd64.service
# systemctl is-active --quiet pi-app-deployer-agent.service || echo "pi-app-deployer-agent is not active" && exit 1
# systemctl is-active --quiet pi-test-amd64.service || echo "pi-test-amd64 is not active" && exit 1


# git push to pi-test, check for new commit
