#!/usr/bin/env bash
echo "Checking for broken symlinks..."
pushd staging_dir/host/bin
if broken_links=$(find . -xtype l -print); then 
    if [ -n "$broken_links" ]; then 
        echo "WARNING: Broken symlinks found:"; 
        echo "$broken_links"; 
        exit 1; 
    else 
        echo "No broken symlinks found."; 
    fi
else 
    echo "Error searching for symlinks."; 
    exit 1; 
fi        