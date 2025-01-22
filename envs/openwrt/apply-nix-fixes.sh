#!/usr/bin/env bash

# Nix fixes for OpenWrt environment
echo "Welcome to OpenWrt Build Shell!"
echo "Checking for broken symlinks in staging_dir/host/bin"
# Check if a directory exists
if [ -d "./staging_dir/host/bin" ]; then
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
  else
    echo "OK. (Directory does not exist yet)"
  fi


echo "Injecting LLVM path to .config"        
if [ -z "$LLVM_HOST_PATH" ]; then
    echo "Error: LLVM_HOST_PATH is not set or is empty"
else
  if [ -e ".config" ]; then
    sed -i -e 's|CONFIG_BPF_TOOLCHAIN_HOST_PATH=.*|CONFIG_BPF_TOOLCHAIN_HOST_PATH="'$LLVM_HOST_PATH'"|' .config
    echo "OK"
  else
    echo "WARNING: .config is missing"
  fi
fi

echo "Note: You can re-run this script by executing \"apply-nix-fixes\"";
