#!/bin/bash

# *****************************************************************************
# Create a new version
# *****************************************************************************

# Number of arguments
if [ "$#" != "1" ]; then
	echo "Usage: $0 <version>"
	exit 1
fi

# Basic setting
script_dir="`cd \"\`dirname \\\"$0\\\"\`\"; pwd`"
root_dir="$script_dir/.."

# Versions
production_version="$1"
development_version="$1.dev"
current_version=`cat "$root_dir/VERSION"`

# Config git
git config user.email "matej.outly@gmail.cz"
git config user.name "Matěj Outlý"

if [ "$production_version" != "$current_version" ]; then

	# Handle production version
	echo "$production_version" > "$root_dir/VERSION"
	git add "$root_dir/VERSION"
	git commit --message "Production version V$production_version"
	git tag --annotate "V$production_version" --message "Production version V$production_version"

	# Build and publish gems
	$script_dir/clean.sh
	$script_dir/build.sh
	$script_dir/publish.sh

	# Handle development version
	echo "$development_version" > "$root_dir/VERSION"
	git add "$root_dir/VERSION"
	git commit --message "Development version V$development_version"

fi
