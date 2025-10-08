#!/bin/bash
# filepath: /Users/sydneymarsden/IQGeo/utils-project-template/qa_test_automation/test_modify_display_names.sh

# QA Test Automation Script for Utils-Project-Template Dev Container
# This script modifies the .iqgeorc.jsonc file to append '_test' to specific fields,
# runs project-update, builds the development environment, verifies container names,
# automatically restores the original configuration, and rebuilds containers at completion.

set -e  # Exit on any error

# Configuration - Look for .iqgeorc.jsonc in parent directory
IQGEORC_FILE="../.iqgeorc.jsonc"
TEST_SUFFIX="_test"

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
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --file FILE     Specify .iqgeorc.jsonc file path (default: ../.iqgeorc.jsonc)"
    echo "  -u, --restore       Remove '_test' suffix from all fields (manual restore only)"
    echo "  -s, --skip-update   Skip running 'npx project-update' after modifications"
    echo "  -b, --skip-build    Skip building and starting the development environment"
    echo "  -n, --no-auto-restore  Skip automatic restore at completion"
    echo "  -r, --skip-final-rebuild  Skip final container rebuild after restoration"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Full workflow: Add '_test' suffix, build, verify, auto-restore, rebuild"
    echo "  $0 --restore        # Manual restore: Remove '_test' suffix and run project-update (no rebuild)"
    echo "  $0 --skip-build     # Add '_test' suffix without building environment, then auto-restore and rebuild"
    echo "  $0 --no-auto-restore # Add '_test' suffix and build environment but skip auto-restore and rebuild"
    echo "  $0 --skip-final-rebuild # Full workflow but skip final container rebuild"
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

# Function to build and start development environment
build_dev_environment() {
    local build_purpose="$1"  # "test" or "restore"
    
    if [[ "$build_purpose" == "restore" ]]; then
        print_status "Rebuilding development environment with original configuration..."
    else
        print_status "Building and starting development environment with '_test' configuration..."
    fi
    
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
        if [[ "$build_purpose" == "restore" ]]; then
            print_success "Development environment rebuild with original configuration completed successfully!"
        else
            print_success "Development environment build completed successfully!"
        fi
        return 0
    else
        if [[ "$build_purpose" == "restore" ]]; then
            print_error "Development environment rebuild failed!"
        else
            print_error "Development environment build failed!"
        fi
        return 1
    fi
}

# Function to verify container names contain _test suffix
verify_container_names() {
    print_status "Verifying container names contain '_test' suffix..."
    
    # Get list of running containers
    local containers=$(docker ps --format "table {{.Names}}" | tail -n +2)
    
    if [[ -z "$containers" ]]; then
        print_error "No running containers found!"
        return 1
    fi
    
    echo ""
    print_status "Running containers:"
    
    local test_containers=()
    local non_test_containers=()
    
    while IFS= read -r container; do
        if [[ -n "$container" ]]; then
            echo "  - $container"
            if [[ "$container" =~ ${TEST_SUFFIX} ]]; then
                test_containers+=("$container")
            else
                non_test_containers+=("$container")
            fi
        fi
    done <<< "$containers"
    
    echo ""
    
    # Check if all containers have _test suffix
    if [[ ${#test_containers[@]} -gt 0 && ${#non_test_containers[@]} -eq 0 ]]; then
        print_success "All container names have been successfully updated with '${TEST_SUFFIX}' suffix!"
        print_success "Verified ${#test_containers[@]} containers with '${TEST_SUFFIX}' suffix:"
        for container in "${test_containers[@]}"; do
            echo -e "  ${GREEN}✓${NC} $container"
        done
        return 0
    elif [[ ${#test_containers[@]} -gt 0 ]]; then
        print_warning "Some containers have '${TEST_SUFFIX}' suffix, but others do not:"
        echo ""
        print_status "Containers WITH '${TEST_SUFFIX}' suffix (${#test_containers[@]}):"
        for container in "${test_containers[@]}"; do
            echo -e "  ${GREEN}✓${NC} $container"
        done
        echo ""
        print_status "Containers WITHOUT '${TEST_SUFFIX}' suffix (${#non_test_containers[@]}):"
        for container in "${non_test_containers[@]}"; do
            echo -e "  ${RED}✗${NC} $container"
        done
        return 2
    else
        print_error "No containers found with '${TEST_SUFFIX}' suffix!"
        print_error "This indicates the configuration changes may not have been applied correctly."
        return 1
    fi
}

# Function to verify container names do NOT contain _test suffix (after restoration)
verify_restored_container_names() {
    print_status "Verifying container names do NOT contain '_test' suffix..."
    
    # Wait for containers to fully start
    print_status "Waiting for containers to fully start..."
    sleep 10
    
    # Get list of running containers
    local containers=$(docker ps --format "table {{.Names}}" | tail -n +2)
    
    if [[ -z "$containers" ]]; then
        print_error "No running containers found!"
        return 1
    fi
    
    echo ""
    print_status "Running containers after restoration:"
    
    local test_containers=()
    local clean_containers=()
    
    while IFS= read -r container; do
        if [[ -n "$container" ]]; then
            echo "  - $container"
            if [[ "$container" =~ ${TEST_SUFFIX} ]]; then
                test_containers+=("$container")
            else
                clean_containers+=("$container")
            fi
        fi
    done <<< "$containers"
    
    echo ""
    
    # Check if all containers do NOT have _test suffix
    if [[ ${#clean_containers[@]} -gt 0 && ${#test_containers[@]} -eq 0 ]]; then
        print_success "All container names have been successfully restored to original state!"
        print_success "Verified ${#clean_containers[@]} containers without '${TEST_SUFFIX}' suffix:"
        for container in "${clean_containers[@]}"; do
            echo -e "  ${GREEN}✓${NC} $container"
        done
        return 0
    elif [[ ${#clean_containers[@]} -gt 0 ]]; then
        print_warning "Some containers have been restored, but others still have '${TEST_SUFFIX}' suffix:"
        echo ""
        print_status "Containers WITHOUT '${TEST_SUFFIX}' suffix (${#clean_containers[@]}):"
        for container in "${clean_containers[@]}"; do
            echo -e "  ${GREEN}✓${NC} $container"
        done
        echo ""
        print_status "Containers still WITH '${TEST_SUFFIX}' suffix (${#test_containers[@]}):"
        for container in "${test_containers[@]}"; do
            echo -e "  ${RED}✗${NC} $container"
        done
        return 2
    else
        print_error "All containers still have '${TEST_SUFFIX}' suffix!"
        print_error "This indicates the restoration may not have been applied correctly."
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

# Function to extract current values
extract_current_values() {
    local file="$1"
    
    echo "Current values:"
    
    # Extract name
    local name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$file" | sed 's/.*"\([^"]*\)".*/\1/')
    echo "  name: $name"
    
    # Extract display_name
    local display_name=$(grep -o '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' "$file" | sed 's/.*"\([^"]*\)".*/\1/')
    echo "  display_name: $display_name"
    
    # Extract prefix
    local prefix=$(grep -o '"prefix"[[:space:]]*:[[:space:]]*"[^"]*"' "$file" | sed 's/.*"\([^"]*\)".*/\1/')
    echo "  prefix: $prefix"
    
    # Extract db_name
    local db_name=$(grep -o '"db_name"[[:space:]]*:[[:space:]]*"[^"]*"' "$file" | sed 's/.*"\([^"]*\)".*/\1/')
    echo "  db_name: $db_name"
}

# Function to add _test suffix to fields
add_test_suffix() {
    local file="$1"
    local temp_file=$(mktemp)
    local line_number=0
    local name_modified=false
    
    while IFS= read -r line; do
        ((line_number++))
        
        # Process name field ONLY on line 2 and only if not already modified
        if [[ $line_number -eq 2 ]] && [[ "$line" =~ \"name\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]] && [[ ! "${BASH_REMATCH[1]}" =~ ${TEST_SUFFIX}$ ]] && [[ "$name_modified" == false ]]; then
            line=$(echo "$line" | sed "s/\"name\"\\([[:space:]]*:[[:space:]]*\"[^\"]*\\)\"/\"name\"\\1${TEST_SUFFIX}\"/")
            name_modified=true
        fi
        
        # Process display_name field (any line)
        if [[ "$line" =~ \"display_name\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]] && [[ ! "${BASH_REMATCH[1]}" =~ ${TEST_SUFFIX}$ ]]; then
            line=$(echo "$line" | sed "s/\"display_name\"\\([[:space:]]*:[[:space:]]*\"[^\"]*\\)\"/\"display_name\"\\1${TEST_SUFFIX}\"/")
        fi
        
        # Process prefix field (any line)
        if [[ "$line" =~ \"prefix\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]] && [[ ! "${BASH_REMATCH[1]}" =~ ${TEST_SUFFIX}$ ]]; then
            line=$(echo "$line" | sed "s/\"prefix\"\\([[:space:]]*:[[:space:]]*\"[^\"]*\\)\"/\"prefix\"\\1${TEST_SUFFIX}\"/")
        fi
        
        # Process db_name field (any line)
        if [[ "$line" =~ \"db_name\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]] && [[ ! "${BASH_REMATCH[1]}" =~ ${TEST_SUFFIX}$ ]]; then
            line=$(echo "$line" | sed "s/\"db_name\"\\([[:space:]]*:[[:space:]]*\"[^\"]*\\)\"/\"db_name\"\\1${TEST_SUFFIX}\"/")
        fi
        
        echo "$line"
    done < "$file" > "$temp_file"
    
    # Replace original file with modified version
    if mv "$temp_file" "$file"; then
        print_success "File successfully modified! '_test' suffix added to fields."
        return 0
    else
        print_error "Failed to modify file!"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to remove _test suffix from fields (restore operation)
remove_test_suffix() {
    local file="$1"
    local temp_file=$(mktemp)
    local changes_made=false
    local status_messages=()
    
    print_status "Removing '_test' suffix from fields in $file..."
    
    # Read file line by line and process each field
    while IFS= read -r line; do
        original_line="$line"
        
        # Remove _test from name field
        if [[ "$line" =~ \"name\":[[:space:]]*\"([^\"]+)_test\" ]]; then
            local name_value="${BASH_REMATCH[1]}"
            line="${line/\"name\": \"${name_value}_test\"/\"name\": \"${name_value}\"}"
            if [[ "$line" != "$original_line" ]]; then
                status_messages+=("Removed '_test' suffix from name field")
                changes_made=true
            fi
        fi
        
        # Remove _test from display_name field
        if [[ "$line" =~ \"display_name\":[[:space:]]*\"([^\"]+)_test\" ]]; then
            local display_name_value="${BASH_REMATCH[1]}"
            line="${line/\"display_name\": \"${display_name_value}_test\"/\"display_name\": \"${display_name_value}\"}"
            if [[ "$line" != "$original_line" ]]; then
                status_messages+=("Removed '_test' suffix from display_name field")
                changes_made=true
            fi
        fi
        
        # Remove _test from prefix field
        if [[ "$line" =~ \"prefix\":[[:space:]]*\"([^\"]+)_test\" ]]; then
            local prefix_value="${BASH_REMATCH[1]}"
            line="${line/\"prefix\": \"${prefix_value}_test\"/\"prefix\": \"${prefix_value}\"}"
            if [[ "$line" != "$original_line" ]]; then
                status_messages+=("Removed '_test' suffix from prefix field")
                changes_made=true
            fi
        fi
        
        # Remove _test from db_name field
        if [[ "$line" =~ \"db_name\":[[:space:]]*\"([^\"]+)_test\" ]]; then
            local db_name_value="${BASH_REMATCH[1]}"
            line="${line/\"db_name\": \"${db_name_value}_test\"/\"db_name\": \"${db_name_value}\"}"
            if [[ "$line" != "$original_line" ]]; then
                status_messages+=("Removed '_test' suffix from db_name field")
                changes_made=true
            fi
        fi
        
        echo "$line"
    done < "$file" > "$temp_file"
    
    # Print status messages
    for message in "${status_messages[@]}"; do
        print_status "$message"
    done
    
    # Replace original file with modified version
    if mv "$temp_file" "$file"; then
        if [[ "$changes_made" == true ]]; then
            print_success "File successfully reverted! '_test' suffix removed from ${#status_messages[@]} fields."
        else
            print_warning "No '_test' suffixes found to remove."
        fi
        return 0
    else
        print_error "Failed to revert file!"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to validate required fields exist
validate_fields() {
    local file="$1"
    local missing_fields=()
    
    # Check for required fields
    if ! grep -q '"name"[[:space:]]*:' "$file"; then
        missing_fields+=("name")
    fi
    
    if ! grep -q '"display_name"[[:space:]]*:' "$file"; then
        missing_fields+=("display_name")
    fi
    
    if ! grep -q '"prefix"[[:space:]]*:' "$file"; then
        missing_fields+=("prefix")
    fi
    
    if ! grep -q '"db_name"[[:space:]]*:' "$file"; then
        missing_fields+=("db_name")
    fi
    
    if [[ ${#missing_fields[@]} -gt 0 ]]; then
        print_error "Missing required fields in $file: ${missing_fields[*]}"
        exit 1
    fi
}

# Function to stop containers before restoration
stop_containers() {
    print_status "Stopping development environment containers..."
    
    # Change to parent directory where docker-compose.yml should be located
    cd "$(dirname "$IQGEORC_FILE")"
    
    # Stop containers with _test suffix to avoid conflicts during restore
    if docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo down --remove-orphans; then
        print_success "Containers stopped successfully!"
        return 0
    else
        print_warning "Failed to stop some containers. Continuing with restore..."
        return 0  # Don't fail the whole script if container stopping fails
    fi
}

# Function to perform automatic restoration
auto_restore() {
    local file="$1"
    local skip_final_rebuild="$2"
    local original_dir="$(pwd)"
    
    echo ""
    print_status "==========================================="
    print_status "AUTOMATIC RESTORATION PROCESS"
    print_status "==========================================="
    
    print_status "Waiting before starting restoration (10 seconds)..."
    sleep 10
    
    print_status "Automatically restoring original configuration..."
    
    # Stop containers first to avoid conflicts
    stop_containers
    echo ""
    
    # Additional wait after stopping containers
    print_status "Waiting for containers to fully stop (5 seconds)..."
    sleep 5
    
    # Return to the qa_test_automation directory where the script was started
    # so we can use the original file path
    cd /Users/sydneymarsden/IQGeo/utils-project-template/qa_test_automation
    print_status "Current directory for restoration: $(pwd)"
    print_status "Looking for file: $file"
    
    # Remove _test suffix from all fields
    print_status "Removing '_test' suffix from $file..."
    if remove_test_suffix "$file"; then
        echo ""
        print_status "Verification - Restored values:"
        extract_current_values "$file"
        
        # Run project update to apply restored configuration
        echo ""
        if run_project_update; then
            print_success "✓ Configuration has been restored to original state"
            print_success "✓ Repository has been updated with original configuration"
            
            # Rebuild containers with original configuration unless skipped
            if [[ "$skip_final_rebuild" != true ]]; then
                echo ""
                print_status "==========================================="
                print_status "FINAL CONTAINER REBUILD"
                print_status "==========================================="
                print_status "Rebuilding containers with original configuration to reset container names..."
                
                # Azure authentication for rebuild
                if azure_login; then
                    echo ""
                    # Rebuild and start development environment with original configuration
                    if build_dev_environment "restore"; then
                        echo ""
                        # Verify restored container names
                        verify_exit_code=0
                        verify_restored_container_names || verify_exit_code=$?
                        
                        if [[ $verify_exit_code -eq 0 ]]; then
                            echo ""
                            print_success "🎉 Complete restoration success! All containers are running with original names!"
                            print_success "✓ Automatic restoration completed successfully!"
                        elif [[ $verify_exit_code -eq 2 ]]; then
                            echo ""
                            print_warning "Development environment is running, but some containers still have '_test' suffix."
                            print_warning "✓ Automatic restoration partially completed."
                        else
                            echo ""
                            print_error "Development environment rebuild completed, but container verification failed."
                            print_warning "✓ File restoration completed, but container restoration had issues."
                        fi
                    else
                        print_error "Development environment rebuild failed during restoration."
                        print_warning "✓ File restoration completed, but container rebuild failed."
                    fi
                else
                    print_error "Azure authentication failed during restoration rebuild."
                    print_warning "✓ File restoration completed, but cannot rebuild containers."
                fi
            else
                echo ""
                print_warning "Skipped final container rebuild. Containers may still have '_test' suffix."
                print_success "✓ File restoration completed successfully!"
            fi
        else
            print_warning "File was restored but project-update failed during auto-restore."
            print_warning "You may need to run 'npx project-update' manually."
        fi
    else
        print_error "Automatic restoration failed!"
        print_error "You may need to manually restore the original configuration."
    fi
}

# Main function
main() {
    local file="$IQGEORC_FILE"
    local restore_flag=false
    local skip_update_flag=false
    local skip_build_flag=false
    local no_auto_restore_flag=false
    local skip_final_rebuild_flag=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                file="$2"
                shift 2
                ;;
            -u|--restore)
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
            -n|--no-auto-restore)
                no_auto_restore_flag=true
                shift
                ;;
            -r|--skip-final-rebuild)
                skip_final_rebuild_flag=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_status "Display Names Modification Test Script for Utils-Project-Template"
    echo ""
    
    # Check if file exists
    check_file_exists "$file"
    
    # Validate file structure
    validate_fields "$file"
    
    # Check dependencies based on what we're going to do
    local check_build_deps=false
    if [[ "$restore_flag" == false && "$skip_build_flag" == false ]] || [[ "$no_auto_restore_flag" == false && "$skip_final_rebuild_flag" == false ]]; then
        check_build_deps=true
    fi
    
    if [[ "$skip_update_flag" == false || "$check_build_deps" == true ]]; then
        check_dependencies "$check_build_deps"
    fi
    
    # Show current values
    extract_current_values "$file"
    echo ""
    
    # Perform action based on flag
    if [[ "$restore_flag" == true ]]; then
        # Manual restore mode - no auto-restore afterwards
        print_status "Manual restore: Removing '_test' suffix from $file..."
        if remove_test_suffix "$file"; then
            echo ""
            print_status "Verification - Updated values:"
            extract_current_values "$file"

            # Run project update unless skipped (NO BUILD for restore)
            if [[ "$skip_update_flag" == false ]]; then
                echo ""
                if ! run_project_update; then
                    print_warning "File was modified but project-update failed. You may need to run 'npx project-update' manually."
                    exit 1
                fi
            else
                echo ""
                print_warning "Skipped running 'npx project-update'. Remember to run it manually to apply changes."
            fi
        else
            exit 1
        fi
    else
        # Normal execution mode - with potential auto-restore
        print_status "Adding '_test' suffix to $file..."
        if add_test_suffix "$file"; then
            echo ""
            print_status "Verification - Updated values:"
            extract_current_values "$file"
            
            # Run project update unless skipped
            if [[ "$skip_update_flag" == false ]]; then
                echo ""
                if ! run_project_update; then
                    print_warning "File was modified but project-update failed. You may need to run 'npx project-update' manually."
                    
                    # Still attempt auto-restore even if project-update failed
                    if [[ "$no_auto_restore_flag" == false ]]; then
                        auto_restore "$file" "$skip_final_rebuild_flag"
                    fi
                    exit 1
                fi
                
                # Build and verify environment (only when adding _test and not skipping build)
                if [[ "$skip_build_flag" == false ]]; then
                    echo ""
                    print_status "Starting development environment build process..."
                    
                    # Azure authentication
                    if azure_login; then
                        echo ""
                        # Build and start development environment
                        if build_dev_environment "test"; then
                            echo ""
                            # Wait a moment for containers to fully start
                            print_status "Waiting for containers to fully start..."
                            sleep 10
                            
                            # Verify container names
                            verify_exit_code=0
                            verify_container_names || verify_exit_code=$?
                            
                            if [[ $verify_exit_code -eq 0 ]]; then
                                echo ""
                                print_success "🎉 Complete success! Development environment is running with '_test' suffix in all container names!"
                            elif [[ $verify_exit_code -eq 2 ]]; then
                                echo ""
                                print_warning "Development environment is running, but not all containers have the '_test' suffix."
                            else
                                echo ""
                                print_error "Development environment build completed, but container verification failed."
                                
                                # Auto-restore even if verification failed
                                if [[ "$no_auto_restore_flag" == false ]]; then
                                    auto_restore "$file" "$skip_final_rebuild_flag"
                                fi
                                exit 1
                            fi
                        else
                            print_error "Development environment build failed. Please check the logs above."
                            
                            # Auto-restore even if build failed
                            if [[ "$no_auto_restore_flag" == false ]]; then
                                auto_restore "$file" "$skip_final_rebuild_flag"
                            fi
                            exit 1
                        fi
                    else
                        print_error "Azure authentication failed. Cannot proceed with build."
                        
                        # Auto-restore even if Azure auth failed
                        if [[ "$no_auto_restore_flag" == false ]]; then
                            auto_restore "$file" "$skip_final_rebuild_flag"
                        fi
                        exit 1
                    fi
                else
                    echo ""
                    print_warning "Skipped building development environment. Use without --skip-build to build environment."
                fi
            else
                echo ""
                print_warning "Skipped running 'npx project-update'. Remember to run it manually to apply changes."
                if [[ "$skip_build_flag" == false ]]; then
                    print_warning "Also skipping build since project-update was skipped."
                fi
            fi
            
            # Auto-restore at the end (unless it's manual restore mode or explicitly disabled)
            if [[ "$no_auto_restore_flag" == false ]]; then
                auto_restore "$file" "$skip_final_rebuild_flag"
            fi
        else
            exit 1
        fi
    fi
    
    echo ""
    if [[ "$restore_flag" == true ]]; then
        print_success "Manual restore workflow completed successfully!"
    elif [[ "$no_auto_restore_flag" == true ]]; then
        print_success "Display names modification workflow completed successfully!"
        print_warning "Auto-restore was skipped. Remember to run '$0 --restore' to reset configuration."
    else
        if [[ "$skip_final_rebuild_flag" == true ]]; then
            print_success "Display names modification and auto-restore workflow completed successfully!"
            print_warning "Final container rebuild was skipped. Containers may still have '_test' names."
        else
            print_success "Complete display names modification, auto-restore, and container rebuild workflow completed successfully!"
        fi
    fi
}

# Run main function with all arguments
main "$@"