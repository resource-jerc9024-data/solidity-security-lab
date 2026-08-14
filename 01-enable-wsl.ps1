#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

Write-Host 'Enabling Windows Subsystem for Linux and Virtual Machine Platform...'
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart

Write-Host 'Installing Ubuntu...'
wsl.exe --install -d Ubuntu

Write-Host ''
Write-Host 'Restart Windows. After restart, open Ubuntu once and create your Linux username/password.'
Write-Host 'Then run 02-setup-audit.sh from Ubuntu as described in SETUP.md.'
