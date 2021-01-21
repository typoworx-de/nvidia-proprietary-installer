#!/bin/bash

declare -a installerArgs=(
  -X
  --silent
  --dkms
  --no-precompiled-interface
  --accept-license
  --no-questions
  --no-backup
  --no-x-check
  --no-questions
  --skip-module-unload
  --no-rpms
  --glvnd-glx-client
  --glvnd-egl-client
  --force-libglx-indirect
  --install-libglvnd
  --disable-nouveau
  --opengl-headers
  --no-cc-version-check
  --run-nvidia-xconfig
);

gccVersion='';
arch=$(uname -m);
kernelMajorVersion=$(uname -r | grep -oE '^([0-9\.]{1})' | head -n 1);

depotPath=$(realpath $(dirname $0)"/depot/");
depotFile=$(ls "${depotPath}/NVIDIA-Linux-${arch}"*.run | sort -r --version-sort | head -n 1)

installedDrivers=$(find /usr/src/ -maxdepth 1 -type d -name 'nvidia*' -not -name 'nvidia-proprietary' | wc -l);

#if [[ $@ =~ " --no-sanity" ]];
#then
#  echo "Disabling sanity-check"
#elif [[ ${installedDrivers} -ge 0 ]];
#then
#  installerArgs+=' --sanity';
#fi

if [[ -z "${depotFile}" ]];
then
  echo -e "\e[31mNo NVIDIA-Driver binary release found in depot-directory!\e[0m";
  exit 1;
fi


if [[ ! " $@ " = *" -q "* ]];
then
  echo
  ls -t1 "${depotPath}";
  echo

  read -p "Start Update with Depot-File ${depotFile}? " -n 1 -r
  echo    # (optional) move to a new line

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    exit 1;
  fi
fi


# switch gcc version
if [[ -z "$gccVersion" ]];
then
  gccVersion=$(find /usr/bin/ -maxdepth 1 -regex '.+\/gcc-[0-9\.]+' | sort -nr | head -n 1 | grep -oE "[0-9\.]+$");
fi

if [[ ${kernelMajorVersion} -ge 5 ]];
then
  echo -e "\e[34mLinux-Kernel seems to be 5.x Release\e[0m\n";

  if [[ ${gccVersion} -lt 9 ]];
  then
    echo -e "\e[31mCannot found gcc/g++ compiler version >= 9!\e[0m";
    echo -e "\e[33mPlease provide more recent gcc/g++ version if compilation fails!\e[0m\n";

    echo "Try this:";
    echo "sudo update-alternatives --install /usr/bin/gcc gcc $(which gcc-9) 5"
    echo "sudo update-alternatives --install /usr/bin/g++ g++ $(which g++-9) 5";
    echo "sudo update-alternatives --install /usr/bin/cpp cpp $(which cpp-9) 5)";
    exit 1;
  fi

  sudo update-alternatives --install /usr/bin/gcc gcc $(which gcc-9) 5;
  sudo update-alternatives --install /usr/bin/g++ g++ $(which g++-9) 5;
fi

if [[ -x "/usr/bin/gcc-${gccVersion}" ]];
then
  sudo update-alternatives --set gcc /usr/bin/gcc-${gccVersion} || echo "Failed setting gcc-${gccVersion} active!";
  sudo update-alternatives --set g++ /usr/bin/g++-${gccVersion} || echo "Failed setting g++-${gccVersion} active!";
  sudo update-alternatives --set cpp /usr/bin/cpp-${gccVersion} || echo "Failed setting cpp-${gccVersion} active!";
fi


function array_join { local IFS="$1"; shift; echo "$*"; }

echo -e "\e[34mInstalling from proprietary package: '$(basename ${depotFile})'\e[0m";

# disabled installer args
# --dkms
# --no-precompiled-interface

pwd=$(pwd);
tmpPath=$(realpath $(dirname 0)/tmp);

test -d "${tmpPath}" && rm -rf ${tmpPath}/* || mkdir "${tmpPath}";
cd "${tmpPath}";

depotDir=$(basename ${depotFile});
depotDir=${depotDir/.run/};

sudo sh ${depotFile} --extract-only || { echo "Error extracting depot-file!"; exit 1; }
cd ${tmpPath}/${depotDir} || exit 1;

sudo ${tmpPath}/${depotDir}/nvidia-installer $(array_join " " ${installerArgs[@]}) --dkms ${installerArgs} && {
  echo -e "\e[32mDone successfully\e[0m\n";
} || {
  sudo ${tmpPath}/${depotDir}/nvidia-installer $(array_join " " ${installerArgs[@]}) ${installerArgs} && {
    echo -e "\e[32mDone successfully (without DKMS!)\e[0m\n";
  } || {
    echo -e "\e[31mFailed with errors (without DKMS)!\e[0m\n";
  }
}
