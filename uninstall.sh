#!/bin/bash

arch=$(uname -m);
depotPath=$(dirname $0)"/depot/";

force=0;
if [[ $@ =~ '--force' ]];
then
  echo "Forced uninstall!";
  force=1;
fi

counter=0;
for package in $(find /usr/src/ -maxdepth 1 -type d -name 'nvidia*' -not -name 'nvidia-proprietary' | sort -nr);
do
  ((counter=counter+1))

  packageBasename=$(basename $package);
  packageVersion=${packageBasename/nvidia-/};

  if [[ $force == 0 && $counter == 1 ]];
  then
    echo -e "\e[93mSkipping current version: $packageVersion\e[0m";
    continue;
  fi

  depotFile="${depotPath}/NVIDIA-Linux-${arch}-${packageVersion}.run";

  if [[ ! -f "${depotFile}" ]];
  then
    echo -e "\e[31mNo proprietary package found matching ${packageVersion} (${depotFile})\e[0m";
    continue;
  fi

  echo -e "\e[94mUninstalling from proprietary package: ${packageVersion}\e[0m";
  sh ${depotFile} -q -a -n -X -s --uninstall;
done

if [[ $counter -eq 0 ]];
then
  echo -e "\e[31mNo nvidia-driver found (/usr/src/nvidia-*)!\e[0m";
  exit;
fi
