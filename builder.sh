#!/bin/sh -eu
set -o pipefail
PATH=/bin:/usr/bin

pwd
env

loadBuildTools() {
	local tool
	for tool in ${buildTools:-} ; do
		source $tool/builder.sh
	done
}

runPhase() {
	local phase="$1"
	echo "$phase"
        eval "${!phase:-$phase}"
}

stage() {
	local s
	for s in ${src:-} ; do
		tar xf "$s"
	done
}

patch() {
	:
}

build() {
	loadBuildTools

	local phase
	for phase in stage patch ${phases:-} ; do
		runPhase $phase
	done
}

build
