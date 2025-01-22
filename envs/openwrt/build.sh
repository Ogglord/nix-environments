#!/bin/bash
# OpenWrt Build Helper Script
# Version: 0.2
# Author: github.com/Ogglord

# Enable strict error handling
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging configuration
LOG_DIR="./build_logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level="$1"
    local message="$2"
    local log_file="${LOG_DIR}/${level}_${TIMESTAMP}.log"
    
    # Print to console with color
    case "$level" in
        "error")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "warning")
            echo -e "${YELLOW}[WARNING]${NC} $message" >&2
            ;;
        "info")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
    
    # Log to file
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $level: $message" >> "$log_file"
}

# Version check for required tools
check_tool_versions() {
    local min_make_ver="4.0"
    local min_git_ver="2.0"
    
    # Check Make version
    make_ver=$(make --version | head -n1 | awk '{print $3}')
    if [ "$(printf '%s\n' "$min_make_ver" "$make_ver" | sort -V | head -n1)" != "$min_make_ver" ]; then
        log "warning" "Make version $make_ver may be lower than recommended $min_make_ver"
    fi
    
    # Check Git version
    git_ver=$(git --version | awk '{print $3}')
    if [ "$(printf '%s\n' "$min_git_ver" "$git_ver" | sort -V | head -n1)" != "$min_git_ver" ]; then
        log "warning" "Git version $git_ver may be lower than recommended $min_git_ver"
    fi
}

# Cleanup function to manage log files
cleanup() {
    log "info" "Cleaning up old log files..."
    
    # Keep only the last 5 log files for each type
    find "$LOG_DIR" -type f -name "*_error_*.log" | sort | head -n -5 | xargs -r rm
    find "$LOG_DIR" -type f -name "*_warning_*.log" | sort | head -n -5 | xargs -r rm
    find "$LOG_DIR" -type f -name "*_info_*.log" | sort | head -n -5 | xargs -r rm
}

# Trap cleanup on script exit
trap cleanup EXIT

echo -e "${GREEN}OpenWrt Build Helper Script version 0.2${NC} - github.com/Ogglord"
echo "-"

# Function to check if current directory is an OpenWrt source folder
check_openwrt_source() {
    local required_dirs=("scripts" "package" "target" "toolchain")
    local required_files=("Makefile" "scripts/feeds")
    local missing_dirs=()
    local missing_files=()
    
    # Check for required directories
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done
    
    # Check for required files
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    # Provide detailed error if any directories or files are missing
    if [ ${#missing_dirs[@]} -gt 0 ] || [ ${#missing_files[@]} -gt 0 ]; then
        log "error" "Invalid OpenWrt source directory"
        
        if [ ${#missing_dirs[@]} -gt 0 ]; then
            log "error" "Missing directories: ${missing_dirs[*]}"
        fi
        
        if [ ${#missing_files[@]} -gt 0 ]; then
            log "error" "Missing files: ${missing_files[*]}"
        fi
        
        log "error" "Make sure you're running this script from the OpenWrt root directory"
        exit 1
    fi
    
    log "info" "OpenWrt source directory validated successfully"
}

# Function to check dependencies
check_dependencies() {
    # Check system commands
    local deps=(make git sed)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            log "error" "Required command '$dep' not found"
            exit 1
        fi
    done
}

# Function to display usage
usage() {
    echo "OpenWrt Build Helper Script"
    echo "Version: 0.2"
    echo ""
    echo "Usage: $0 <mode> [--dry-run]"
    echo ""
    echo "Modes:                                      | Log file:"
    echo "  full   - Update+Install Feeds               feeds.log "
    echo "           Download,                          download.log +"
    echo "           Build                              build.log"
    echo "  normal - Build only                         build.log"
    echo "  debug  - Build (single thread verbose)      build_debug.log"
    echo ""
    echo "Options:"
    echo "  --dry-run   Simulate the build process without making changes"
    exit 1
}

# Check if mode argument is provided
if [ $# -ne 1 ]; then
    usage    
fi

# Pre-check OpenWrt source directory
check_openwrt_source

# Check dependencies
check_dependencies

# Function to handle errors
error_exit() {
    log "error" "Error occurred on line $1. Exiting script."
    log "error" "Check output, build.log or build_debug.log for errors during build or other steps."
    exit 1
}

# Trap errors and call error_exit with the line number
trap 'error_exit $LINENO' ERR

update_install_feeds() {
    log "info" "Step 1. Updating and installing all feeds..."
    ./scripts/feeds update -a 2>&1 | tee "$LOG_DIR/feeds.log"
    ./scripts/feeds install -a 2>&1 | tee -a "$LOG_DIR/feeds.log"
    log "info" "Reinstalling apps that fail on the first attempt..."
    REMOVE_APPS="audit busybox kexec-tools lldpd policycoreutils"
    INSTALL_APPS="busybox kexec-tools lldpd policycoreutils"
    ./scripts/feeds uninstall $REMOVE_APPS 2>&1 | tee -a "$LOG_DIR/feeds.log"
    ./scripts/feeds install $INSTALL_APPS 2>&1 | tee -a "$LOG_DIR/feeds.log"
    ./scripts/feeds install -a 2>&1 | tee -a "$LOG_DIR/feeds.log"
    log "info" "Step 1. COMPLETED"
}

download_apps(){
    # Run make download
    log "info" "Running 'make -j1 V=s download'. Logging to download.log"
    make -j1 V=s download | tee "$LOG_DIR/download.log"
}

build() {
    case $MODE in
        debug)
            # Build in debug mode
            set -x
            log "info" "Starting build process in DEBUG mode..."
            log "info" "Running make with debug output..."
            make -j1 V=s 2>&1 | tee "$LOG_DIR/build_debug.log"
            ;;
        full|normal)
            # Exit immediately on error for non-debug modes        
            log "info" "Starting build process in ${MODE^^} mode..."
            log "info" "Running make defconfig just in case..."
            make defconfig
            log "info" "Time to build! Running 'make -j14 V=s'..."        
            make -j14 V=s 2>&1 | tee "$LOG_DIR/build.log" | grep -i -E "^make.*(error|[12345]...Entering dir)"
            ;;
        *)
            log "error" "Unable to build, unknown mode: $MODE."
            exit 1
            ;;
    esac
}

# Parse command-line arguments
DRY_RUN=false
MODE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        full|normal|debug)
            MODE="$1"
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        *)
            log "error" "Invalid argument: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

# Validate mode is set
if [ -z "$MODE" ]; then
    log "error" "No build mode specified"
    usage
    exit 1
fi

# Check tool versions
check_tool_versions

# Dry run mode
if [ "$DRY_RUN" = true ]; then
    log "info" "Dry run mode enabled. Simulating build process..."
    case $MODE in
        full)
            log "info" "[DRY RUN] Would update and install feeds using ./scripts/feeds"
            log "info" "[DRY RUN] Would download apps using make download"
            log "info" "[DRY RUN] Would build in ${MODE^^} mode"
            ;;
        normal)
            log "info" "[DRY RUN] Would build in ${MODE^^} mode"
            ;;
        debug)
            log "info" "[DRY RUN] Would build in ${MODE^^} mode"
            ;;
    esac
    exit 0
fi

# Actual build process
case $MODE in
    full)
        update_install_feeds
        download_apps
        build        
    ;;
    normal)
        build        
    ;;
    debug)
        build
    ;;    
    *)
    log "error" "Invalid command"
    exit 1
esac    

log "info" "Build process completed in ${MODE^^} mode! Check logs in $LOG_DIR for full output."
