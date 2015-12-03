#!/bin/bash

sudo mysql ironic -e "update nodes set provision_state='available' where  uuid='"$1"'"
ironic node-delete "$1"
