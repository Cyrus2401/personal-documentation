#!/usr/bin/env bash

# ================================================================
#  debian-system-update.sh — Debian system update script
#  Update package list · Full upgrade · Autoremove · Autoclean
#  Auteur : HESSOU Cyrus
#  Usage  : sudo ./debian-system-update.sh
# ================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    echo "Use: sudo ./debian-system-update.sh"
    exit 1
fi

echo "-----------------------------------"
echo "   Debian system update            "
echo "-----------------------------------"

echo "Updating package list..."
apt update

echo "Performing full system upgrade..."
apt full-upgrade -y

echo "Removing unused packages..."
apt autoremove --purge -y

echo "Cleaning APT cache..."
apt autoclean

echo "Checking for remaining upgradable packages..."
UPDATES=$(apt list --upgradable 2>/dev/null | tail -n +2 | wc -l)

if [ "$UPDATES" -eq 0 ]; then
    echo "System is fully up to date."
else
    echo "There are $UPDATES packages still available for upgrade."
    echo "Run: sudo apt upgrade to install them."
fi

echo "-----------------------------------"
echo "   Script completed                "
echo "-----------------------------------"
