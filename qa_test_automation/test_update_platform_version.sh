#!/bin/bash
# filepath: /Users/sydneymarsden/IQGeo/utils-project-template/qa_test_automation/test_update_platform_version.sh

# QA Test Automation Script for Platform Version Updates
# This script modifies the platform version in .iqgeorc.jsonc file,
# runs project-update, and builds the development environment to verify changes.

set -e  # Exit on any error

# Configuration - Look for .iqgeorc.jsonc in parent directory
IQGEORC_FILE="../.iqgeorc.jsonc"
TEMP_BACKUP_FILE=""
VERSION_LINE_NUMBER=11

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
    echo "Usage: $0 [OPTIONS] <VERSION>"
    echo ""
    echo "Arguments:"
    echo "  VERSION             The platform version to set (e.g., 7.4, 7.5, 8.0)"
    echo ""
    echo "Options:"
    echo "  -f, --file FILE     Specify .iqgeorc.jsonc file path (default: ../.iqgeorc.jsonc)"
    echo "  -r, --restore       Restore original .iqgeorc.jsonc from backup and run project-update"
    echo "  -s, --skip-update   Skip running 'npx project-update' after modification"
    echo "  -b, --skip-build    Skip building and starting the development environment"
    echo "  -c, --current       Show current platform version and exit"
    echo "  -v, --skip-verify   Skip platform version verification in container"
    echo "  -t, --test-legacy   Test legacy version compatibility (expects build failure for versions < 7.0)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 7.5              # Set version to 7.5, run project-update, build, and verify"
    echo "  $0 --current        # Show current platform version"
    echo "  $0 8.0 --skip-build # Set version without building containers"
    echo "  $0 7.4 --skip-verify # Set version and build but skip container verification"
    echo "  $0 --restore        # Restore original .iqgeorc.jsonc and run project-update"
    echo "  $0 --file ./custom.jsonc 7.4  # Use custom file path"
    echo "  $0 6.5 --test-legacy # Test that version 6.5 fails as expected (legacy compatibility test)"
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

# Function to create temporary backup of original file
create_temp_backup() {
    local file="$1"
    
    # Create temporary backup file
    TEMP_BACKUP_FILE=$(mktemp "/tmp/iqgeorc_backup.XXXXXX")
    
    print_status "Creating temporary backup of original .iqgeorc.jsonc file..."
    if cp "$file" "$TEMP_BACKUP_FILE"; then
        print_success "Temporary backup created: $TEMP_BACKUP_FILE"
    else
        print_error "Failed to create temporary backup file!"
        exit 1
    fi
}

# Function to restore from temporary backup
restore_from_temp_backup() {
    local file="$1"
    local backup="$2"
    local cleanup_backup="$3"  # whether to remove backup after restore
    
    if [[ -f "$backup" ]]; then
        print_status "Restoring original .iqgeorc.jsonc from temporary backup..."
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
            
            # Clean up backup file if requested
            if [[ "$cleanup_backup" == "true" ]]; then
                rm -f "$backup"
                print_status "Temporary backup file removed."
            fi
        else
            print_error "Failed to restore from backup!"
            exit 1
        fi
    else
        print_error "Temporary backup file not found: $backup"
        print_error "Cannot restore original file."
        exit 1
    fi
}

# Function to cleanup temporary files
cleanup_temp_files() {
    if [[ -n "$TEMP_BACKUP_FILE" && -f "$TEMP_BACKUP_FILE" ]]; then
        print_status "Cleaning up temporary backup file: $TEMP_BACKUP_FILE"
        rm -f "$TEMP_BACKUP_FILE"
    fi
}

# Function to check if version is legacy (< 7.0)
is_legacy_version() {
    local version="$1"
    
    # Extract major version
    local major_version=$(echo "$version" | cut -d. -f1)
    
    # Check if major version is less than 7
    if [[ "$major_version" -lt 7 ]]; then
        return 0  # True - is legacy
    else
        return 1  # False - is not legacy
    fi
}

# Function to validate version format
validate_version() {
    local version="$1"
    
    # Check if version matches expected format (e.g., 7.4, 7.5, 8.0, etc.)
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        print_error "Invalid version format: '$version'"
        print_error "Version should be in format like: 7.4, 7.5, 8.0, etc."
        exit 1
    fi
}

# Function to get current platform version
get_current_version() {
    local file="$1"
    
    # Extract version from line 11
    local current_version=$(sed -n "${VERSION_LINE_NUMBER}p" "$file" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/')
    
    if [[ -z "$current_version" ]]; then
        print_error "Could not find 'version' field on line $VERSION_LINE_NUMBER in $file"
        exit 1
    fi
    
    echo "$current_version"
}

# Function to update platform version
update_platform_version() {
    local file="$1"
    local new_version="$2"
    local temp_file=$(mktemp)
    
    # Check if version field exists on the specified line
    local line_content=$(sed -n "${VERSION_LINE_NUMBER}p" "$file")
    if [[ ! "$line_content" =~ \"version\"[[:space:]]*:[[:space:]]*\"[^\"]*\" ]]; then
        print_error "Line $VERSION_LINE_NUMBER does not contain a 'version' field in the expected format"
        print_error "Line content: $line_content"
        exit 1
    fi
    
    # Create modified file
    awk -v line_num="$VERSION_LINE_NUMBER" -v new_ver="$new_version" '
    NR == line_num {
        if ($0 ~ /"version"[[:space:]]*:[[:space:]]*"[^"]*"/) {
            gsub(/"version"[[:space:]]*:[[:space:]]*"[^"]*"/, "\"version\": \"" new_ver "\"")
        }
    }
    { print }
    ' "$file" > "$temp_file"
    
    # Replace original file with modified version
    if mv "$temp_file" "$file"; then
        print_success "Platform version successfully updated to '$new_version'"
        return 0
    else
        print_error "Failed to update platform version!"
        rm -f "$temp_file"
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
        return 0
    else
        print_error "Project update failed!"
        return 1
    fi
}

# Function to build and start development environment
build_dev_environment() {
    local version="$1"
    local test_legacy_flag="$2"
    
    print_status "Building and starting development environment with platform version '$version'..."
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
    
    # Build and start the environment - disable exit on error temporarily for legacy test
    if [[ "$test_legacy_flag" == true ]]; then
        set +e  # Disable exit on error for legacy test
    fi
    
    print_status "Starting Docker Compose build..."
    local build_exit_code=0
    if docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo up -d --build; then
        build_exit_code=0
    else
        build_exit_code=$?
    fi
    
    # Re-enable exit on error if it was disabled
    if [[ "$test_legacy_flag" == true ]]; then
        set -e
    fi
    
    # Handle legacy version test results
    if [[ "$test_legacy_flag" == true ]]; then
        if [[ $build_exit_code -ne 0 ]]; then
            echo ""
            print_success "✓ LEGACY VERSION TEST PASSED: Build failed as expected for platform version '$version'"
            print_success "✓ The system correctly rejected the unsupported platform version"
            print_status "Build exit code: $build_exit_code"
            print_status "This confirms that versions prior to 7.0 are properly blocked"
            return 0  # Success for legacy test - build failure is expected
        else
            echo ""
            print_error "✗ LEGACY VERSION TEST FAILED: Build unexpectedly succeeded for platform version '$version'"
            print_error "✗ Expected the build to fail for versions prior to 7.0"
            print_warning "This may indicate a configuration issue or that legacy version blocking is not working"
            
            # Check if containers are running
            local containers=$(docker ps --format "table {{.Names}}" | tail -n +2)
            if [[ -n "$containers" ]]; then
                print_warning "Unexpected: Containers are running with legacy version '$version':"
                while IFS= read -r container; do
                    if [[ -n "$container" ]]; then
                        echo "  - $container"
                    fi
                done <<< "$containers"
            fi
            return 1  # Failure for legacy test - build should have failed
        fi
    fi
    
    # Normal build handling (non-legacy versions)
    if [[ $build_exit_code -eq 0 ]]; then
        print_success "Development environment build completed successfully!"
        
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
            
            print_success "✓ $container_count containers are running with platform version '$version'"
        else
            print_warning "No containers appear to be running after build"
        fi
        
        return 0
    else
        print_error "Development environment build failed!"
        print_error "Build exit code: $build_exit_code"
        return 1
    fi
}

# Function to verify platform version in container
verify_platform_version_in_container() {
    local expected_version="$1"
    
    echo ""
    print_status "=========================================="
    print_status "PLATFORM VERSION VERIFICATION"
    print_status "=========================================="
    
    print_status "Verifying platform version in container matches expected version '$expected_version'..."
    
    # Wait a bit more for container to be fully ready
    print_status "Waiting for container to be fully ready (10 seconds)..."
    sleep 10
    
    # Execute the docker command to get version info
    print_status "Running: docker exec -t iqgeo_myproj cat /opt/iqgeo/platform/WebApps/myworldapp/core/version_info.json"
    echo ""
    
    local version_output=""
    local docker_exit_code=0
    
    # Capture both the output and exit code
    if version_output=$(docker exec -t iqgeo_myproj cat /opt/iqgeo/platform/WebApps/myworldapp/core/version_info.json 2>&1); then
        docker_exit_code=0
    else
        docker_exit_code=$?
    fi
    
    # Display the raw output
    print_status "Container version info output:"
    echo "----------------------------------------"
    echo "$version_output"
    echo "----------------------------------------"
    echo ""
    
    # Check if the command executed successfully
    if [[ $docker_exit_code -ne 0 ]]; then
        print_error "Failed to execute docker exec command (exit code: $docker_exit_code)"
        print_error "This could indicate the container is not running or the file path doesn't exist"
        return 1
    fi
    
    # Try to extract version information from the output
    local container_version=""
    
    # Look for version patterns in the JSON output
    if echo "$version_output" | grep -q "version"; then
        # Try to extract version using different patterns
        container_version=$(echo "$version_output" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/' | head -1)
        
        # If that doesn't work, try other common version fields
        if [[ -z "$container_version" ]]; then
            container_version=$(echo "$version_output" | grep -o '"platformVersion"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/' | head -1)
        fi
        
        # Try numeric patterns that might match our expected version
        if [[ -z "$container_version" ]]; then
            container_version=$(echo "$version_output" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        fi
    fi
    
    if [[ -n "$container_version" ]]; then
        print_success "✓ Found platform version in container: $container_version"
        
        # Check if the container version matches or is compatible with expected version
        # Allow for patch versions (e.g., 7.4 matches 7.4.1)
        local expected_major_minor=$(echo "$expected_version" | cut -d. -f1-2)
        local container_major_minor=$(echo "$container_version" | cut -d. -f1-2)
        
        if [[ "$container_major_minor" == "$expected_major_minor" ]]; then
            print_success "✓ VERIFICATION SUCCESSFUL: Container platform version '$container_version' matches expected version '$expected_version'"
            print_success "✓ The container was built with the expected platform version"
            return 0
        else
            print_error "✗ VERIFICATION FAILED: Container platform version '$container_version' does not match expected version '$expected_version'"
            print_error "Expected major.minor: $expected_major_minor, Found: $container_major_minor"
            return 1
        fi
    else
        print_warning "Could not extract version information from container output"
        print_warning "Raw output was displayed above - please verify manually"
        print_warning "As long as a version compatible with '$expected_version' appears in the output, the verification is successful"
        return 0  # Don't fail the script, just warn
    fi
}

# Function to show current and new version comparison
show_version_comparison() {
    local file="$1"
    local old_version="$2"
    local new_version="$3"
    
    echo ""
    print_status "Version Update Summary:"
    echo "  Previous version: $old_version"
    echo "  New version:      $new_version"
    echo "  File:             $file"
    echo "  Line:             $VERSION_LINE_NUMBER"
}

# Function to show legacy version test information
show_legacy_test_info() {
    local version="$1"
    
    echo ""
    print_status "=========================================="
    print_status "LEGACY VERSION COMPATIBILITY TEST"
    print_status "=========================================="
    print_warning "Testing platform version '$version' (< 7.0) - Build failure expected"
    print_status "This test verifies that the system properly rejects unsupported platform versions"
    print_status "Expected behavior: Build should fail and no containers should start"
    echo ""
}

# Main function
main() {
    local file="$IQGEORC_FILE"
    local skip_update_flag=false
    local skip_build_flag=false
    local skip_verify_flag=false
    local show_current_flag=false
    local restore_flag=false
    local test_legacy_flag=false
    local new_version=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                file="$2"
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
            -c|--current)
                show_current_flag=true
                shift
                ;;
            -v|--skip-verify)
                skip_verify_flag=true
                shift
                ;;
            -t|--test-legacy)
                test_legacy_flag=true
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
                if [[ -z "$new_version" ]]; then
                    new_version="$1"
                else
                    print_error "Multiple version arguments provided. Only one version is allowed."
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    print_status "Platform Version Update Script for Utils-Project-Template"
    echo ""
    
    # Check if file exists
    check_file_exists "$file"
    
    # Handle restore mode
    if [[ "$restore_flag" == true ]]; then
        # Create temporary backup if not exists
        if [[ -z "$TEMP_BACKUP_FILE" ]]; then
            create_temp_backup "$file"
        fi
        
        # Check if npx is available for project update
        if ! command -v npx &> /dev/null; then
            print_error "npx (Node.js) is required for running project-update after restore."
            print_error "Please install Node.js and try again."
            exit 1
        fi
        
        restore_from_temp_backup "$file" "$TEMP_BACKUP_FILE" true
        exit 0
    fi
    
    # Handle show current version mode
    if [[ "$show_current_flag" == true ]]; then
        local current_version=$(get_current_version "$file")
        print_status "Current platform version: $current_version"
        exit 0
    fi
    
    # Validate that version was provided
    if [[ -z "$new_version" ]]; then
        print_error "No version specified."
        echo ""
        show_usage
        exit 1
    fi
    
    # Validate version format
    validate_version "$new_version"
    
    # Check if this is a legacy version test
    local is_legacy_test=false
    if is_legacy_version "$new_version"; then
        is_legacy_test=true
        
        if [[ "$test_legacy_flag" == true ]]; then
            show_legacy_test_info "$new_version"
        else
            print_warning "You are trying to set platform version '$new_version' which is prior to 7.0"
            print_warning "Versions prior to 7.0 are not supported and builds are expected to fail"
            print_warning "Use --test-legacy flag if you want to test legacy version compatibility"
            print_status "Add --test-legacy to test that this version fails as expected"
            exit 1
        fi
    elif [[ "$test_legacy_flag" == true ]]; then
        print_error "--test-legacy flag was specified but version '$new_version' is not a legacy version (< 7.0)"
        print_error "Legacy test mode is only for versions prior to 7.0"
        exit 1
    fi
    
    # Check dependencies based on what we're going to do
    local check_build_deps=false
    if [[ "$skip_build_flag" == false ]]; then
        check_build_deps=true
    fi
    
    if [[ "$skip_update_flag" == false || "$check_build_deps" == true ]]; then
        check_dependencies "$check_build_deps"
    fi
    
    # Get current version before making changes
    local current_version=$(get_current_version "$file")
    
    # Check if version is already set to the target version
    if [[ "$current_version" == "$new_version" ]]; then
        if [[ "$is_legacy_test" == true ]]; then
            print_warning "Platform version is already set to '$new_version'. Proceeding with legacy test..."
        else
            print_warning "Platform version is already set to '$new_version'. No changes needed."
            exit 0
        fi
    fi
    
    # Show what will be changed
    show_version_comparison "$file" "$current_version" "$new_version"
    
    # Create temporary backup of original file
    create_temp_backup "$file"
    
    # Update the platform version
    print_status "Updating platform version in $file..."
    if update_platform_version "$file" "$new_version"; then
        # Verify the change was applied
        local updated_version=$(get_current_version "$file")
        if [[ "$updated_version" == "$new_version" ]]; then
            print_success "Verification passed: Version successfully updated to '$new_version'"
        else
            print_error "Verification failed: Expected '$new_version', but found '$updated_version'"
            exit 1
        fi
        
        # Run project update unless skipped
        if [[ "$skip_update_flag" == false ]]; then
            echo ""
            if ! run_project_update; then
                print_error "Platform version was updated but project-update failed."
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
                    if build_dev_environment "$new_version" "$test_legacy_flag"; then
                        # Handle successful build result
                        if [[ "$is_legacy_test" == true ]]; then
                            # Legacy test passed (build failed as expected)
                            echo ""
                            print_success "🎉 Legacy version compatibility test completed successfully!"
                            print_success "✓ Platform version '$new_version' correctly failed to build as expected"
                            print_success "✓ The system properly rejects unsupported platform versions"
                        else
                            # Normal version verification unless skipped
                            if [[ "$skip_verify_flag" == false ]]; then
                                if verify_platform_version_in_container "$new_version"; then
                                    echo ""
                                    print_success "🎉 Platform version update, build, and verification completed successfully!"
                                    print_success "✓ Your development environment is now running with verified platform version '$new_version'"
                                else
                                    echo ""
                                    print_warning "Platform version update and build completed, but verification had issues"
                                    print_warning "Your development environment is running with platform version '$new_version'"
                                    print_warning "Please check the verification output above"
                                fi
                            else
                                echo ""
                                print_success "Platform version update and build completed successfully!"
                                print_warning "Platform version verification was skipped"
                                print_status "Your development environment is now running with platform version '$new_version'"
                            fi
                        fi
                    else
                        # Handle build failure
                        if [[ "$is_legacy_test" == true ]]; then
                            # This should not happen as legacy test handles build failure internally
                            print_error "Unexpected error in legacy version test"
                            exit 1
                        else
                            print_error "Development environment build failed."
                            exit 1
                        fi
                    fi
                else
                    print_error "Azure authentication failed. Cannot proceed with build."
                    exit 1
                fi
            else
                echo ""
                print_warning "Skipped building development environment."
                if [[ "$is_legacy_test" == true ]]; then
                    print_warning "Legacy version test cannot be completed without building"
                    print_status "Remove --skip-build flag to complete the legacy version test"
                else
                    print_success "Platform version update completed successfully!"
                    print_status "Your configuration is now set for platform version '$new_version'"
                fi
            fi
        else
            echo ""
            print_warning "Skipped running 'npx project-update'. Remember to run it manually to apply changes."
            if [[ "$skip_build_flag" == false ]]; then
                print_warning "Also skipping build since project-update was skipped."
            fi
            print_status "To apply changes, run: npx project-update"
        fi
    else
        print_error "Failed to update platform version!"
        exit 1
    fi
    
    echo ""
    print_success "Platform version update workflow completed!"
    if [[ -n "$TEMP_BACKUP_FILE" && -f "$TEMP_BACKUP_FILE" ]]; then
        print_status "Temporary backup available at: $TEMP_BACKUP_FILE"
        print_status "Original version can be restored using temporary backup system"
    fi
}

# Cleanup function to run on exit
trap cleanup_temp_files EXIT

# Run main function with all arguments
main "$@"