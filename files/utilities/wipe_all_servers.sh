#!/bin/bash

for a in `ironic node-list |head -n -1|tail -n +4|cut -d "|" -f2|tr -d " "`; do
  sudo mysql ironic -e "update nodes set provision_state='available' where  uuid='"$a"'"
  ironic node-delete "$a"
done
