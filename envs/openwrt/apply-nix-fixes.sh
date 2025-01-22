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
    echo "SKIPPED: Directory does not exist yet"
  fi


echo "Configuring LLVM toolchain settings in .config"        
if [ -z "$LLVM_HOST_PATH" ]; then
    echo "Error: LLVM_HOST_PATH is not set or is empty"
else
  if [ -e ".config" ]; then
    # Unset CONFIG_BPF_TOOLCHAIN_BUILD_LLVM
    if grep -q "CONFIG_BPF_TOOLCHAIN_BUILD_LLVM=y" .config; then
      echo "Unsetting CONFIG_BPF_TOOLCHAIN_BUILD_LLVM"
      sed -i -e 's|CONFIG_BPF_TOOLCHAIN_BUILD_LLVM=y|# CONFIG_BPF_TOOLCHAIN_BUILD_LLVM is not set|' .config
    fi

    # Handle CONFIG_BPF_TOOLCHAIN_HOST_PATH
    if grep -q "CONFIG_BPF_TOOLCHAIN_HOST_PATH" .config; then
      # If it exists, replace the existing line
      sed -i -e 's|CONFIG_BPF_TOOLCHAIN_HOST_PATH=.*|CONFIG_BPF_TOOLCHAIN_HOST_PATH="'$LLVM_HOST_PATH'"|' .config
    else
      echo "CONFIG_BPF_TOOLCHAIN_HOST_PATH was unset, adding it"
      # If it doesn't exist, append the line to the end of the file
      echo 'CONFIG_BPF_TOOLCHAIN_HOST_PATH="'$LLVM_HOST_PATH'"' >> .config
      echo 'CONFIG_BPF_TOOLCHAIN_HOST=y' >> .config
      echo 'CONFIG_USE_LLVM_HOST=y' >> .config
    fi
    #echo "OK"
  else
    echo "SKIPPED: .config is missing"
  fi
fi
