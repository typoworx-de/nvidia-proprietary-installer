# nvidia-proprietary-installer
Automating installations and driver management for nvidia-proprietary driver packages

## installation
Default Install Path is /usr/src/nvidia-proprietary
Default Path for nvidia-proprietary driver-packages is /usr/src/nvidia-proprietary/depot/

### Usage
* Call ./install.sh to install most recent driver version from 'depot'
* Call ./uninstall.sh to uninstall all drivers (/usr/src/nvidia-*) matching a depot-package (NVIDIA-Linux-x86_64-xx.xx.run).
  All versions except most recent will be uninstalled by executing 'NVIDIA-Linux-x86_64-xx.xx.run --uninstall'

