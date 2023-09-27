#!/usr/bin/env bash
#
# Title: dev.sh
# Descr: 
# Date : 2023-0-25
# Ver  : 1.0

source "$HOME/bin/common.sh"

BINDIR=$(readlink -f "$(dirname "$0")")

message_alert 'Build Builder'
perl Build.PL --install_base="$HOME" --install_path tmpl="$HOME/.templates" --install_path jars="$HOME/lib/java" > build.log

message_alert 'Installing'
Build install 

