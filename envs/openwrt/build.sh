#!/bin/bash
set -e

# Function to check dependencies
check_dependencies() {
    # Check system commands
    local deps=(make git)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            echo "Error: Required command '$dep' not found"
            exit 1
        fi
    done

    # Check OpenWrt specific dependencies
    if [ ! -x "./scripts/feeds" ]; then
        echo "Error: './scripts/feeds' not found or not executable"
        echo "Make sure you're running this script from the OpenWrt root directory"
        exit 1
    fi
}
# Function to display usage
usage() {
    echo "Usage: $0 <mode>"
    echo "Modes:                                      | Log file:"
    echo "  full   - Update+Install Feeds               feeds.log "
    echo "           Download,                          download.log +"
    echo "           Build                              build.log"
    echo "  simple - Build only                         build.log"
    echo "  debug  - Build only with single thread      build_debug.log"
    echo "  upload - Upload a build to git              git.log"
    exit 1
}

# Check if mode argument is provided
if [ $# -ne 1 ]; then
    usage    
fi

# Function to handle errors
error_exit() {
    echo "Error occurred on line $1. Exiting script."
    echo "Check output, build.log  or build_debug.log for errors during build or other steps."
    exit 1
}

# Trap errors and call error_exit with the line number
trap 'error_exit $LINENO' ERR

upload_build() {
    git config --global url."git@github.com:".insteadOf "https://github.com/"    
    git config --global user.email "oag@proton.me"
    git config --global user.name "Ogglord"

    # Copy configuration files to the git directory
    echo "Copying .config and diffconfig to 'bin/config'..."
    cp .config ./bin/config/
    ./scripts/diffconfig.sh > diffconfig
    cp diffconfig ./bin/config/

    echo "Entering bin folder..."
    pushd bin
    
    echo "Adding all files to git stage"
    git add .
    echo "Committing..."
    git commit -m "Scripted commit post build.sh"
    echo "Pushing to github..."
    git push
    echo "Changes committed and pushed successfully."

    echo "Leaving bin folder..."
    popd
}

update_install_feeds() {
    echo "Step 1. Updating and installing all feeds..."
    ./scripts/feeds update -a 2>&1 | tee feeds.log
    ./scripts/feeds install -a 2>&1 | tee -a feeds.log
    echo "Reinstalling apps that fail on the first attempt..."
    REMOVE_APPS="audit busybox kexec-tools lldpd policycoreutils"
    INSTALL_APPS="busybox kexec-tools lldpd policycoreutils"
    ./scripts/feeds uninstall $REMOVE_APPS 2>&1 | tee -a feeds.log
    ./scripts/feeds install $INSTALL_APPS 2>&1 | tee -a feeds.log
    ./scripts/feeds install -a 2>&1 | tee -a feeds.log
    echo "Step 1. COMPLETED"
}

download_apps(){
    # Run make download
    echo "Running 'make download'..."
    make -j1 V=s download | tee download.log

}


build() {


case $MODE in
    debug)
        # Build in debug mode
        set -x
        echo "Starting build process in DEBUG mode..."
        echo "Running make with debug output..."
        make -j1 V=s 2>&1 | tee build_debug.log
        ;;
    full|simple)
        # Exit immediately on error for non-debug modes        
        echo "Starting build process in ${MODE^^} mode..."
        echo "Running make defconfig just in case..."
        make defconfig
        echo "Time to build! Running 'make -j14 V=s'..."        
        make -j14 V=s 2>&1 | tee build.log | grep -i -E "^make.*(error|[12345]...Entering dir)"
        ;;
    *)
        echo unable to build, unknown mode: $MODE.
        exit 1
        ;;
esac

    read -p "Do you want to commit and push changes to github? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        upload_build               
    fi

}


MODE=$1

case $MODE in
    full)
        update_install_feeds
        download_apps
        build        
    ;;
    simple)
        build        
    ;;
    debug)
        build
    ;;
    upload)
        upload_build
    ;;    
    *)
    echo "invalid command"
    exit 1
esac    


echo "Build process completed in ${MODE^^} mode! Check *.log for full output."