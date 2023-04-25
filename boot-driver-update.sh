#!/bin/bash
_dir=$(realpath $(dirname $0));
_self=$(realpath $(basename $0));

function syntax()
{
  echo "$(basename $0) [install|uninstall|enable|disable|update]";
  echo
  exit 1;
}

function _logger()
{
  level="syslog.notice";

  if [ "$#" -ne 1 ];
  then
    level="syslog.${1}";
    message="${@: -1}";
  else
    message="$@";
  fi

  tee >(logger "${level}") <<< "${message}"
}

function installService()
{
  sudo tee /etc/systemd/system/nvidia-update-agent.service 1> /dev/null << EOL
[Unit]
Description=NVIDIA Update-Agent

[Service]
Type=oneshot
ExecStart=${_self} update-runner
ExecStartPost=${_self} disable

[Install]
WantedBy=multi-user.target
EOL
}

function uninstallService()
{
  sudo systemctl disable nvidia-update-agent.service && \
  sudo rm /etc/systemd/system/nvidia-update-agent.service && \
  _logger info "NVIDIA Update-Agent has been uninstalled.";
}

function enableUpdate()
{
  sudo systemctl enable nvidia-update-agent.service && \
  _logger info "NVIDIA Update-Agent enabled for next boot.";
}

function disableUpdate()
{
  sudo systemctl disable nvidia-update-agent.service && \
  _logger info "NVIDIA Update-Agent disabled.";
}

function runUpdate()
{
  _logger info "Running NVIDIA Update-Agent";
  [[ -f "${_dir}/install.sh" ]] || {
    _logger error "Update-Script: '${_dir}/install.sh' not found!";
    exit 1;
  }

  ${_dir}/install.sh -q || {
    _logger error "Update failed!";
    exit 1;
  }
}


case "${1}" in
  install)
    installService;;

  uninstall)
    uninstallService;;

  enable|update)
    _logger info "NVIDIA Update-Agent is queued for next reboot";
    enableUpdate;;

  disable)
    disableUpdate;;

  update-runner)
    runUpdate;;

  *) syntax;;
esac
