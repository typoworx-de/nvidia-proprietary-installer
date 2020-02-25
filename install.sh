#!/bin/bash

arch=$(uname -m);
depotPath='/usr/src/nvidia-proprietary/depot';
depotFile=$(ls "${depotPath}/NVIDIA-Linux-${arch}"*.run | sort -nr | head -n 1)

echo -e "\e[34mInstalling from proprietary package: '$(basename $depotFile)'\e[0m";
sh ${depotFile} -q -a -n -X -s --install-libglvnd --dkms --run-nvidia-xconfig && {
  echo -e "\e[32mDone successfully\e[0m\n";
} || {
  echo -e "\e[31mFailed with errors!\e[0m\n";
}
