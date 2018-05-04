#!/bin/bash


if hostname -s | md5sum | grep -qF $'773a2038b8bfe5ca064e8de03079e711\n33c4ca47bb83c1b193620757dd9a7231'; then
  functions_to_render_prompt+=( render_no_ssh_profiles )
fi
