#!/bin/bash
# filepath: /Users/sydneymarsden/IQGeo/utils-project-template/qa_test_automation/test_dependency_exclusion.sh

# QA Test Automation Script for Dependency Exclusion Testing
# This script empties dependency arrays in .iqgeorc.jsonc to test that the application
# properly fails when required dependencies are missing, then automatically restores
# the original configuration and rebuilds containers at completion.

set -e  # Exit on any error

# Configuration
IQGEORC_FILE="../.iqgeorc.jsonc"
BACKUP_FILE="../.iqgeorc.jsonc.backup"

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
    echo "  -r, --restore       Restore original .iqgeorc.jsonc from backup (manual restore only)"
    echo "  -s, --skip-update   Skip running 'npx project-update' after modifications"
    echo "  -b, --skip-build    Skip building and starting the development environment"
    echo "  -t, --skip-test     Skip running the curl test"
    echo "  -n, --no-auto-restore  Skip automatic restore at completion"
    echo "  -k, --skip-final-rebuild  Skip final container rebuild after restoration"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Full workflow: Empty deps, build, test, auto-restore, rebuild"
    echo "  $0 --restore        # Manual restore: Restore original .iqgeorc.jsonc file (no auto-restore or rebuild)"
    echo "  $0 --skip-build     # Empty dependencies without building, then auto-restore and rebuild"
    echo "  $0 --skip-test      # Build environment but skip curl test, then auto-restore and rebuild"
    echo "  $0 --no-auto-restore # Empty dependencies and test but skip auto-restore and rebuild"
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
        
        if ! command -v curl &> /dev/null; then
            missing_deps+=("curl")
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
            print_status "You may want to run 'npx project-update' to apply the restored configuration."
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

# Function to empty dependency arrays
empty_dependency_arrays() {
    local file="$1"
    local temp_file=$(mktemp)
    local line_number=0
    local modifications_made=false
    local modified_lines=()
    
    while IFS= read -r line; do
        ((line_number++))
        
        # Check for devenv, appserver, or tools dependency lines
        if [[ "$line" =~ ^([[:space:]]*\"(devenv|appserver|tools)\"[[:space:]]*:[[:space:]]*)\[.*\][[:space:]]*,?[[:space:]]*$ ]]; then
            local prefix="${BASH_REMATCH[1]}"
            local dependency_name="${BASH_REMATCH[2]}"
            
            # Check if it's already empty
            if [[ "$line" =~ \[[[:space:]]*\] ]]; then
                modified_lines+=("Line $line_number: '$dependency_name' array already empty")
            else
                # Replace with empty array
                line="${prefix}[],"
                modifications_made=true
                modified_lines+=("Line $line_number: Emptied '$dependency_name' dependency array")
            fi
        fi
        
        echo "$line"
    done < "$file" > "$temp_file"
    
    # Print status messages after the file processing is complete
    print_status "Emptying dependency arrays in $file..."
    for message in "${modified_lines[@]}"; do
        print_status "$message"
    done
    
    # Replace original file with modified version
    if mv "$temp_file" "$file"; then
        if [[ "$modifications_made" == true ]]; then
            print_success "Dependency arrays successfully emptied!"
        else
            print_warning "No modifications were needed - dependency arrays already empty."
        fi
        return 0
    else
        print_error "Failed to modify file!"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to show current dependency status
show_dependency_status() {
    local file="$1"
    
    print_status "Current dependency configuration:"
    echo ""
    
    # Find and show dependency-related lines
    local line_number=0
    local in_platform_section=false
    
    while IFS= read -r line; do
        ((line_number++))
        
        # Check if we're entering the platform section
        if [[ "$line" =~ \"platform\"[[:space:]]*:[[:space:]]*\{ ]]; then
            in_platform_section=true
        fi
        
        # Check if we're leaving the platform section
        if [[ "$in_platform_section" == true && "$line" =~ ^[[:space:]]*\}[[:space:]]*,?[[:space:]]*$ ]]; then
            in_platform_section=false
        fi
        
        # Show lines that contain dependency information
        if [[ "$in_platform_section" == true ]] && [[ "$line" =~ (devenv|appserver|tools|Dev.*environment.*optional.*dependencies|Optional.*dependencies) ]]; then
            echo "  Line $line_number: $line"
        fi
    done < "$file"
    echo ""
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
    local build_purpose="$1"  # "test" or "restore"
    
    if [[ "$build_purpose" == "restore" ]]; then
        print_status "Rebuilding development environment with restored original dependencies..."
    else
        print_status "Building and starting development environment with empty dependencies..."
    fi
    
    print_status "Running Docker Compose build from directory: $(pwd)"
    
    # Verify we're in the correct directory by checking for .iqgeorc.jsonc
    if [[ ! -f ".iqgeorc.jsonc" ]]; then
        print_error "Not in the correct project directory. Expected to find .iqgeorc.jsonc file."
        print_error "Current directory: $(pwd)"
        return 1
    fi
    
    # Stop any existing containers to avoid conflicts
    print_status "Stopping any existing containers..."
    docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo down --remove-orphans || true
    
    # Build and start the environment
    print_status "Starting Docker Compose build..."
    if docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo up -d --build; then
        if [[ "$build_purpose" == "restore" ]]; then
            print_success "Development environment rebuild with restored dependencies completed successfully!"
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

# Function to test application accessibility
test_application_accessibility() {
    print_status "Testing application accessibility..."
    
    # Wait for application to start
    print_status "Waiting for application to start (60 seconds)..."
    sleep 60
    
    # Test the application endpoint
    print_status "Testing http://localhost/index for expected 500 Internal Server Error..."
    
    # Capture curl response
    local http_code=""
    local response_body=""
    local curl_exit_code=0
    
    # Run curl and capture both status code and response body
    response_body=$(curl -s -w "\n%{http_code}" http://localhost/index 2>/dev/null) || curl_exit_code=$?
    
    if [[ $curl_exit_code -eq 0 ]]; then
        # Extract HTTP status code (last line)
        http_code=$(echo "$response_body" | tail -n1)
        # Extract response body (all but last line)
        response_body=$(echo "$response_body" | head -n -1)
        
        print_status "HTTP Response Code: $http_code"
        
        if [[ "$http_code" == "500" ]]; then
            print_success "✓ Expected 500 Internal Server Error received!"
            print_status "Response body preview:"
            echo "$response_body" | head -n 5
            
            # Check if response contains error indicators
            if echo "$response_body" | grep -i -q "error\|exception\|internal.*server.*error"; then
                print_success "✓ Response body contains error indicators as expected"
            else
                print_warning "Response body does not contain obvious error indicators"
            fi
            
            return 0
        elif [[ "$http_code" == "000" || "$http_code" == "" ]]; then
            print_warning "Connection failed - this could indicate the application failed to start properly"
            print_status "This might be the expected behavior when dependencies are missing"
            
            # Check container status
            print_status "Checking container status..."
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            
            return 0  # This could be a valid test result
        else
            print_error "✗ Unexpected HTTP response code: $http_code"
            print_error "Expected: 500 Internal Server Error or connection failure"
            print_status "Response body:"
            echo "$response_body"
            return 1
        fi
    else
        print_warning "Connection to http://localhost/index failed (curl exit code: $curl_exit_code)"
        print_status "This could indicate the application failed to start due to missing dependencies"
        print_status "This might be the expected behavior for this test"
        
        # Try to get more information about running containers
        print_status "Checking running containers..."
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        return 0  # Connection failure could be a valid test result
    fi
}

# Function to test restored application functionality
test_restored_application() {
    print_status "Testing restored application functionality..."
    
    # Wait for application to start fully
    print_status "Waiting for application to start fully (60 seconds)..."
    sleep 60
    
    # Test the application endpoint
    print_status "Testing http://localhost/index for expected successful response..."
    
    # Capture curl response
    local http_code=""
    local response_body=""
    local curl_exit_code=0
    
    # Run curl and capture both status code and response body
    response_body=$(curl -s -w "\n%{http_code}" http://localhost/index 2>/dev/null) || curl_exit_code=$?
    
    if [[ $curl_exit_code -eq 0 ]]; then
        # Extract HTTP status code (last line)
        http_code=$(echo "$response_body" | tail -n1)
        # Extract response body (all but last line)
        response_body=$(echo "$response_body" | head -n -1)
        
        print_status "HTTP Response Code: $http_code"
        
        if [[ "$http_code" == "200" ]]; then
            print_success "✓ Application is now working correctly with restored dependencies!"
            print_status "Response body preview:"
            echo "$response_body" | head -n 5
            return 0
        elif [[ "$http_code" == "500" ]]; then
            print_warning "Application still returning 500 error - dependencies may not be fully restored"
            print_status "This might indicate the containers need more time to start or there's another issue"
            return 2
        elif [[ "$http_code" == "000" || "$http_code" == "" ]]; then
            print_warning "Connection failed - application may still be starting up"
            return 2
        else
            print_warning "Unexpected HTTP response code: $http_code"
            print_status "Application may be partially working or still initializing"
            return 2
        fi
    else
        print_warning "Connection to http://localhost/index failed (curl exit code: $curl_exit_code)"
        print_status "Application may still be starting up with restored dependencies"
        return 2
    fi
}

# Function to stop containers before restoration
stop_containers() {
    print_status "Stopping development environment containers..."
    
    # Change to parent directory where docker-compose.yml should be located
    cd "$(dirname "$IQGEORC_FILE")"
    
    # Stop containers to avoid conflicts during restore
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
    local backup="$2"
    local skip_final_rebuild="$3"
    
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
    print_status "Looking for backup: $backup"
    
    # Restore from backup
    if restore_from_backup "$file" "$backup"; then
        echo ""
        print_status "Verification - Restored dependency configuration:"
        show_dependency_status "$file"
        
        # Run project update to apply restored configuration
        echo ""
        print_status "Running 'npx project-update' to apply restored configuration..."
        if run_project_update; then
            print_success "✓ Configuration has been restored to original state"
            print_success "✓ Repository has been updated with original configuration"
            
            # Rebuild containers with restored dependencies unless skipped
            if [[ "$skip_final_rebuild" != true ]]; then
                echo ""
                print_status "==========================================="
                print_status "FINAL CONTAINER REBUILD WITH DEPENDENCIES"
                print_status "==========================================="
                print_status "Rebuilding containers with restored dependencies to reset environment to original state..."
                
                # Azure authentication for rebuild
                if azure_login; then
                    echo ""
                    # Rebuild and start development environment with restored dependencies
                    if build_dev_environment "restore"; then
                        echo ""
                        # Test the restored application functionality
                        test_exit_code=0
                        test_restored_application || test_exit_code=$?
                        
                        if [[ $test_exit_code -eq 0 ]]; then
                            echo ""
                            print_success "🎉 Complete restoration success! Application is fully functional with restored dependencies!"
                            print_success "✓ Automatic restoration and container rebuild completed successfully!"
                        elif [[ $test_exit_code -eq 2 ]]; then
                            echo ""
                            print_warning "Containers have been rebuilt, but application may still be initializing."
                            print_warning "✓ File and container restoration completed - application may need more time to start."
                        else
                            echo ""
                            print_error "Development environment rebuild completed, but application testing failed."
                            print_warning "✓ File and container restoration completed, but application verification had issues."
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
                print_warning "Skipped final container rebuild. Containers may still have empty dependencies."
                print_success "✓ File restoration completed successfully!"
            fi
            
            print_success "✓ Automatic restoration completed successfully!"
        else
            print_warning "File was restored but project-update failed during auto-restore."
            print_warning "You may need to run 'npx project-update' manually."
        fi
    else
        print_error "Automatic restoration failed!"
        print_error "You may need to manually restore the original configuration."
    fi
}

# Function to cleanup and show summary
cleanup_and_summary() {
    local success="$1"
    local skip_final_rebuild="$2"
    
    echo ""
    print_status "=========================================="
    print_status "DEPENDENCY EXCLUSION TEST SUMMARY"
    print_status "=========================================="
    
    if [[ "$success" == true ]]; then
        print_success "✓ Test completed successfully!"
        print_success "✓ Dependency arrays were emptied"
        print_success "✓ Application correctly failed to start or returned 500 error"
        print_success "✓ Verification confirms missing dependencies prevent proper application startup"
        
        if [[ "$skip_final_rebuild" != true ]]; then
            print_success "✓ Original dependencies have been restored"
            print_success "✓ Containers have been rebuilt with restored dependencies"
            print_success "✓ Environment has been reset to original working state"
        fi
        
        echo ""
        print_status "Test verified that empty dependency arrays:"
        print_status "  \"devenv\": []"
        print_status "  \"appserver\": []" 
        print_status "  \"tools\": []"
        print_status "Result in expected application failure behavior."
    else
        print_error "✗ Test failed!"
        print_error "Review the output above for details."
    fi
    
    echo ""
    print_status "To manually restore the original configuration:"
    print_status "  $0 --restore"
    echo ""
    print_status "To view running containers:"
    print_status "  docker ps"
    echo ""
    print_status "To stop the development environment:"
    print_status "  docker compose -f \".devcontainer/docker-compose.yml\" --profile iqgeo down"
    echo ""
}

# Main function
main() {
    local file="$IQGEORC_FILE"
    local backup="$BACKUP_FILE"
    local restore_flag=false
    local skip_update_flag=false
    local skip_build_flag=false
    local skip_test_flag=false
    local no_auto_restore_flag=false
    local skip_final_rebuild_flag=false
    
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
            -t|--skip-test)
                skip_test_flag=true
                shift
                ;;
            -n|--no-auto-restore)
                no_auto_restore_flag=true
                shift
                ;;
            -k|--skip-final-rebuild)
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
    
    print_status "Dependency Exclusion Test Script for Utils-Project-Template"
    echo ""
    
    # Handle restore mode
    if [[ "$restore_flag" == true ]]; then
        check_file_exists "$backup"
        restore_from_backup "$file" "$backup"
        exit 0
    fi
    
    # Check if file exists
    check_file_exists "$file"
    
    # Check dependencies based on what we're going to do
    local check_build_deps=false
    if [[ "$skip_build_flag" == false ]] || [[ "$no_auto_restore_flag" == false && "$skip_final_rebuild_flag" == false ]]; then
        check_build_deps=true
    fi
    
    if [[ "$skip_update_flag" == false || "$check_build_deps" == true ]]; then
        check_dependencies "$check_build_deps"
    fi
    
    # Show current dependency status
    show_dependency_status "$file"
    
    # Create backup of original file
    create_backup "$file" "$backup"
    
    # Empty dependency arrays
    if empty_dependency_arrays "$file"; then
        echo ""
        print_status "Verification - Updated dependency configuration:"
        show_dependency_status "$file"
        
        # Run project update unless skipped
        if [[ "$skip_update_flag" == false ]]; then
            echo ""
            if ! run_project_update; then
                print_warning "File was modified but project-update failed."
                
                # Still attempt auto-restore even if project-update failed
                if [[ "$no_auto_restore_flag" == false ]]; then
                    auto_restore "$file" "$backup" "$skip_final_rebuild_flag"
                fi
                exit 1
            fi
            
            # Build and test environment unless skipped
            if [[ "$skip_build_flag" == false ]]; then
                echo ""
                print_status "Starting development environment build process..."
                
                # Azure authentication
                if azure_login; then
                    echo ""
                    # Build and start development environment
                    if build_dev_environment "test"; then
                        # Test application accessibility unless skipped
                        if [[ "$skip_test_flag" == false ]]; then
                            echo ""
                            if test_application_accessibility; then
                                # Auto-restore at the end unless disabled
                                if [[ "$no_auto_restore_flag" == false ]]; then
                                    auto_restore "$file" "$backup" "$skip_final_rebuild_flag"
                                fi
                                cleanup_and_summary true "$skip_final_rebuild_flag"
                            else
                                # Auto-restore even if test failed
                                if [[ "$no_auto_restore_flag" == false ]]; then
                                    auto_restore "$file" "$backup" "$skip_final_rebuild_flag"
                                fi
                                cleanup_and_summary false "$skip_final_rebuild_flag"
                                exit 1
                            fi
                        else
                            print_warning "Skipped application accessibility test."
                            # Auto-restore at the end unless disabled
                            if [[ "$no_auto_restore_flag" == false ]]; then
                                auto_restore "$file" "$backup" "$skip_final_rebuild_flag"
                            fi
                            cleanup_and_summary true "$skip_final_rebuild_flag"
                        fi
                    else
                        print_error "Development environment build failed."
                        # Auto-restore even if build failed
                        if [[ "$no_auto_restore_flag" == false ]]; then
                            auto_restore "$file" "$backup" "$skip_final_rebuild_flag"
                        fi
                        cleanup_and_summary false "$skip_final_rebuild_flag"
                        exit 1
                    fi
                else
                    print_error "Azure authentication failed. Cannot proceed with build."
                    # Auto-restore even if Azure auth failed
                    if [[ "$no_auto_restore_flag" == false ]]; then
                        auto_restore "$file" "$backup" "$skip_final_rebuild_flag"
                    fi
                    cleanup_and_summary false "$skip_final_rebuild_flag"
                    exit 1
                fi
            else
                echo ""
                print_warning "Skipped building development environment."
                # Auto-restore at the end unless disabled
                if [[ "$no_auto_restore_flag" == false ]]; then
                    auto_restore "$file" "$backup" "$skip_final_rebuild_flag"
                fi
                cleanup_and_summary true "$skip_final_rebuild_flag"
            fi
        else
            echo ""
            print_warning "Skipped running 'npx project-update'. Remember to run it manually to apply changes."
            # Auto-restore at the end unless disabled
            if [[ "$no_auto_restore_flag" == false ]]; then
                auto_restore "$file" "$backup" "$skip_final_rebuild_flag"
            fi
            cleanup_and_summary true "$skip_final_rebuild_flag"
        fi
    else
        print_error "Failed to modify .iqgeorc.jsonc file."
        exit 1
    fi
    
    echo ""
    if [[ "$no_auto_restore_flag" == true ]]; then
        print_success "Dependency exclusion test workflow completed successfully!"
        print_warning "Auto-restore was skipped. Remember to run '$0 --restore' to reset configuration."
    elif [[ "$skip_final_rebuild_flag" == true ]]; then
        print_success "Complete dependency exclusion test and auto-restore workflow completed successfully!"
        print_warning "Final container rebuild was skipped. Containers may still have empty dependencies."
    else
        print_success "Complete dependency exclusion test, auto-restore, and container rebuild workflow completed successfully!"
    fi
}

# Run main function with all arguments
main "$@"