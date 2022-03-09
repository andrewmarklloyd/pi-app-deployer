#!/bin/bash

set -euo pipefail

interactive=${interactive:-}


osRelease=$(cat /etc/os-release)
if [[ "${osRelease}" == *"Raspbian"* ]]; then
  os="Raspbian"
  homeDir="/home/pi"
  arch="arm"
elif [[ "${osRelease}" == *"Ubuntu"* ]]; then
  os="Ubuntu"
  homeDir="/root"
  arch="amd64"
else
  echo "OS not supported"
  exit 1
fi
envFile="${homeDir}/.pi-app-deployer-agent.env"

get_latest_release() {
  curl --silent "https://api.github.com/repos/andrewmarklloyd/pi-app-deployer/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

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

version=$(get_latest_release)
echo "Downloading version ${version} of pi-app-deployer"
curl -sL https://github.com/andrewmarklloyd/pi-app-deployer/releases/download/${version}/pi-app-deployer-agent-${version}-linux-${arch}.tar.gz | tar zx -C /tmp

mv /tmp/pi-app-deployer-agent ${homeDir}/pi-app-deployer-agent

if [[ ${interactive} == "true" ]]; then
  echo "Enter the repo name including the org then press enter:"
  read repo

  echo "Enter the pi-app-deployer manifest name then press enter:"
  read manifestName

  echo
  echo "Running the pi-app-deployer-agent version ${version} installer using the following command:"

  c="${homeDir}/pi-app-deployer-agent --repo-name ${repo} --manifest-name ${manifestName} --install"
  echo "${c}"

  eval ${c}
else
  echo "pi-app-deployer-agent downloaded, run from ${homeDir}/pi-app-deployer-agent"
fi
