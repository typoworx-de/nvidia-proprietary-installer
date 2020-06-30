#!/bin/bash

gccVersion='';
arch=$(uname -m);
kernelMajorVersion=$(uname -r | grep -oE '^([0-9\.]{1})' | head -n 1);

depotPath=$(dirname $0)"/depot/";
depotFile=$(ls "${depotPath}/NVIDIA-Linux-${arch}"*.run | sort -nr | head -n 1)

if [[ -z "${depotFile}" ]];
then
  echo -e "\e[31mNo NVIDIA-Driver binary release found in depot-directory!\e[0m";
  exit 1;
fi

# switch gcc version
if [[ -z "$gccVersion" ]];
then
  gccVersion=$(find /usr/bin/ -maxdepth 1 -regex '.+\/gcc-[0-9\.]+' | sort -r --version-sort | head -n 1 | grep -oE "[0-9\.]+$");
fi

if [[ ${kernelMajorVersion} -ge 5 ]];
then
  echo -e "\e[34mLinux-Kernel seems to be 5.x Release\e[0m\n";

  if [[ ${gccVersion} -lt 9 ]];
  then
    echo -e "\e[31mCannot found gcc/g++ compiler version >= 9!\e[0m";
    echo -e "\e[33mPlease provide more recent gcc/g++ version if compilation fails!\e[0m\n";
  fi
fi

if [[ -x "/usr/bin/gcc-${gccVersion}" ]];
then
  update-alternatives --set gcc /usr/bin/gcc-${gccVersion}
  update-alternatives --set g++ /usr/bin/g++-${gccVersion}
fi

echo -e "\e[34mInstalling from proprietary package: '$(basename $depotFile)'\e[0m";
sh ${depotFile} -q -a -n -X -s --no-x-check --install-libglvnd --dkms --run-nvidia-xconfig && {
  echo -e "\e[32mDone successfully\e[0m\n";
} || {
  echo -e "\e[31mFailed with errors!\e[0m\n";
}
