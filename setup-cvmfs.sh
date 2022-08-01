#!/usr/bin/env bash

#Platform specific install
if [ "$(uname)" == "Linux" ]; then
  CVMFS_RELEASE_LATEST=/var/cache/apt/archives/cvmfs-release-latest_all.deb
  if [ ! -f ${CVMFS_RELEASE_LATEST} ] ; then
    curl -L -o ${CVMFS_RELEASE_LATEST} ${CVMFS_UBUNTU_DEB_LOCATION}
  fi
  sudo dpkg -i ${CVMFS_RELEASE_LATEST}
  rm -f ${CVMFS_RELEASE_LATEST}
  sudo apt-get -q update
  sudo apt-get -q -y install cvmfs
  if [ "${CVMFS_CONFIG_PACKAGE}" == "cvmfs-config-default" ]; then
    sudo apt-get -q -y install cvmfs-config-default
  else
    curl -L -o cvmfs-config.deb ${CVMFS_CONFIG_PACKAGE}
    sudo dpkg -i cvmfs-config.deb
    rm -f cvmfs-config.deb
  fi
elif [ "$(uname)" == "Darwin" ]; then
  # Temporary fix for macOS until cvmfs 2.8 is released
  if [ -z "${CVMFS_HTTP_PROXY}" ]; then
    export CVMFS_HTTP_PROXY='DIRECT'
  fi
  brew install --cask macfuse
  curl -L -o cvmfs-latest.pkg ${CVMFS_MACOS_PKG_LOCATION}
  sudo installer -package cvmfs-latest.pkg -target /
else
  echo "Unsupported platform"
  exit 1
fi

if [ "$1" == "local" ]; then
  . createConfig.sh
else
  $THIS/createConfig.sh
fi

echo "Run cvmfs_config setup"
sudo cvmfs_config setup
retCongif=$?
if [ $retCongif -ne 0 ]; then
  echo "!!! github-action-cvmfs FAILED !!!"
  echo "cvmfs_config setup exited with ${retCongif}"
  exit $retCongif
fi


if [ "$(uname)" == "Darwin" ]; then
  for repo in $(echo ${CVMFS_REPOSITORIES} | sed "s/,/ /g")
  do
    mkdir -p /Users/Shared/cvmfs/${repo}
    sudo mount -t cvmfs ${repo} /Users/Shared/cvmfs/${repo}
  done
fi
