#!/bin/bash

if [ "773a2038b8bfe5ca064e8de03079e711  -" = "$(hostname -s | md5sum)" ]; then
  functions_to_render_prompt+=( render_no_ssh_profiles )
fi
