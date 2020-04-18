#!/bin/bash

# *****************************************************************************
# Publish the gem to rubygems server
# *****************************************************************************

# Number of arguments
if [ "$#" != "0" ]; then
	echo "Usage: $0"
	exit 1
fi

# Basic setting
script_dir="`cd \"\`dirname \\\"$0\\\"\`\"; pwd`"
root_dir="$script_dir/.."
build_dir="$root_dir/build"

# Push to rubygems
gem push "$build_dir"/dibbler-*
