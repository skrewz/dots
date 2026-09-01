# Tests for the pi extensions.
#
# The detection logic in ../extensions/command-gate.ts is exercised two ways:
#   - command-gate.test.ts   unit tests for the pure detection functions
#   - command-gate.smoke.ts  end-to-end: simulate pi loading the extension and
#                            firing tool_call events
#
# They are run with pi's bundled jiti loader — the same loader pi uses to load
# extensions — so module resolution matches what pi actually does. (Plain
# `node` cannot run them: native type-stripping does not resolve the
# extensionless `../extensions/command-gate` import.)
#
# Usage (from anywhere):
#   make -C .pi/agent/extensions-tests test
#
# Override the loader if your pi install lives elsewhere:
#   JITI=/path/to/jiti make -C .pi/agent/extensions-tests test

# pi's bundled jiti (override with JITI=... if needed).
JITI ?= /home/skrewz/node_modules/@earendil-works/pi-coding-agent/node_modules/.bin/jiti

# Directory containing this Makefile (with trailing slash).
HERE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: test
test:
	$(JITI) $(HERE)command-gate.test.ts
	$(JITI) $(HERE)command-gate.smoke.ts
