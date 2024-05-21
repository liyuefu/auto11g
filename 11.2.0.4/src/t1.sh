#!/usr/bin/env bash
DIR="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
source "$DIR/../src/lib/oralib.sh"
#
# user=`whoami`
# echo $user
# check_root $user
# if [ $? -eq 0 ]; then
#   echo "root"
# else
#   echo "$user, not root"
# fi
check_root `whoami` && msg_ok "yes, root" || msg_error "please run with root"; exit 1
