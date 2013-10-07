#!/bin/bash

/usr/bin/acpi -b |& sed -nre 's/^.*[^0-9]([0-9]+)%.*$/\1/; tp; b; :p p'
