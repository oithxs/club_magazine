#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -eu

if [ $(id -u) == 0 ] ; then

    # Handle username change. Since this is cheap, do this unconditionally
    echo "Set username to: $NB_USER"
    usermod -d /home/$NB_USER -l $NB_USER user

    # handle home and working directory if the username changed
    if [[ "$NB_USER" != "user" ]]; then
        # changing username, make sure homedir exists
        # (it could be mounted, and we shouldn't create it if it already exists)
        if [[ ! -e "/home/$NB_USER" ]]; then
            echo "Relocating home dir to /home/$NB_USER"
            mv /home/user "/home/$NB_USER"
        fi
        # if workdir is in /home/user, cd to /home/$NB_USER
        if [[ "$PWD/" == "/home/user/"* ]]; then
            newcwd="/home/$NB_USER/${PWD:13}"
            echo "Setting CWD to $newcwd"
            cd "$newcwd"
        fi
    fi

    # Change UID of NB_USER to NB_UID if it does not match
    if [ "$NB_UID" != $(id -u $NB_USER) ] ; then
        echo "Set $NB_USER UID to: $NB_UID"
        usermod -u $NB_UID $NB_USER
    fi

    # Change GID of NB_USER to NB_GID if NB_GID is passed as a parameter
    if [ "$NB_GID" ] ; then
        echo "Set $NB_USER GID to: $NB_GID"
        groupmod -g $NB_GID -o $(id -g -n $NB_USER)
    fi

    echo "Execute the command: $*"
    exec su $NB_USER -c "env PATH=$PATH $*"
else
    if [[ ! -z "$NB_UID" && "$NB_UID" != "$(id -u)" ]]; then
        echo 'Container must be run as root to set $NB_UID'
    fi
    if [[ ! -z "$NB_GID" && "$NB_GID" != "$(id -g)" ]]; then
        echo 'Container must be run as root to set $NB_GID'
    fi
    # Exec the command
    echo "Execute the command: $*"
    exec $*
fi
