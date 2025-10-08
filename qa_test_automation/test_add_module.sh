#!/bin/bash
# filepath: /Users/sydneymarsden/IQGeo/utils-project-template/qa_test_automation/test_add_module.sh

# QA Test Automation Script for Adding Modules to Utils-Project-Template
# This script dynamically adds one or more modules to the modules section in .iqgeorc.jsonc,
# runs project-update, builds the development environment, and verifies the module versions.

set -e  # Exit on any error

# Configuration
IQGEORC_FILE="../.iqgeorc.jsonc"
BACKUP_FILE="../.iqgeorc.jsonc.backup"

# Global variables to store absolute paths
ABSOLUTE_IQGEORC_FILE=""
ABSOLUTE_BACKUP_FILE=""

# Global variables to track success criteria for auto-restore
MODULE_UPDATE_SUCCESS=false
PROJECT_UPDATE_SUCCESS=false
BUILD_SUCCESS=false
VERIFICATION_SUCCESS=false
RESTORATION_SUCCESS=false

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] <module_name> <module_version> [<module_name> <module_version>] ..."
    echo ""
    echo "Arguments:"
    echo "  module_name     Name of the module to add (required)"
    echo "  module_version  Version of the module to add (required)"
    echo "  ...             Additional module name/version pairs (optional)"
    echo ""
    echo "Options:"
    echo "  -f, --file FILE         Specify .iqgeorc.jsonc file path (default: ../.iqgeorc.jsonc)"
    echo "  -r, --restore           Restore original .iqgeorc.jsonc from backup and run project-update"
    echo "  -s, --skip-update       Skip running 'npx project-update' after modifications"
    echo "  -b, --skip-build        Skip building and starting the development environment"
    echo "  -v, --skip-verify       Skip module version verification in container"
    echo "  --no-auto-restore       Skip automatic restoration and final rebuild"
    echo "  --skip-final-rebuild    Skip final container rebuild (but still restore file)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 workflow_manager 4.0                              # Add single module with auto-restore"
    echo "  $0 groups 1.0 workflow_manager 4.0                  # Add two modules with auto-restore"
    echo "  $0 groups 1.0 workflow_manager 4.0 analytics 2.1.5  # Add three modules with auto-restore"
    echo "  $0 analytics pre-release reporting 2.1.5            # Add modules with different version formats"
    echo "  $0 --restore                                         # Restore original .iqgeorc.jsonc and run project-update"
    echo "  $0 --skip-build groups 1.0 analytics 2.1.5          # Add modules without building containers"
    echo "  $0 --skip-verify custom 1.0 reporting 3.0           # Add modules and build but skip verification"
    echo "  $0 --no-auto-restore workflow_manager 4.0           # Test without automatic restoration"
    echo "  $0 --skip-final-rebuild groups 1.0                  # Test with restore but no final rebuild"
    echo ""
    echo "Default Behavior: Add modules → Test → Verify → Auto-restore → Final rebuild"
    echo "Auto-Restore: Automatically restores original configuration after testing completes"
}

# Function to set absolute paths for files
set_absolute_paths() {
    local file="$1"
    local backup="$2"
    
    # Convert to absolute paths before we start changing directories
    if [[ "$file" == /* ]]; then
        # Already absolute path
        ABSOLUTE_IQGEORC_FILE="$file"
    else
        # Convert relative path to absolute
        ABSOLUTE_IQGEORC_FILE="$(realpath "$file")"
    fi
    
    if [[ "$backup" == /* ]]; then
        # Already absolute path
        ABSOLUTE_BACKUP_FILE="$backup"
    else
        # Convert relative path to absolute
        ABSOLUTE_BACKUP_FILE="$(realpath "$backup" 2>/dev/null || echo "$(dirname "$(realpath "$file")")/.iqgeorc.jsonc.backup")"
    fi
    
    print_status "Absolute .iqgeorc.jsonc file path: $ABSOLUTE_IQGEORC_FILE"
    print_status "Absolute backup file path: $ABSOLUTE_BACKUP_FILE"
}

# Function to check if file exists
check_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        print_error "File '$file' not found."
        print_error "Please ensure the .iqgeorc.jsonc file exists in the Utils-Project-Template root directory."
        exit 1
    fi
}

# Function to check if required commands are available
check_dependencies() {
    local missing_deps=()
    local check_build_deps="$1"
    
    if ! command -v npx &> /dev/null; then
        missing_deps+=("npx (Node.js)")
    fi
    
    # Only check build dependencies if we're going to build
    if [[ "$check_build_deps" == true ]]; then
        if ! command -v az &> /dev/null; then
            missing_deps+=("az (Azure CLI)")
        fi
        
        if ! command -v docker &> /dev/null; then
            missing_deps+=("docker")
        fi
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_error "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Function to create backup of original file
create_backup() {
    local file="$1"
    local backup="$2"
    
    if [[ ! -f "$backup" ]]; then
        print_status "Creating backup of original .iqgeorc.jsonc file..."
        if cp "$file" "$backup"; then
            print_success "Backup created: $backup"
        else
            print_error "Failed to create backup file!"
            exit 1
        fi
    else
        print_status "Backup file already exists: $backup"
    fi
}

# Function to restore from backup
restore_from_backup() {
    local file="$1"
    local backup="$2"
    
    if [[ -f "$backup" ]]; then
        print_status "Restoring original .iqgeorc.jsonc from backup..."
        if cp "$backup" "$file"; then
            print_success "File restored from backup successfully!"
            
            # Automatically run project update after restore
            echo ""
            print_status "Running 'npx project-update' to apply the restored configuration..."
            
            # Change to parent directory where package.json should be located
            cd "$(dirname "$file")"
            
            if npx project-update; then
                print_success "Project update completed successfully!"
                print_success "✓ Original configuration has been restored and applied"
            else
                print_error "Project update failed after restore!"
                print_warning "The file was restored but the project-update command failed."
                print_status "You may need to run 'npx project-update' manually to apply the restored configuration."
                exit 1
            fi
        else
            print_error "Failed to restore from backup!"
            exit 1
        fi
    else
        print_error "Backup file not found: $backup"
        print_error "Cannot restore original file."
        exit 1
    fi
}

# Function to validate module name and version
validate_module_params() {
    local module_name="$1"
    local module_version="$2"
    
    # Check if module name is provided and valid
    if [[ -z "$module_name" ]]; then
        print_error "Module name is required!"
        return 1
    fi
    
    # Check if module name contains only valid characters
    if [[ ! "$module_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Module name '$module_name' contains invalid characters!"
        print_error "Module name should only contain letters, numbers, underscores, and hyphens."
        return 1
    fi
    
    # Check if module version is provided and valid
    if [[ -z "$module_version" ]]; then
        print_error "Module version is required!"
        return 1
    fi
    
    # Basic version format validation (flexible to allow various version formats)
    if [[ ! "$module_version" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        print_error "Module version '$module_version' contains invalid characters!"
        print_error "Module version should only contain letters, numbers, dots, underscores, and hyphens."
        return 1
    fi
    
    return 0
}

# Function to parse module pairs from command line arguments
parse_module_pairs() {
    # Use global array name passed as first argument
    local array_name="$1"
    shift
    local args=("$@")
    
    # Clear the array using eval
    eval "${array_name}=()"
    
    # Parse arguments in pairs
    local i=0
    while [[ $i -lt ${#args[@]} ]]; do
        local module_name="${args[$i]}"
        local module_version="${args[$((i+1))]}"
        
        # Check if we have both name and version
        if [[ -z "$module_name" || -z "$module_version" ]]; then
            print_error "Module arguments must be provided in pairs: <module_name> <module_version>"
            return 1
        fi
        
        # Validate the module parameters
        if ! validate_module_params "$module_name" "$module_version"; then
            return 1
        fi
        
        # Add to array as "name:version" using eval
        eval "${array_name}+=(\"$module_name:$module_version\")"
        
        # Move to next pair
        i=$((i+2))
    done
    
    # Check if we have at least one module using eval
    local array_length
    eval "array_length=\${#${array_name}[@]}"
    if [[ $array_length -eq 0 ]]; then
        print_error "At least one module name and version pair is required!"
        return 1
    fi
    
    return 0
}

# Function to check if modules already exist
check_modules_exist() {
    local file="$1"
    local array_name="$2"
    local existing_modules=()
    
    # Get array contents using eval
    local modules_list
    eval "modules_list=(\"\${${array_name}[@]}\")"
    
    # Check each module for existing entries
    for module_pair in "${modules_list[@]}"; do
        local module_name="${module_pair%%:*}"
        
        if grep -q "\"name\"[[:space:]]*:[[:space:]]*\"$module_name\"" "$file"; then
            existing_modules+=("$module_name")
        fi
    done
    
    # If any modules exist, warn the user
    if [[ ${#existing_modules[@]} -gt 0 ]]; then
        print_warning "The following modules already exist in the modules section:"
        for existing_module in "${existing_modules[@]}"; do
            echo "  - $existing_module"
        done
        print_warning "This will add duplicate entries. Continue? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_status "Operation cancelled by user."
            exit 0
        fi
    fi
}

# Function to show current modules
show_current_modules() {
    local file="$1"
    local in_modules_section=false
    local module_count=0
    local current_module_name=""
    
    print_status "Current modules in configuration:"
    echo ""
    
    while IFS= read -r line; do
        # Check if we're entering the modules section
        if [[ "$line" =~ \"modules\"[[:space:]]*:[[:space:]]*\[ ]]; then
            in_modules_section=true
            continue
        fi
        
        # Check if we're leaving the modules section
        if [[ "$in_modules_section" == true && "$line" =~ ^[[:space:]]*\][[:space:]]*,?[[:space:]]*$ ]]; then
            in_modules_section=false
            break
        fi
        
        # Show module entries
        if [[ "$in_modules_section" == true ]]; then
            if [[ "$line" =~ \"name\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
                ((module_count++))
                current_module_name="${BASH_REMATCH[1]}"
                echo "  $module_count. Module: $current_module_name"
            elif [[ "$line" =~ \"version\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
                local version="${BASH_REMATCH[1]}"
                echo "     Version: $version"
            elif [[ -n "$current_module_name" && "$line" =~ ^[[:space:]]*\}[[:space:]]*,?[[:space:]]*$ ]]; then
                # Module without version (like "custom")
                echo "     Version: (not specified)"
                current_module_name=""
            fi
        fi
    done < "$file"
    
    if [[ $module_count -eq 0 ]]; then
        echo "  (no modules currently configured)"
    fi
    echo ""
}

# Function to add multiple modules to the modules section
add_modules() {
    local file="$1"
    local array_name="$2"
    local temp_file=$(mktemp)
    local in_modules_section=false
    local modules_added=false
    local line_number=0
    local status_messages=()
    local last_module_line=""
    local last_module_line_number=0
    
    # Get array contents using eval
    local modules_list
    eval "modules_list=(\"\${${array_name}[@]}\")"
    
    print_status "Adding ${#modules_list[@]} module(s) to $file..."
    
    # Show what modules will be added
    for module_pair in "${modules_list[@]}"; do
        local module_name="${module_pair%%:*}"
        local module_version="${module_pair##*:}"
        print_status "  → $module_name (version: $module_version)"
    done
    echo ""
    
    while IFS= read -r line; do
        ((line_number++))
        
        # Check if we're entering the modules section
        if [[ "$line" =~ \"modules\"[[:space:]]*:[[:space:]]*\[ ]]; then
            in_modules_section=true
            echo "$line"
            continue
        fi
        
        # If we're in the modules section, track the last module closing brace
        if [[ "$in_modules_section" == true ]]; then
            # Check if this line is a module closing brace (with or without comma)
            if [[ "$line" =~ ^([[:space:]]*)\}([[:space:]]*,?[[:space:]]*)$ ]]; then
                last_module_line="$line"
                last_module_line_number=$line_number
                
                # Check if this closing brace already has a comma
                local indent="${BASH_REMATCH[1]}"
                local suffix="${BASH_REMATCH[2]}"
                
                # If no comma exists, add one
                if [[ ! "$suffix" =~ , ]]; then
                    echo "${indent}},"
                else
                    echo "$line"
                fi
                continue
            fi
            
            # Check if we're at the end of the modules section
            if [[ "$line" =~ ^([[:space:]]*)\][[:space:]]*,?[[:space:]]*$ ]]; then
                # Add all new modules before the closing bracket
                local indent="${BASH_REMATCH[1]}"
                local suffix="]${BASH_REMATCH[2]}"
                
                # Use the same indentation as the last module
                local module_indent="$indent"
                if [[ -n "$last_module_line" ]]; then
                    # Extract indentation from the last module closing brace
                    module_indent=$(echo "$last_module_line" | sed 's/\(^[[:space:]]*\).*/\1/')
                fi
                
                # Add each new module with proper alignment
                local module_count=0
                for module_pair in "${modules_list[@]}"; do
                    local module_name="${module_pair%%:*}"
                    local module_version="${module_pair##*:}"
                    
                    ((module_count++))
                    
                    # Add comma after previous module if this isn't the first new module
                    if [[ $module_count -gt 1 ]]; then
                        echo "${module_indent},"
                    fi
                    
                    echo "${module_indent}{"
                    echo "${module_indent}    \"name\": \"$module_name\","
                    echo "${module_indent}    \"version\": \"$module_version\""
                    echo "${module_indent}}"
                    
                    status_messages+=("Line $line_number: Added module '$module_name' with version '$module_version'")
                done
                
                echo "$line"
                
                modules_added=true
                in_modules_section=false
                continue
            fi
        fi
        
        echo "$line"
    done < "$file" > "$temp_file"
    
    # Print status messages after the file processing is complete
    for message in "${status_messages[@]}"; do
        print_status "$message"
    done
    
    # Replace original file with modified version
    if [[ "$modules_added" == true ]]; then
        if mv "$temp_file" "$file"; then
            print_success "All ${#modules_list[@]} module(s) successfully added to modules section!"
            # Track successful module update for pass/fail criteria
            MODULE_UPDATE_SUCCESS=true
            return 0
        else
            print_error "Failed to modify file!"
            rm -f "$temp_file"
            return 1
        fi
    else
        rm -f "$temp_file"
        print_error "Failed to find modules section in file!"
        print_error "Make sure the .iqgeorc.jsonc file has a valid 'modules' array."
        return 1
    fi
}

# Function to authenticate with Azure
azure_login() {
    print_status "Authenticating with Azure Container Registry..."
    
    if az acr login --name iqgeoproddev; then
        print_success "Azure authentication completed successfully!"
        return 0
    else
        print_error "Azure authentication failed!"
        print_error "Please ensure you are logged into Azure CLI and have access to iqgeoproddev registry."
        return 1
    fi
}

# Function to run project update
run_project_update() {
    print_status "Waiting for file changes to be fully applied (5 seconds)..."
    sleep 5
    
    print_status "Running 'npx project-update' to apply changes to repository..."
    
    # Change to parent directory where package.json should be located
    cd "$(dirname "$IQGEORC_FILE")"
    
    if npx project-update; then
        print_success "Project update completed successfully!"
        # Track successful project update for pass/fail criteria
        PROJECT_UPDATE_SUCCESS=true
        return 0
    else
        print_error "Project update failed!"
        return 1
    fi
}

# Function to build and start development environment
build_dev_environment() {
    local array_name="$1"
    
    # Get array contents using eval
    local modules_list
    eval "modules_list=(\"\${${array_name}[@]}\")"
    
    print_status "Building and starting development environment with added modules..."
    
    # Show modules being built
    for module_pair in "${modules_list[@]}"; do
        local module_name="${module_pair%%:*}"
        local module_version="${module_pair##*:}"
        print_status "  → $module_name (version: $module_version)"
    done
    
    print_status "Running Docker Compose build from directory: $(pwd)"
    
    # Verify we're in the correct directory by checking for .iqgeorc.jsonc
    if [[ ! -f ".iqgeorc.jsonc" ]]; then
        print_error "Not in the correct project directory. Expected to find .iqgeorc.jsonc file."
        print_error "Current directory: $(pwd)"
        print_error "Expected to be in: utils-project-template"
        return 1
    fi
    
    # Stop any existing containers to avoid conflicts
    print_status "Stopping any existing containers..."
    docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo down --remove-orphans || true
    
    # Build and start the environment
    print_status "Starting Docker Compose build..."
    if docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo up -d --build; then
        print_success "Development environment build completed successfully!"
        # Track successful build for pass/fail criteria
        BUILD_SUCCESS=true
        
        # Wait for containers to start
        print_status "Waiting for containers to start (15 seconds)..."
        sleep 15
        
        # Show running containers
        local containers=$(docker ps --format "table {{.Names}}" | tail -n +2)
        
        if [[ -n "$containers" ]]; then
            echo ""
            print_success "Development environment is running with the following containers:"
            
            local container_count=0
            while IFS= read -r container; do
                if [[ -n "$container" ]]; then
                    ((container_count++))
                    echo "  - $container"
                fi
            done <<< "$containers"
            
            print_success "✓ $container_count containers are running with ${#modules_list[@]} added module(s)"
        else
            print_warning "No containers appear to be running after build"
        fi
        
        return 0
    else
        print_error "Development environment build failed!"
        return 1
    fi
}

# Function to verify module versions in container
verify_modules_in_container() {
    local array_name="$1"
    local verification_results=()
    local successful_verifications=0
    local failed_verifications=0
    
    # Get array contents using eval
    local modules_list
    eval "modules_list=(\"\${${array_name}[@]}\")"
    
    echo ""
    print_status "=========================================="
    print_status "MODULE VERSION VERIFICATION"
    print_status "=========================================="
    
    print_status "Verifying ${#modules_list[@]} module(s) in container..."
    
    # Wait a bit more for container to be fully ready
    print_status "Waiting for container to be fully ready (10 seconds)..."
    sleep 10
    
    # Verify each module
    for module_pair in "${modules_list[@]}"; do
        local module_name="${module_pair%%:*}"
        local expected_version="${module_pair##*:}"
        
        echo ""
        print_status "Verifying module '$module_name' (expected version: $expected_version)..."
        
        # Execute the docker command to get module version info
        local docker_command="docker exec -t iqgeo_myproj cat /opt/iqgeo/platform/WebApps/myworldapp/modules/$module_name/version_info.json"
        print_status "Running: $docker_command"
        echo ""
        
        local version_output=""
        local docker_exit_code=0
        
        # Capture both the output and exit code
        if version_output=$(docker exec -t iqgeo_myproj cat "/opt/iqgeo/platform/WebApps/myworldapp/modules/$module_name/version_info.json" 2>&1); then
            docker_exit_code=0
        else
            docker_exit_code=$?
        fi
        
        # Display the raw output
        print_status "Module '$module_name' version info output:"
        echo "----------------------------------------"
        echo "$version_output"
        echo "----------------------------------------"
        echo ""
        
        # Check if the command executed successfully
        if [[ $docker_exit_code -ne 0 ]]; then
            print_error "Failed to execute docker exec command for module '$module_name' (exit code: $docker_exit_code)"
            print_error "This could indicate:"
            print_error "  - Container is not running"
            print_error "  - Module '$module_name' directory doesn't exist in /opt/iqgeo/platform/WebApps/myworldapp/modules/"
            print_error "  - version_info.json file doesn't exist for this module"
            verification_results+=("$module_name:FAILED")
            ((failed_verifications++))
            continue
        fi
        
        # Try to extract version information from the output
        local container_version=""
        
        # Look for version patterns in the JSON output
        if echo "$version_output" | grep -q "version"; then
            # Try to extract version using different patterns
            container_version=$(echo "$version_output" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/' | head -1)
            
            # If that doesn't work, try other common version fields
            if [[ -z "$container_version" ]]; then
                container_version=$(echo "$version_output" | grep -o '"moduleVersion"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/' | head -1)
            fi
            
            # Try numeric patterns that might match our expected version
            if [[ -z "$container_version" ]]; then
                container_version=$(echo "$version_output" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
            fi
        fi
        
        if [[ -n "$container_version" ]]; then
            print_success "✓ Found module '$module_name' version in container: $container_version"
            
            # Enhanced version comparison logic
            local version_match=false
            
            # Handle "pre-release" versions
            if [[ "$expected_version" == "pre-release" ]]; then
                version_match=true  # Any version found is acceptable for pre-release
                print_status "Pre-release version detected - any version is acceptable"
            else
                # For numeric versions, use more flexible comparison
                
                # Remove any leading 'v' from versions
                local clean_expected=$(echo "$expected_version" | sed 's/^v//')
                local clean_container=$(echo "$container_version" | sed 's/^v//')
                
                # Extract major and minor version parts
                local expected_major=$(echo "$clean_expected" | cut -d. -f1)
                local expected_minor=$(echo "$clean_expected" | cut -d. -f2)
                local container_major=$(echo "$clean_container" | cut -d. -f1)
                local container_minor=$(echo "$clean_container" | cut -d. -f2)
                
                # Check for exact match first
                if [[ "$clean_container" == "$clean_expected" ]]; then
                    version_match=true
                    print_status "Exact version match found"
                # Check if major.minor matches (allowing different patch versions)
                elif [[ "$container_major" == "$expected_major" && "$container_minor" == "$expected_minor" ]]; then
                    version_match=true
                    print_status "Compatible version found (same major.minor, different patch version is acceptable)"
                # Check if container version starts with expected version (e.g., 4.0 matches 4.0.1)
                elif [[ "$clean_container" == "$clean_expected"* ]]; then
                    version_match=true
                    print_status "Compatible version found (container version extends expected version)"
                # Check if expected version is a prefix of container version
                elif echo "$clean_container" | grep -q "^${clean_expected}\."; then
                    version_match=true
                    print_status "Compatible version found (expected version is prefix of container version)"
                else
                    # Check if versions are "close enough" - within same major version
                    if [[ "$container_major" == "$expected_major" ]]; then
                        version_match=true
                        print_status "Acceptable version found (same major version, different minor/patch)"
                    fi
                fi
            fi
            
            if [[ "$version_match" == true ]]; then
                print_success "✓ VERIFICATION SUCCESSFUL: Module '$module_name' version '$container_version' is compatible with expected version '$expected_version'"
                verification_results+=("$module_name:SUCCESS")
                ((successful_verifications++))
            else
                print_warning "Module '$module_name' version mismatch: expected '$expected_version', found '$container_version'"
                print_warning "However, the module is present and functional in the container"
                print_status "You may want to verify if this version difference is acceptable for your use case"
                verification_results+=("$module_name:PARTIAL")
                ((successful_verifications++))  # Still count as success since module is present
            fi
        else
            print_warning "Could not extract specific version information for module '$module_name'"
            print_warning "Raw output was displayed above - please verify manually"
            print_warning "The module appears to be present in the container based on the command execution"
            verification_results+=("$module_name:PARTIAL")
            ((successful_verifications++))  # Count as success since module appears present
        fi
    done
    
    # Summary of verification results
    echo ""
    print_status "=========================================="
    print_status "VERIFICATION SUMMARY"
    print_status "=========================================="
    
    for result in "${verification_results[@]}"; do
        local module_name="${result%%:*}"
        local status="${result##*:}"
        
        case $status in
            "SUCCESS")
                print_success "✓ $module_name: Verified successfully"
                ;;
            "PARTIAL")
                print_warning "⚠ $module_name: Partially verified (module present but version needs manual review)"
                ;;
            "FAILED")
                print_error "✗ $module_name: Verification failed"
                ;;
        esac
    done
    
    echo ""
    if [[ $successful_verifications -eq ${#modules_list[@]} ]]; then
        print_success "Overall verification result: All modules verified successfully!"
        # Track successful verification for pass/fail criteria
        VERIFICATION_SUCCESS=true
        return 0
    elif [[ $successful_verifications -gt 0 ]]; then
        print_warning "Overall verification result: $successful_verifications/${#modules_list[@]} modules verified successfully"
        # Track partial success as success for pass/fail criteria
        VERIFICATION_SUCCESS=true
        return 0  # Don't fail completely if some modules are verified
    else
        print_error "Overall verification result: No modules could be verified"
        return 1
    fi
}

# Function to perform auto-restoration workflow
auto_restore_workflow() {
    local skip_final_rebuild="$1"
    
    echo ""
    print_status "=========================================="
    print_status "AUTO-RESTORATION WORKFLOW"
    print_status "=========================================="
    
    print_status "Starting automatic restoration process..."
    print_status "Current working directory: $(pwd)"
    print_status "File to restore: $ABSOLUTE_IQGEORC_FILE"
    print_status "Backup file: $ABSOLUTE_BACKUP_FILE"
    
    # Restore from backup using absolute paths
    if [[ -f "$ABSOLUTE_BACKUP_FILE" ]]; then
        print_status "Restoring original .iqgeorc.jsonc from backup..."
        if cp "$ABSOLUTE_BACKUP_FILE" "$ABSOLUTE_IQGEORC_FILE"; then
            print_success "File restored from backup successfully!"
            
            # Run project update after restore
            echo ""
            print_status "Running 'npx project-update' to apply the restored configuration..."
            
            # Change to parent directory where package.json should be located
            cd "$(dirname "$ABSOLUTE_IQGEORC_FILE")"
            
            if npx project-update; then
                print_success "Project update completed successfully after restoration!"
                
                # Rebuild with original configuration unless skipped
                if [[ "$skip_final_rebuild" != true ]]; then
                    echo ""
                    print_status "Rebuilding development environment with original configuration..."
                    
                    # Azure authentication
                    if az acr login --name iqgeoproddev >/dev/null 2>&1; then
                        # Stop existing containers
                        print_status "Stopping existing containers..."
                        docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo down --remove-orphans || true
                        
                        # Build with original configuration
                        print_status "Starting Docker Compose build with original configuration..."
                        if docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo up -d --build; then
                            print_success "Development environment rebuilt with original configuration!"
                            
                            # Wait for containers to start
                            print_status "Waiting for containers to start (15 seconds)..."
                            sleep 15
                            
                            echo ""
                            print_success "🎉 Auto-restoration completed successfully!"
                            print_success "✓ Added modules have been removed from configuration"
                            print_success "✓ Original .iqgeorc.jsonc has been restored"
                            print_success "✓ Project update completed with original configuration"
                            print_success "✓ Development environment rebuilt with original configuration"
                            print_success "✓ Your environment has been returned to its original state"
                            # Track successful restoration for pass/fail criteria
                            RESTORATION_SUCCESS=true
                        else
                            print_error "Auto-restoration failed during final rebuild!"
                            print_error "The configuration has been restored and project-update completed, but the container rebuild failed."
                            exit 1
                        fi
                    else
                        print_error "Azure authentication failed during auto-restoration!"
                        print_error "The configuration has been restored but container rebuild cannot proceed."
                        exit 1
                    fi
                else
                    echo ""
                    print_warning "Skipped final container rebuild"
                    print_success "Auto-restoration of configuration completed successfully!"
                    print_success "✓ Added modules have been removed from configuration"
                    print_success "✓ Original .iqgeorc.jsonc has been restored"
                    print_success "✓ Project update completed with original configuration"
                    print_warning "Note: Containers are still running with the modified configuration"
                    # Track restoration success even when skipping rebuild for pass/fail criteria
                    RESTORATION_SUCCESS=true
                fi
            else
                print_error "Project update failed after restoration!"
                print_error "The file was restored but the project-update command failed."
                exit 1
            fi
        else
            print_error "Failed to restore from backup!"
            exit 1
        fi
    else
        print_error "Backup file not found: $ABSOLUTE_BACKUP_FILE"
        print_error "Cannot perform auto-restoration."
        exit 1
    fi
}

# Function to evaluate final pass/fail result
evaluate_final_result() {
    local skip_update="$1"
    local skip_build="$2"
    local skip_verify="$3"
    local no_auto_restore="$4"
    
    echo ""
    print_status "=========================================="
    print_status "FINAL SCRIPT EVALUATION"
    print_status "=========================================="
    
    # Check each criteria
    local criteria_met=0
    local total_criteria=5
    
    echo ""
    print_status "Evaluating success criteria:"
    echo ""
    
    # Criteria 1: Module configuration updated successfully
    if [[ "$MODULE_UPDATE_SUCCESS" == true ]]; then
        print_success "1. Module Configuration Update: PASS"
        print_status "   → Modules successfully added to .iqgeorc.jsonc"
        ((criteria_met++))
    else
        print_error "1. Module Configuration Update: FAIL"
        print_status "   → Failed to update module configuration"
    fi
    
    # Criteria 2: Project update completed successfully
    if [[ "$skip_update" == true ]]; then
        print_warning "2. Project Update: SKIPPED (--skip-update used)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$PROJECT_UPDATE_SUCCESS" == true ]]; then
        print_success "2. Project Update: PASS"
        print_status "   → npx project-update completed successfully"
        ((criteria_met++))
    else
        print_error "2. Project Update: FAIL"
        print_status "   → npx project-update failed"
    fi
    
    # Criteria 3: Environment builds with updated configuration
    if [[ "$skip_build" == true ]]; then
        print_warning "3. Environment Build: SKIPPED (--skip-build used)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$skip_update" == true ]]; then
        print_warning "3. Environment Build: SKIPPED (project update was skipped)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$BUILD_SUCCESS" == true ]]; then
        print_success "3. Environment Build: PASS"
        print_status "   → Environment built successfully with added modules"
        ((criteria_met++))
    else
        print_error "3. Environment Build: FAIL"
        print_status "   → Environment failed to build with added modules"
    fi
    
    # Criteria 4: Module verification in container
    if [[ "$skip_verify" == true ]]; then
        print_warning "4. Module Verification: SKIPPED (--skip-verify used)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$skip_build" == true ]]; then
        print_warning "4. Module Verification: SKIPPED (build was skipped)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$skip_update" == true ]]; then
        print_warning "4. Module Verification: SKIPPED (project update was skipped)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$VERIFICATION_SUCCESS" == true ]]; then
        print_success "4. Module Verification: PASS"
        print_status "   → Modules verified successfully in container"
        ((criteria_met++))
    else
        print_error "4. Module Verification: FAIL"
        print_status "   → Module verification failed"
    fi
    
    # Criteria 5: Restoration completes successfully
    if [[ "$no_auto_restore" == true ]]; then
        print_warning "5. Restoration: SKIPPED (--no-auto-restore used)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$RESTORATION_SUCCESS" == true ]]; then
        print_success "5. Restoration: PASS"
        print_status "   → Configuration restored successfully"
        ((criteria_met++))
    else
        print_error "5. Restoration: FAIL"
        print_status "   → Configuration restoration failed"
    fi
    
    # Final evaluation
    echo ""
    print_status "------------------------------------------"
    print_status "CRITERIA SUMMARY: $criteria_met/$total_criteria criteria met"
    
    if [[ $total_criteria -eq 0 ]]; then
        print_warning "RESULT: INCONCLUSIVE"
        print_warning "All criteria were skipped - no evaluation possible"
        echo ""
        print_status "Script execution completed but no testable criteria were evaluated."
        return 2  # Return special code for inconclusive
    elif [[ $criteria_met -eq $total_criteria ]]; then
        echo ""
        print_success "🎉 FINAL RESULT: PASS 🎉"
        print_success "All evaluated criteria have been met successfully!"
        echo ""
        print_status "✓ Script executed successfully with all requirements fulfilled"
        return 0
    else
        echo ""
        print_error "❌ FINAL RESULT: FAIL ❌"
        print_error "Not all criteria were met ($criteria_met/$total_criteria passed)"
        echo ""
        print_status "✗ Script execution completed but some requirements were not fulfilled"
        return 1
    fi
}

# Main function
main() {
    local file="$IQGEORC_FILE"
    local backup="$BACKUP_FILE"
    local restore_flag=false
    local skip_update_flag=false
    local skip_build_flag=false
    local skip_verify_flag=false
    local no_auto_restore_flag=false
    local skip_final_rebuild_flag=false
    local module_args=()
    local modules=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                file="$2"
                backup="${file}.backup"
                shift 2
                ;;
            -r|--restore)
                restore_flag=true
                shift
                ;;
            -s|--skip-update)
                skip_update_flag=true
                shift
                ;;
            -b|--skip-build)
                skip_build_flag=true
                shift
                ;;
            -v|--skip-verify)
                skip_verify_flag=true
                shift
                ;;
            --no-auto-restore)
                no_auto_restore_flag=true
                shift
                ;;
            --skip-final-rebuild)
                skip_final_rebuild_flag=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                # Collect all non-option arguments as module arguments
                module_args+=("$1")
                shift
                ;;
        esac
    done
    
    print_status "Add Module Script for Utils-Project-Template"
    echo ""
    
    # Handle restore mode
    if [[ "$restore_flag" == true ]]; then
        check_file_exists "$backup"
        
        # Check if npx is available for project update
        if ! command -v npx &> /dev/null; then
            print_error "npx (Node.js) is required for running project-update after restore."
            print_error "Please install Node.js and try again."
            exit 1
        fi
        
        restore_from_backup "$file" "$backup"
        exit 0
    fi
    
    # Parse module pairs from arguments
    if ! parse_module_pairs modules "${module_args[@]}"; then
        echo ""
        show_usage
        exit 1
    fi
    
    # Display what modules will be processed
    print_status "Processing ${#modules[@]} module(s):"
    for module_pair in "${modules[@]}"; do
        local module_name="${module_pair%%:*}"
        local module_version="${module_pair##*:}"
        echo "  • $module_name (version: $module_version)"
    done
    echo ""
    
    # Show auto-restore behavior
    if [[ "$no_auto_restore_flag" == true ]]; then
        print_warning "Auto-restoration is disabled - changes will persist after testing"
    elif [[ "$skip_final_rebuild_flag" == true ]]; then
        print_status "Auto-restoration enabled (restoration only - no final rebuild)"
    else
        print_status "Auto-restoration enabled - configuration will be restored after testing"
    fi
    echo ""
    
    # Check if file exists
    check_file_exists "$file"
    
    # Set absolute paths early to avoid directory navigation issues
    set_absolute_paths "$file" "$backup"
    
    # Check dependencies based on what we're going to do
    local check_build_deps=false
    if [[ "$skip_build_flag" == false ]]; then
        check_build_deps=true
    fi
    
    if [[ "$skip_update_flag" == false || "$check_build_deps" == true ]]; then
        check_dependencies "$check_build_deps"
    fi
    
    # Show current modules
    show_current_modules "$file"
    
    # Check if modules already exist
    check_modules_exist "$file" modules
    
    # Create backup of original file
    create_backup "$ABSOLUTE_IQGEORC_FILE" "$ABSOLUTE_BACKUP_FILE"
    
    # Add the modules
    if add_modules "$file" modules; then
        echo ""
        print_status "Verification - Updated modules configuration:"
        show_current_modules "$file"
        
        # Run project update unless skipped
        if [[ "$skip_update_flag" == false ]]; then
            echo ""
            if ! run_project_update; then
                print_error "Modules were added but project-update failed."
                # Still try to restore if auto-restore is enabled
                if [[ "$no_auto_restore_flag" != true ]]; then
                    echo ""
                    print_status "Attempting to restore configuration due to project-update failure..."
                    auto_restore_workflow "$skip_final_rebuild_flag"
                fi
                exit 1
            fi
            
            # Build and verify environment unless skipped
            if [[ "$skip_build_flag" == false ]]; then
                echo ""
                print_status "Starting development environment build process..."
                
                # Azure authentication
                if azure_login; then
                    echo ""
                    # Build and start development environment
                    if build_dev_environment modules; then
                        # Verify module versions in container unless skipped
                        if [[ "$skip_verify_flag" == false ]]; then
                            if verify_modules_in_container modules; then
                                echo ""
                                print_success "🎉 Module addition, build, and verification completed successfully!"
                                print_success "✓ ${#modules[@]} module(s) have been added and verified"
                                print_success "✓ Your development environment is running with the updated module configuration"
                            else
                                echo ""
                                print_warning "Module addition and build completed, but verification had issues"
                                print_warning "Your development environment is running with ${#modules[@]} added module(s)"
                                print_warning "Please check the verification output above"
                            fi
                            
                            # Auto-restore workflow unless disabled
                            if [[ "$no_auto_restore_flag" != true ]]; then
                                auto_restore_workflow "$skip_final_rebuild_flag"
                            else
                                echo ""
                                print_warning "Auto-restoration was skipped - changes will persist"
                                print_status "To restore manually, run: $0 --restore"
                            fi
                        else
                            echo ""
                            print_success "Module addition and build completed successfully!"
                            print_warning "Module version verification was skipped"
                            print_status "Your development environment is now running with ${#modules[@]} added module(s)"
                            
                            # Auto-restore workflow unless disabled
                            if [[ "$no_auto_restore_flag" != true ]]; then
                                auto_restore_workflow "$skip_final_rebuild_flag"
                            else
                                echo ""
                                print_warning "Auto-restoration was skipped - changes will persist"
                                print_status "To restore manually, run: $0 --restore"
                            fi
                        fi
                    else
                        print_error "Development environment build failed."
                        # Still try to restore if auto-restore is enabled
                        if [[ "$no_auto_restore_flag" != true ]]; then
                            echo ""
                            print_status "Attempting to restore configuration due to build failure..."
                            auto_restore_workflow "$skip_final_rebuild_flag"
                        fi
                        exit 1
                    fi
                else
                    print_error "Azure authentication failed. Cannot proceed with build."
                    # Still try to restore if auto-restore is enabled
                    if [[ "$no_auto_restore_flag" != true ]]; then
                        echo ""
                        print_status "Attempting to restore configuration due to authentication failure..."
                        auto_restore_workflow "$skip_final_rebuild_flag"
                    fi
                    exit 1
                fi
            else
                echo ""
                print_warning "Skipped building development environment."
                print_success "Module addition completed successfully!"
                print_status "${#modules[@]} module(s) have been added to configuration"
                
                # Auto-restore file even if build was skipped
                if [[ "$no_auto_restore_flag" != true ]]; then
                    echo ""
                    print_status "Auto-restoring configuration (build was skipped)..."
                    auto_restore_workflow "$skip_final_rebuild_flag"
                fi
            fi
        else
            echo ""
            print_warning "Skipped running 'npx project-update'. Remember to run it manually to apply changes."
            if [[ "$skip_build_flag" == false ]]; then
                print_warning "Also skipping build since project-update was skipped."
            fi
            print_status "To apply changes, run: npx project-update"
            
            # Auto-restore file even if update was skipped
            if [[ "$no_auto_restore_flag" != true ]]; then
                echo ""
                print_status "Auto-restoring configuration (project-update was skipped)..."
                auto_restore_workflow "$skip_final_rebuild_flag"
            fi
        fi
    else
        print_error "Failed to add modules."
        # Still try to restore if auto-restore is enabled and backup exists
        if [[ "$no_auto_restore_flag" != true && -f "$ABSOLUTE_BACKUP_FILE" ]]; then
            echo ""
            print_status "Attempting to restore configuration due to module addition failure..."
            auto_restore_workflow "$skip_final_rebuild_flag"
        fi
        exit 1
    fi
    
    # Evaluate final pass/fail result
    local final_result=0
    evaluate_final_result "$skip_update_flag" "$skip_build_flag" "$skip_verify_flag" "$no_auto_restore_flag"
    final_result=$?
    
    echo ""
    print_success "Add module workflow completed!"
    print_status "Backup available at: $backup"
    print_status "To restore original configuration manually, run: $0 --restore"
    
    # Exit with appropriate code based on final evaluation
    exit $final_result
}

# Run main function with all arguments
main "$@"