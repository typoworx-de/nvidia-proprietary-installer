#!/bin/bash
_pwd=$(pwd)

installerArgs='';

gccVersion='';
arch=$(uname -m);
kernelMajorVersion=$(uname -r | grep -oE '^([0-9\.]{1})' | head -n 1);

depotPath=$(dirname $0)"/depot/";
depotFile=$(ls "${depotPath}/NVIDIA-Linux-${arch}"*.run | sort -r --version-sort | head -n 1)

installedDrivers=$(find /usr/src/ -maxdepth 1 -type d -name 'nvidia*' -not -name 'nvidia-proprietary' | wc -l);

latestKernel=$(dpkg -l | grep -E 'ii[ ]*linux-image-' | sort -r | head -n1 | cut -d' ' -f3);
latestKernelVersion=${latestKernel//linux-image-/}


#installerVersion=$(basename -s '.run' ${depotFile} | cut -d- -f4 | grep -oE '([0-9\.]+)')
installerBase=$(basename -s '.run' ${depotFile})
installerVersion=$(cut -d- -f4 <<< ${installerBase} | grep -oE '([0-9\.]+)')
installerBase=${installerBase//${installerVersion}}
installerSource="${_pwd}/${installerBase}${installerVersion}"

#if [[ $@ =~ " --no-sanity" ]];
#then
#  echo "Disabling sanity-check"
#elif [[ ${installedDrivers} -ge 0 ]];
#then
#  installerArgs+=' --sanity';
#fi

if [[ ! -z "${latestKernelVersion}" ]];
then
  # not working yet :-(
  #installerArgs+=" --kernel-name='${latestKernelVersion}' --kernel-source-path='/usr/src/linux-headers-${latestKernelVersion}'";

  apt-get install -y "linux-headers-${latestKernelVersion}"
fi

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
  gccVersion=$(find /usr/bin/ -maxdepth 1 -regex '.+\/gcc-[0-9\.]+' | sort -n | head -n 1 | grep -oE "[0-9\.]+$");
fi

if [[ ${gccVersion} -lt 11 ]];
then
  kernelVersion=$(uname -r)

  [[ $(grep -c 'CONFIG_SLS=y' /usr/src/linux-headers-${kernelVersion}/.config) -eq 0 ]] || {
    echo "Patching Kernel-Config: disable CONFIG_SLS=y";
    sudo sed -i~nvidia -E 's/^(CONFIG_CC_HAS_SLS=y|CONFIG_SLS=y)$/#\1/' /usr/src/linux-headers-${kernelVersion}/.config
  }
fi

if [[ ${kernelMajorVersion} -ge 5 ]];
then
  echo -e "\e[34mLinux-Kernel seems to be 5.x Release\e[0m\n";

  echo "Switching Compiler-Set to Version ${gccVersion}"

  for compiler in gcc cpp g++;
  do
    [ $(update-alternatives --list ${compiler} | grep -c "${compiler}-${gccVersion}") -eq 0 ] && {
      update-alternatives --install /usr/bin/${compiler} ${compiler} $(which ${compiler}-${gccVersion}) ${gccVersion};
    }

    update-alternatives --set ${compiler} /usr/bin/${compiler}-${gccVersion} || {
      echo "Error: Missing ${compiler}-${gccVersion}!";
      exit 1;
    }
  done
fi

echo -e "\e[34mInstalling from proprietary package: '$(basename ${depotFile})'\e[0m";

# disabled installer args
# --dkms

installer=${depotFile}

[ -f "${installerSource}" ] && {
  installer="${installerSource}/nvidia-installer";
}

#sudo sh ${installer} \
#  -q -a -n -X -s \
#  ${installerArgs} \
#  --no-x-check \
#  --skip-module-unload \
#  --no-rpms \
#  --force-libglx-indirect --install-libglvnd \
#  --disable-nouveau \
#  --run-nvidia-xconfig && \
#{
#  echo -e "\e[32mDone successfully\e[0m\n";
#} || {
#  echo -e "\e[31mFailed with errors!\e[0m\n";
#}

echo "Installing NVIDIA DKMS from ${installerSource} ..."
sudo dkms add ${installerSource}/kernel -m nvidia -v ${installerVersion} || true
sudo dkms install ${installerSource}/kernel -m nvidia -v ${installerVersion} || true

[ -d "${installerSource}" ] && {
  echo "Pruning ${installerSource}"
  echo rm -rf "${installerSource}";
}
