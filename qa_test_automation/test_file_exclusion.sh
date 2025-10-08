#!/bin/bash
# filepath: /Users/sydneymarsden/IQGeo/utils-project-template/qa_test_automation/test_file_exclusion.sh

# QA Test Automation Script for Platform Version and File Exclusion Testing
# This script updates the platform version and tests file exclusion functionality
# in the .iqgeorc.jsonc file.
# ISSUE: This test only works if the dockerfile has not already been modified and is present in the list of uncommited changes. 

set -e  # Exit on any error

# Configuration
IQGEORC_FILE="../.iqgeorc.jsonc"
BACKUP_FILE="../.iqgeorc.jsonc.backup"
TARGET_VERSION="7.2"
EXCLUSION_FILE=".devcontainer/dockerfile"
EXCLUDED_FILE_CHECK=".devcontainer/dockerfile"

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
    echo "  -v, --version VER   Specify target platform version (default: 7.2)"
    echo "  -r, --restore       Restore original .iqgeorc.jsonc from backup"
    echo "  -s, --skip-update   Skip running 'npx project-update' after modifications"
    echo "  -g, --skip-git      Skip git status verification"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Reset exclusions, update version to 7.2, set exclusion, and test"
    echo "  $0 --restore        # Restore original .iqgeorc.jsonc file"
    echo "  $0 --version 7.3    # Use different platform version"
    echo "  $0 --skip-git       # Skip git status verification"
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
    local check_git="$1"
    
    if ! command -v npx &> /dev/null; then
        missing_deps+=("npx (Node.js)")
    fi
    
    if [[ "$check_git" == true ]] && ! command -v git &> /dev/null; then
        missing_deps+=("git")
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
            
            # Run project update to apply the restored configuration
            print_status "Running 'npx project-update' to apply restored configuration..."
            cd "$(dirname "$file")"
            
            if npx project-update; then
                print_success "Project update completed successfully!"
                print_success "Restored configuration has been applied to the repository."
            else
                print_warning "Project update failed after restore."
                print_warning "You may need to run 'npx project-update' manually."
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

# Function to reset exclude_file_paths to empty array
reset_exclude_file_paths() {
    local file="$1"
    local temp_file=$(mktemp)
    local line_number=0
    local exclusion_updated=false
    local status_messages=()
    
    print_status "Resetting exclude_file_paths to empty array..."
    
    while IFS= read -r line; do
        ((line_number++))
        
        # Look for exclude_file_paths line and reset it to empty array
        if [[ "$line" =~ ^([[:space:]]*\"exclude_file_paths\"[[:space:]]*:[[:space:]]*\[)([^\]]*)\](.*)$ ]]; then
            local prefix="${BASH_REMATCH[1]}"
            local current_content="${BASH_REMATCH[2]}"
            local suffix="]${BASH_REMATCH[3]}"
            
            # Check if already empty
            if [[ "$current_content" =~ ^[[:space:]]*$ ]]; then
                status_messages+=("Line $line_number: exclude_file_paths already empty")
            else
                # Reset to empty array
                line="${prefix}${suffix}"
                exclusion_updated=true
                status_messages+=("Line $line_number: Reset exclude_file_paths from [$current_content] to empty array")
            fi
        fi
        
        echo "$line"
    done < "$file" > "$temp_file"
    
    # Print status messages after the file processing is complete
    for message in "${status_messages[@]}"; do
        print_status "$message"
    done
    
    # Replace original file with modified version
    if mv "$temp_file" "$file"; then
        if [[ "$exclusion_updated" == true ]]; then
            print_success "exclude_file_paths successfully reset to empty array!"
        else
            print_warning "exclude_file_paths was already empty - no reset needed."
        fi
        return 0
    else
        print_error "Failed to modify file!"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to update platform version (only line 11)
update_platform_version() {
    local file="$1"
    local target_version="$2"
    local temp_file=$(mktemp)
    local line_number=0
    local version_updated=false
    local version_line=""
    local in_platform_section=false
    local status_messages=()
    
    print_status "Updating platform version to '$target_version' in $file..."
    
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
        
        # Look for platform version line (only within platform section)
        if [[ "$in_platform_section" == true && "$line" =~ ^([[:space:]]*\"version\"[[:space:]]*:[[:space:]]*\")[^\"]*(\".*)$ ]]; then
            local prefix="${BASH_REMATCH[1]}"
            local suffix="${BASH_REMATCH[2]}"
            local old_version=$(echo "$line" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            
            if [[ "$old_version" != "$target_version" ]]; then
                line="${prefix}${target_version}${suffix}"
                version_updated=true
                version_line="$line_number"
                status_messages+=("Line $line_number: Updated platform version from '$old_version' to '$target_version'")
            else
                status_messages+=("Line $line_number: Platform version already set to '$target_version'")
            fi
        fi
        
        echo "$line"
    done < "$file" > "$temp_file"
    
    # Print status messages after the file processing is complete
    for message in "${status_messages[@]}"; do
        print_status "$message"
    done
    
    # Replace original file with modified version
    if mv "$temp_file" "$file"; then
        if [[ "$version_updated" == true ]]; then
            print_success "Platform version successfully updated to '$target_version' on line $version_line!"
        else
            print_warning "No version update needed - already set to '$target_version'."
        fi
        return 0
    else
        print_error "Failed to modify file!"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to set file exclusion (replaces existing entries)
set_file_exclusion() {
    local file="$1"
    local exclusion_file="$2"
    local temp_file=$(mktemp)
    local line_number=0
    local exclusion_updated=false
    local exclusion_line=""
    local status_messages=()
    
    print_status "Setting exclude_file_paths to only include '$exclusion_file' in $file..."
    
    while IFS= read -r line; do
        ((line_number++))
        
        # Look for exclude_file_paths line
        if [[ "$line" =~ ^([[:space:]]*\"exclude_file_paths\"[[:space:]]*:[[:space:]]*\[)([^\]]*)\](.*)$ ]]; then
            local prefix="${BASH_REMATCH[1]}"
            local current_content="${BASH_REMATCH[2]}"
            local suffix="]${BASH_REMATCH[3]}"
            
            # Check if the exclusion file is already the only entry
            if [[ "$current_content" =~ ^[[:space:]]*\"$exclusion_file\"[[:space:]]*$ ]]; then
                status_messages+=("Line $line_number: '$exclusion_file' is already the only entry in exclude_file_paths")
            else
                # Replace with only the new exclusion file
                line="${prefix}\"${exclusion_file}\"${suffix}"
                exclusion_updated=true
                exclusion_line="$line_number"
                status_messages+=("Line $line_number: Set exclude_file_paths to only include '$exclusion_file'")
            fi
        fi
        
        echo "$line"
    done < "$file" > "$temp_file"
    
    # Print status messages after the file processing is complete
    for message in "${status_messages[@]}"; do
        print_status "$message"
    done
    
    # Replace original file with modified version
    if mv "$temp_file" "$file"; then
        if [[ "$exclusion_updated" == true ]]; then
            print_success "File exclusion successfully set on line $exclusion_line!"
        else
            print_warning "No exclusion update needed - '$exclusion_file' already the only excluded file."
        fi
        return 0
    else
        print_error "Failed to modify file!"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to show current configuration
show_current_config() {
    local file="$1"
    local line_number=0
    
    print_status "Current configuration:"
    echo ""
    
    while IFS= read -r line; do
        ((line_number++))
        
        # Show platform version
        if [[ "$line" =~ \"version\".*: ]]; then
            echo "  Line $line_number: $line"
        fi
        
        # Show exclude_file_paths
        if [[ "$line" =~ \"exclude_file_paths\" ]]; then
            echo "  Line $line_number: $line"
        fi
    done < "$file"
    echo ""
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

# Function to verify file exclusion with git status
verify_file_exclusion() {
    local excluded_file="$1"
    
    print_status "Waiting for changes to be applied (15 seconds)..."
    sleep 15
    
    print_status "Running 'git status' to verify file exclusion..."
    
    # Get git status output
    local git_output
    if git_output=$(git status --porcelain 2>/dev/null); then
        print_status "Git status completed successfully"
        
        # Check if the excluded file appears in the modified files list
        if echo "$git_output" | grep -q "$excluded_file"; then
            print_error "✗ FAILED: '$excluded_file' appears in git status output"
            print_error "This indicates the file exclusion is not working properly"
            echo ""
            print_status "Files that were modified:"
            echo "$git_output"
            return 1
        else
            print_success "✓ SUCCESS: '$excluded_file' does not appear in git status output"
            print_success "File exclusion is working correctly!"
            
            if [[ -n "$git_output" ]]; then
                echo ""
                print_status "Other files that were modified (expected):"
                echo "$git_output"
            else
                echo ""
                print_status "No files were modified by the update"
            fi
            return 0
        fi
    else
        print_error "Failed to run 'git status'"
        print_error "Make sure you are in a git repository"
        return 1
    fi
}

# Function to cleanup and show summary
cleanup_and_summary() {
    local success="$1"
    
    echo ""
    print_status "=========================================="
    print_status "FILE EXCLUSION TEST SUMMARY"
    print_status "=========================================="
    
    if [[ "$success" == true ]]; then
        print_success "✓ Test completed successfully!"
        print_success "✓ exclude_file_paths was reset to empty array"
        print_success "✓ Platform version was updated to '$TARGET_VERSION'"
        print_success "✓ File exclusion was set to only include '$EXCLUSION_FILE'"
        print_success "✓ Project update completed without errors"
        print_success "✓ File exclusion verification passed - '$EXCLUDED_FILE_CHECK' was properly excluded"
    else
        print_error "✗ Test failed!"
        print_error "Review the output above for details."
    fi
    
    echo ""
    print_status "To restore the original configuration:"
    print_status "  $0 --restore"
    echo ""
}

# Main function
main() {
    local file="$IQGEORC_FILE"
    local backup="$BACKUP_FILE"
    local target_version="$TARGET_VERSION"
    local restore_flag=false
    local skip_update_flag=false
    local skip_git_flag=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                file="$2"
                backup="${file}.backup"
                shift 2
                ;;
            -v|--version)
                target_version="$2"
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
            -g|--skip-git)
                skip_git_flag=true
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
    
    print_status "File Exclusion Test Script for Utils-Project-Template"
    echo ""
    
    # Handle restore mode
    if [[ "$restore_flag" == true ]]; then
        check_file_exists "$backup"
        restore_from_backup "$file" "$backup"
        exit 0
    fi
    
    # Check if file exists
    check_file_exists "$file"
    
    # Check dependencies
    local check_git_deps=true
    if [[ "$skip_git_flag" == true ]]; then
        check_git_deps=false
    fi
    
    if [[ "$skip_update_flag" == false || "$check_git_deps" == true ]]; then
        check_dependencies "$check_git_deps"
    fi
    
    # Show current configuration
    show_current_config "$file"
    
    # Create backup of original file
    create_backup "$file" "$backup"
    
    # Reset exclude_file_paths to empty array
    if reset_exclude_file_paths "$file"; then
        echo ""
        
        # Update platform version
        if update_platform_version "$file" "$target_version"; then
            echo ""
            
            # Set file exclusion (replaces existing entries)
            if set_file_exclusion "$file" "$EXCLUSION_FILE"; then
                echo ""
                print_status "Verification - Updated configuration:"
                show_current_config "$file"
                
                # Run project update unless skipped
                if [[ "$skip_update_flag" == false ]]; then
                    echo ""
                    if run_project_update; then
                        # Verify file exclusion with git status unless skipped
                        if [[ "$skip_git_flag" == false ]]; then
                            echo ""
                            if verify_file_exclusion "$EXCLUDED_FILE_CHECK"; then
                                cleanup_and_summary true
                            else
                                cleanup_and_summary false
                                exit 1
                            fi
                        else
                            print_warning "Skipped git status verification."
                            cleanup_and_summary true
                        fi
                    else
                        print_error "Project update failed."
                        cleanup_and_summary false
                        exit 1
                    fi
                else
                    echo ""
                    print_warning "Skipped running 'npx project-update'. Remember to run it manually to apply changes."
                    cleanup_and_summary true
                fi
            else
                print_error "Failed to set file exclusion."
                exit 1
            fi
        else
            print_error "Failed to update platform version."
            exit 1
        fi
    else
        print_error "Failed to reset exclude_file_paths."
        exit 1
    fi
}

# Run main function with all arguments
main "$@"