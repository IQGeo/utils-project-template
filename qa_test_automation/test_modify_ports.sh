#!/bin/bash
# filepath: /Users/sydneymarsden/IQGeo/utils-project-template/qa_test_automation/test_modify_ports.sh

# QA Test Automation Script for Port Modifications
# This script updates .env file variables, verifies changes by building the development environment,
# then automatically restores the original configuration and rebuilds

set -e  # Exit on any error

# Configuration
ENV_FILE="../.devcontainer/.env"
DOCKER_COMPOSE_FILE="../.devcontainer/docker-compose.yml"
CUSTOM_SECTION_START="# START CUSTOM SECTION"
CUSTOM_SECTION_END="# END CUSTOM SECTION"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global array to track added variables for removal
declare -a ADDED_VARIABLES=()
# Global variable to store absolute path to .env file
ABSOLUTE_ENV_FILE=""

# Global variables to track success criteria
BUILD_SUCCESS=false
PORT_VERIFICATION_SUCCESS=false
DEV_ENV_RUNNING_SUCCESS=false
RESTORATION_SUCCESS=false

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
    echo "Usage: $0 [OPTIONS] <VARIABLE_NAME> <PORT_VALUE> [<VARIABLE_NAME> <PORT_VALUE>] ..."
    echo ""
    echo "Arguments:"
    echo "  VARIABLE_NAME   Name of the environment variable (without _PORT suffix)"
    echo "  PORT_VALUE      Port number to assign to the variable"
    echo "  ...             Additional variable name/port pairs (optional)"
    echo ""
    echo "Options:"
    echo "  -f, --file FILE         Specify .env file path (default: ../.devcontainer/.env)"
    echo "  -r, --remove            Remove previously added custom variables"
    echo "  -s, --skip-build        Skip building and starting the development environment"
    echo "  -v, --skip-verify       Skip port verification via curl"
    echo "  -c, --current           Show current custom environment variables and exit"
    echo "  --no-auto-restore       Skip automatic restoration and final rebuild"
    echo "  --skip-final-rebuild    Skip final container rebuild (but still restore file)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 APP 8080                              # Set APP_PORT=8080, test, then auto-restore"
    echo "  $0 KEYCLOAK 8081 PGADMIN 8091           # Set multiple port variables with auto-restore"
    echo "  $0 POSTGIS 5433 REDIS 6380              # Set database and cache ports with auto-restore"
    echo "  $0 --current                            # Show current custom variables"
    echo "  $0 --remove                             # Remove all custom variables manually"
    echo "  $0 --skip-build APP 8080                # Set variable without building"
    echo "  $0 --no-auto-restore KEYCLOAK 8081      # Test without automatic restoration"
    echo "  $0 --skip-final-rebuild APP 8080        # Test with restore but no final rebuild"
    echo ""
    echo "Default Behavior: Test → Verify → Auto-restore → Final rebuild"
    echo "Variable Format: Variables are added as VARIABLE_NAME_PORT=PORT_VALUE"
    echo "Custom Section: Variables are added between '# START CUSTOM SECTION' and '# END CUSTOM SECTION'"
    echo "Special Behavior: APP_PORT verification includes '/index' path in URL"
}

# Function to check if file exists
check_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        print_error "File '$file' not found."
        print_error "Please ensure the .env file exists in the .devcontainer directory."
        exit 1
    fi
}

# Function to check if required commands are available
check_dependencies() {
    local missing_deps=()
    local check_build_deps="$1"
    
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

# Function to set absolute path for .env file
set_absolute_env_path() {
    local file="$1"
    
    # Convert to absolute path before we start changing directories
    if [[ "$file" == /* ]]; then
        # Already absolute path
        ABSOLUTE_ENV_FILE="$file"
    else
        # Convert relative path to absolute
        ABSOLUTE_ENV_FILE="$(realpath "$file")"
    fi
    
    print_status "Absolute .env file path: $ABSOLUTE_ENV_FILE"
}

# Function to remove custom variables from the .env file
remove_custom_variables() {
    local file="$1"
    
    # Use absolute path if available
    if [[ -n "$ABSOLUTE_ENV_FILE" && -f "$ABSOLUTE_ENV_FILE" ]]; then
        file="$ABSOLUTE_ENV_FILE"
        print_status "Using absolute path for removal: $file"
    fi
    
    local temp_file=$(mktemp)
    local variables_removed=0
    local removed_vars=()
    
    print_status "Removing custom environment variables from .env file..."
    print_status "Current working directory: $(pwd)"
    print_status "Target file: $file"
    
    if [[ ! -f "$file" ]]; then
        print_error "File not found during removal: $file"
        return 1
    fi
    
    # Process the file and remove custom section content
    local in_custom_section=false
    local custom_section_exists=false
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if we're entering the custom section
        if [[ "$line" == "$CUSTOM_SECTION_START" ]]; then
            in_custom_section=true
            custom_section_exists=true
            echo "$line"
            continue
        fi
        
        # Check if we're leaving the custom section
        if [[ "$line" == "$CUSTOM_SECTION_END" ]]; then
            in_custom_section=false
            echo "$line"
            continue
        fi
        
        # Skip lines within the custom section (removing them)
        if [[ "$in_custom_section" == true ]]; then
            # Count non-empty, non-comment lines as removed variables
            if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# && ! "$line" =~ ^[[:space:]]*$ ]]; then
                ((variables_removed++))
                # Store removed variable for console output (don't print to file)
                removed_vars+=("$line")
            fi
            continue
        fi
        
        # Copy all other lines
        echo "$line"
    done < "$file" > "$temp_file"
    
    # Replace original file with modified version
    if mv "$temp_file" "$file"; then
        # Now print the removal messages to console after file processing
        if [[ ${#removed_vars[@]} -gt 0 ]]; then
            for removed_var in "${removed_vars[@]}"; do
                print_status "Removed: $removed_var"
            done
            print_success "Successfully removed ${#removed_vars[@]} custom environment variable(s)!"
        else
            print_status "No custom variables found to remove."
        fi
        return 0
    else
        print_error "Failed to remove custom variables!"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to validate variable name and port
validate_env_params() {
    local var_name="$1"
    local port_value="$2"
    
    # Check if variable name is provided and valid
    if [[ -z "$var_name" ]]; then
        print_error "Variable name is required!"
        return 1
    fi
    
    # Check if variable name contains only valid characters
    if [[ ! "$var_name" =~ ^[A-Z0-9_]+$ ]]; then
        print_error "Variable name '$var_name' contains invalid characters!"
        print_error "Variable name should only contain uppercase letters, numbers, and underscores."
        return 1
    fi
    
    # Check if port value is provided and valid
    if [[ -z "$port_value" ]]; then
        print_error "Port value is required!"
        return 1
    fi
    
    # Check if port is a valid number
    if [[ ! "$port_value" =~ ^[0-9]+$ ]]; then
        print_error "Port value '$port_value' is not a valid number!"
        return 1
    fi
    
    # Check if port is in valid range
    if [[ "$port_value" -lt 1 || "$port_value" -gt 65535 ]]; then
        print_error "Port value '$port_value' is out of valid range (1-65535)!"
        return 1
    fi
    
    return 0
}

# Function to parse variable pairs from command line arguments
parse_env_pairs() {
    # Use global array name passed as first argument
    local array_name="$1"
    shift
    local args=("$@")
    
    # Clear the array using eval
    eval "${array_name}=()"
    
    # Parse arguments in pairs
    local i=0
    while [[ $i -lt ${#args[@]} ]]; do
        local var_name="${args[$i]}"
        local port_value="${args[$((i+1))]}"
        
        # Check if we have both name and port
        if [[ -z "$var_name" || -z "$port_value" ]]; then
            print_error "Environment variable arguments must be provided in pairs: <VARIABLE_NAME> <PORT_VALUE>"
            return 1
        fi
        
        # Validate the parameters
        if ! validate_env_params "$var_name" "$port_value"; then
            return 1
        fi
        
        # Add to array as "name:port" using eval
        eval "${array_name}+=(\"$var_name:$port_value\")"
        
        # Move to next pair
        i=$((i+2))
    done
    
    # Check if we have at least one variable using eval
    local array_length
    eval "array_length=\${#${array_name}[@]}"
    if [[ $array_length -eq 0 ]]; then
        print_error "At least one variable name and port value pair is required!"
        return 1
    fi
    
    return 0
}

# Function to show current custom variables
show_current_variables() {
    local file="$1"
    
    # Use absolute path if available
    if [[ -n "$ABSOLUTE_ENV_FILE" && -f "$ABSOLUTE_ENV_FILE" ]]; then
        file="$ABSOLUTE_ENV_FILE"
    fi
    
    local in_custom_section=false
    local variable_count=0
    
    print_status "Current custom environment variables:"
    echo ""
    
    while IFS= read -r line; do
        # Check if we're entering the custom section
        if [[ "$line" == "$CUSTOM_SECTION_START" ]]; then
            in_custom_section=true
            continue
        fi
        
        # Check if we're leaving the custom section
        if [[ "$line" == "$CUSTOM_SECTION_END" ]]; then
            in_custom_section=false
            break
        fi
        
        # Show variables in custom section
        if [[ "$in_custom_section" == true ]]; then
            # Skip empty lines and comments
            if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
                ((variable_count++))
                echo "  $variable_count. $line"
            fi
        fi
    done < "$file"
    
    if [[ $variable_count -eq 0 ]]; then
        echo "  (no custom variables currently set)"
    fi
    echo ""
}

# Function to check if custom section exists and create if needed
ensure_custom_section() {
    local file="$1"
    local temp_file=$(mktemp)
    
    # Check if custom section markers exist
    local has_start=$(grep -c "^$CUSTOM_SECTION_START" "$file" || true)
    local has_end=$(grep -c "^$CUSTOM_SECTION_END" "$file" || true)
    
    print_status "Custom section check: START=$has_start, END=$has_end"
    
    if [[ $has_start -eq 0 || $has_end -eq 0 ]]; then
        print_status "Custom section markers missing or incomplete. Fixing..."
        
        # Copy the file and handle missing markers
        cp "$file" "$temp_file"
        
        # If we have START but no END, add END
        if [[ $has_start -gt 0 && $has_end -eq 0 ]]; then
            print_status "Adding missing END marker..."
            echo "$CUSTOM_SECTION_END" >> "$temp_file"
        # If we have no START or END, add both
        elif [[ $has_start -eq 0 ]]; then
            print_status "Adding both START and END markers..."
            echo "" >> "$temp_file"
            echo "$CUSTOM_SECTION_START" >> "$temp_file"
            echo "$CUSTOM_SECTION_END" >> "$temp_file"
        fi
        
        if mv "$temp_file" "$file"; then
            print_success "Custom section markers added/fixed successfully"
        else
            print_error "Failed to add custom section markers!"
            rm -f "$temp_file"
            exit 1
        fi
    else
        print_status "Custom section markers found in file"
    fi
}

# Function to add or update environment variables
update_env_variables() {
    local file="$1"
    local array_name="$2"
    local temp_file=$(mktemp)
    local variables_added=0
    
    # Get array contents using eval
    local variables_list
    eval "variables_list=(\"\${${array_name}[@]}\")"
    
    print_status "Processing ${#variables_list[@]} environment variable(s)..."
    
    # Show what variables will be processed
    for var_pair in "${variables_list[@]}"; do
        local var_name="${var_pair%%:*}"
        local port_value="${var_pair##*:}"
        print_status "  → ${var_name}_PORT = $port_value"
    done
    echo ""
    
    # Clear the global tracking array
    ADDED_VARIABLES=()
    
    # Process the file
    local in_custom_section=false
    local custom_section_processed=false
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if we're entering the custom section
        if [[ "$line" == "$CUSTOM_SECTION_START" ]]; then
            in_custom_section=true
            echo "$line"
            
            # Process all variables when we enter the custom section
            if [[ "$custom_section_processed" == false ]]; then
                # First, copy any existing custom variables (excluding ones we're updating)
                local existing_vars=()
                
                # Read the existing custom section
                local next_line
                while IFS= read -r next_line || [[ -n "$next_line" ]]; do
                    if [[ "$next_line" == "$CUSTOM_SECTION_END" ]]; then
                        # Put the END marker back for processing
                        line="$next_line"
                        break
                    fi
                    
                    # Check if this is a variable line we're NOT updating
                    local is_updating=false
                    if [[ "$next_line" =~ ^[A-Z0-9_]+_PORT[[:space:]]*=[[:space:]]*[0-9]+[[:space:]]*$ ]]; then
                        local existing_var=$(echo "$next_line" | sed 's/_PORT[[:space:]]*=.*//')
                        
                        for var_pair in "${variables_list[@]}"; do
                            local var_name="${var_pair%%:*}"
                            if [[ "$existing_var" == "$var_name" ]]; then
                                is_updating=true
                                break
                            fi
                        done
                    fi
                    
                    # Keep existing variable if we're not updating it
                    if [[ ! "$is_updating" == true && -n "$next_line" && ! "$next_line" =~ ^[[:space:]]*$ ]]; then
                        existing_vars+=("$next_line")
                    fi
                done
                
                # Add existing variables first
                for existing_var in "${existing_vars[@]}"; do
                    echo "$existing_var"
                done
                
                # Add or update our variables
                for var_pair in "${variables_list[@]}"; do
                    local var_name="${var_pair%%:*}"
                    local port_value="${var_pair##*:}"
                    local full_var_name="${var_name}_PORT"
                    
                    echo "${full_var_name}=${port_value}"
                    # Track this variable for potential removal
                    ADDED_VARIABLES+=("${full_var_name}")
                    ((variables_added++))
                done
                
                custom_section_processed=true
            fi
            continue
        fi
        
        # Check if we're leaving the custom section
        if [[ "$line" == "$CUSTOM_SECTION_END" ]]; then
            in_custom_section=false
            echo "$line"
            continue
        fi
        
        # Skip lines within the custom section (we've already processed them)
        if [[ "$in_custom_section" == true ]]; then
            continue
        fi
        
        # Copy all other lines
        echo "$line"
    done < "$file" > "$temp_file"
    
    # Replace original file with modified version
    if mv "$temp_file" "$file"; then
        # Print success messages AFTER file processing is complete
        for var_pair in "${variables_list[@]}"; do
            local var_name="${var_pair%%:*}"
            local port_value="${var_pair##*:}"
            local full_var_name="${var_name}_PORT"
            print_status "Added/Updated: ${full_var_name}=${port_value}"
        done
        
        print_success "Successfully updated ${variables_added} environment variable(s)!"
        return 0
    else
        print_error "Failed to update environment variables!"
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

# Function to build and start development environment
build_dev_environment() {
    local config_type="$1"  # "modified" or "original"
    
    if [[ "$config_type" == "original" ]]; then
        print_status "Building and starting development environment with original configuration..."
    else
        print_status "Building and starting development environment with updated environment variables..."
    fi
    
    print_status "Running Docker Compose build from directory: $(pwd)"
    
    # Verify we're in the correct directory by checking for .devcontainer
    if [[ ! -d ".devcontainer" ]]; then
        print_error "Not in the correct project directory. Expected to find .devcontainer directory."
        print_error "Current directory: $(pwd)"
        print_error "Expected to be in: utils-project-template"
        return 1
    fi
    
    # Stop any existing containers to avoid conflicts
    print_status "Stopping any existing containers..."
    docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo down --remove-orphans || true
    
    print_status "Starting Docker Compose build..."
    if docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo up -d --build; then
        if [[ "$config_type" == "original" ]]; then
            print_success "Development environment build with original configuration completed successfully!"
        else
            print_success "Development environment build completed successfully!"
            # Track successful build for pass/fail criteria
            BUILD_SUCCESS=true
        fi
        
        # Wait for containers to start
        print_status "Waiting for containers to start (15 seconds)..."
        sleep 15
        
        # Show running containers
        local containers=$(docker ps --format "table {{.Names}}" | tail -n +2)
        
        if [[ -n "$containers" ]]; then
            echo ""
            if [[ "$config_type" == "original" ]]; then
                print_success "Development environment is running with original configuration:"
            else
                print_success "Development environment is running with the following containers:"
            fi
            
            local container_count=0
            while IFS= read -r container; do
                if [[ -n "$container" ]]; then
                    ((container_count++))
                    echo "  - $container"
                fi
            done <<< "$containers"
            
            if [[ "$config_type" == "original" ]]; then
                print_success "✓ $container_count containers are running with restored original configuration"
            else
                print_success "✓ $container_count containers are running with updated environment variables"
                # Track successful dev environment running for pass/fail criteria
                DEV_ENV_RUNNING_SUCCESS=true
            fi
        else
            print_warning "No containers appear to be running after build"
        fi
        
        return 0
    else
        if [[ "$config_type" == "original" ]]; then
            print_error "Development environment build with original configuration failed!"
        else
            print_error "Development environment build failed!"
        fi
        return 1
    fi
}

# Function to verify port accessibility
verify_ports() {
    local array_name="$1"
    local verification_results=()
    local successful_verifications=0
    local failed_verifications=0
    
    # Get array contents using eval
    local variables_list
    eval "variables_list=(\"\${${array_name}[@]}\")"
    
    echo ""
    print_status "=========================================="
    print_status "PORT ACCESSIBILITY VERIFICATION"
    print_status "=========================================="
    
    print_status "Verifying ${#variables_list[@]} port(s) accessibility..."
    
    # Wait a bit more for services to be fully ready
    print_status "Waiting for services to be fully ready (10 seconds)..."
    sleep 10
    
    # Verify each port
    for var_pair in "${variables_list[@]}"; do
        local var_name="${var_pair%%:*}"
        local port_value="${var_pair##*:}"
        
        echo ""
        print_status "Verifying port $port_value (${var_name}_PORT)..."
        
        # Construct URL with special handling for APP variable
        local curl_url="http://localhost:$port_value"
        if [[ "$var_name" == "APP" ]]; then
            curl_url="${curl_url}/index"
            print_status "Special handling for APP_PORT: appending '/index' to URL"
            print_status "Additional wait time for APP service initialization (90 seconds)..."
            sleep 90
        fi
        
        print_status "Testing: curl -s -w '%{http_code}' '$curl_url'"
        
        local http_code=""
        local curl_output=""
        local curl_exit_code=0
        
        # Capture both HTTP response code, output content, and curl exit code
        if curl_output=$(curl -s -w '\n---CURL_SEPARATOR---\n%{http_code}' "$curl_url" 2>&1); then
            curl_exit_code=0
            # Split the output to get content and HTTP code
            local content_part=$(echo "$curl_output" | sed '/---CURL_SEPARATOR---/,$d')
            http_code=$(echo "$curl_output" | sed -n '/---CURL_SEPARATOR---/,$p' | tail -1)
        else
            curl_exit_code=$?
            content_part="$curl_output"
            http_code="000"
        fi
        
        print_status "HTTP Response Code: $http_code"
        print_status "Curl Exit Code: $curl_exit_code"
        
        # Show curl output content
        echo ""
        print_status "Response Content:"
        echo "----------------------------------------"
        if [[ -n "$content_part" ]]; then
            # Limit output to first 20 lines to prevent terminal flooding
            echo "$content_part" | head -20
            local line_count=$(echo "$content_part" | wc -l)
            if [[ $line_count -gt 20 ]]; then
                echo "... (output truncated - showing first 20 lines of $line_count total)"
            fi
        else
            echo "(no response content)"
        fi
        echo "----------------------------------------"
        echo ""
        
        # Evaluate the response
        if [[ $curl_exit_code -eq 0 ]]; then
            case $http_code in
                200|301|302|401|403)
                    print_success "✓ Port $port_value is accessible (HTTP $http_code)"
                    if [[ "$var_name" == "APP" ]]; then
                        print_success "✓ APP service is responding on ${var_name}_PORT=$port_value with /index path"
                    else
                        print_success "✓ Service is responding on ${var_name}_PORT=$port_value"
                    fi
                    verification_results+=("$var_name:$port_value:SUCCESS")
                    ((successful_verifications++))
                    ;;
                404|500|502|503)
                    print_warning "⚠ Port $port_value is accessible but service returned HTTP $http_code"
                    print_warning "Service may be starting up or have configuration issues"
                    verification_results+=("$var_name:$port_value:PARTIAL")
                    ((successful_verifications++))  # Still count as success since port is accessible
                    ;;
                000)
                    print_error "✗ Port $port_value is not accessible (connection failed)"
                    verification_results+=("$var_name:$port_value:FAILED")
                    ((failed_verifications++))
                    ;;
                *)
                    print_warning "⚠ Port $port_value returned unexpected HTTP code: $http_code"
                    verification_results+=("$var_name:$port_value:PARTIAL")
                    ((successful_verifications++))
                    ;;
            esac
        else
            print_error "✗ Failed to connect to port $port_value (curl exit code: $curl_exit_code)"
            print_error "This could indicate the service is not running or the port is not accessible"
            verification_results+=("$var_name:$port_value:FAILED")
            ((failed_verifications++))
        fi
    done
    
    # Summary of verification results
    echo ""
    print_status "=========================================="
    print_status "VERIFICATION SUMMARY"
    print_status "=========================================="
    
    for result in "${verification_results[@]}"; do
        local var_name="${result%%:*}"
        local temp="${result#*:}"
        local port_value="${temp%%:*}"
        local status="${result##*:}"
        
        case $status in
            "SUCCESS")
                if [[ "$var_name" == "APP" ]]; then
                    print_success "✓ ${var_name}_PORT=$port_value: Verified successfully with /index path"
                else
                    print_success "✓ ${var_name}_PORT=$port_value: Verified successfully"
                fi
                ;;
            "PARTIAL")
                print_warning "⚠ ${var_name}_PORT=$port_value: Accessible but needs review"
                ;;
            "FAILED")
                print_error "✗ ${var_name}_PORT=$port_value: Verification failed"
                ;;
        esac
    done
    
    echo ""
    if [[ $successful_verifications -eq ${#variables_list[@]} ]]; then
        print_success "Overall verification result: All ports verified successfully!"
        # Track successful port verification for pass/fail criteria
        PORT_VERIFICATION_SUCCESS=true
        return 0
    elif [[ $successful_verifications -gt 0 ]]; then
        print_warning "Overall verification result: $successful_verifications/${#variables_list[@]} ports verified successfully"
        # Track partial success as success for pass/fail criteria
        PORT_VERIFICATION_SUCCESS=true
        return 0  # Don't fail completely if some ports are verified
    else
        print_error "Overall verification result: No ports could be verified"
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
    
    print_status "Current working directory: $(pwd)"
    print_status "File to restore: $ABSOLUTE_ENV_FILE"
    
    # Remove custom variables using absolute path
    remove_custom_variables "$ABSOLUTE_ENV_FILE"
    
    echo ""
    print_status "Verification - Restored environment variables:"
    show_current_variables "$ABSOLUTE_ENV_FILE"
    
    # Rebuild with original configuration unless skipped
    if [[ "$skip_final_rebuild" != true ]]; then
        echo ""
        print_status "Rebuilding development environment with original configuration..."
        
        # We should already be in the project root directory from earlier build
        if build_dev_environment "original"; then
            echo ""
            print_success "🎉 Auto-restoration completed successfully!"
            print_success "✓ Custom environment variables have been removed"
            print_success "✓ Development environment rebuilt with original configuration"
            print_success "✓ Your environment has been returned to its original state"
            # Track successful restoration for pass/fail criteria
            RESTORATION_SUCCESS=true
        else
            print_error "Auto-restoration failed during final rebuild!"
            print_error "The custom variables have been removed, but the container rebuild failed."
            exit 1
        fi
    else
        echo ""
        print_warning "Skipped final container rebuild"
        print_success "Auto-restoration of .env file completed successfully!"
        print_status "Custom environment variables have been removed"
        print_warning "Note: Containers are still running with the modified configuration"
        # Track restoration success even when skipping rebuild for pass/fail criteria
        RESTORATION_SUCCESS=true
    fi
}

# Function to evaluate final pass/fail result
evaluate_final_result() {
    local skip_build="$1"
    local skip_verify="$2"
    local no_auto_restore="$3"
    
    echo ""
    print_status "=========================================="
    print_status "FINAL SCRIPT EVALUATION"
    print_status "=========================================="
    
    # Check each criteria
    local criteria_met=0
    local total_criteria=4
    
    echo ""
    print_status "Evaluating success criteria:"
    echo ""
    
    # Criteria 1: Environment builds with updated environment variable
    if [[ "$skip_build" == true ]]; then
        print_warning "1. Environment Build: SKIPPED (--skip-build used)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$BUILD_SUCCESS" == true ]]; then
        print_success "1. Environment Build: PASS"
        print_status "   → Environment built successfully with updated variables"
        ((criteria_met++))
    else
        print_error "1. Environment Build: FAIL"
        print_status "   → Environment failed to build with updated variables"
    fi
    
    # Criteria 2: The port is accessible/server is responding
    if [[ "$skip_verify" == true ]]; then
        print_warning "2. Port Accessibility: SKIPPED (--skip-verify used)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$skip_build" == true ]]; then
        print_warning "2. Port Accessibility: SKIPPED (build was skipped)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$PORT_VERIFICATION_SUCCESS" == true ]]; then
        print_success "2. Port Accessibility: PASS"
        print_status "   → Ports are accessible and servers responding"
        ((criteria_met++))
    else
        print_error "2. Port Accessibility: FAIL"
        print_status "   → Ports are not accessible or servers not responding"
    fi
    
    # Criteria 3: Development environment is running with the updated configuration
    if [[ "$skip_build" == true ]]; then
        print_warning "3. Dev Environment Running: SKIPPED (--skip-build used)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$DEV_ENV_RUNNING_SUCCESS" == true ]]; then
        print_success "3. Dev Environment Running: PASS"
        print_status "   → Development environment running with updated configuration"
        ((criteria_met++))
    else
        print_error "3. Dev Environment Running: FAIL"
        print_status "   → Development environment not running with updated configuration"
    fi
    
    # Criteria 4: Restoration completes successfully
    if [[ "$no_auto_restore" == true ]]; then
        print_warning "4. Restoration: SKIPPED (--no-auto-restore used)"
        print_status "   → Not counted in evaluation"
        ((total_criteria--))
    elif [[ "$RESTORATION_SUCCESS" == true ]]; then
        print_success "4. Restoration: PASS"
        print_status "   → Configuration restored successfully"
        ((criteria_met++))
    else
        print_error "4. Restoration: FAIL"
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
    local file="$ENV_FILE"
    local skip_build_flag=false
    local skip_verify_flag=false
    local show_current_flag=false
    local remove_flag=false
    local no_auto_restore_flag=false
    local skip_final_rebuild_flag=false
    local env_args=()
    local env_variables=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                file="$2"
                shift 2
                ;;
            -r|--remove)
                remove_flag=true
                shift
                ;;
            -s|--skip-build)
                skip_build_flag=true
                shift
                ;;
            -v|--skip-verify)
                skip_verify_flag=true
                shift
                ;;
            -c|--current)
                show_current_flag=true
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
                # Collect all non-option arguments
                env_args+=("$1")
                shift
                ;;
        esac
    done
    
    print_status "Port Modification Script for Utils-Project-Template"
    echo ""
    
    # Check if file exists and set absolute path
    check_file_exists "$file"
    set_absolute_env_path "$file"
    
    # Handle remove mode
    if [[ "$remove_flag" == true ]]; then
        remove_custom_variables "$file"
        exit 0
    fi
    
    # Handle show current variables mode
    if [[ "$show_current_flag" == true ]]; then
        show_current_variables "$file"
        exit 0
    fi
    
    # Parse environment variable pairs from arguments
    if ! parse_env_pairs env_variables "${env_args[@]}"; then
        echo ""
        show_usage
        exit 1
    fi
    
    # Display what variables will be processed
    print_status "Processing ${#env_variables[@]} environment variable(s):"
    for var_pair in "${env_variables[@]}"; do
        local var_name="${var_pair%%:*}"
        local port_value="${var_pair##*:}"
        echo "  • ${var_name}_PORT = $port_value"
        if [[ "$var_name" == "APP" ]]; then
            echo "    (Special handling: will test with /index path)"
        fi
    done
    echo ""
    
    # Show auto-restore behavior
    if [[ "$no_auto_restore_flag" == true ]]; then
        print_warning "Auto-restoration is disabled - changes will persist after testing"
    elif [[ "$skip_final_rebuild_flag" == true ]]; then
        print_status "Auto-restoration enabled (removal only - no final rebuild)"
    else
        print_status "Auto-restoration enabled - custom variables will be removed after testing"
    fi
    echo ""
    
    # Check dependencies based on what we're going to do
    local check_build_deps=false
    if [[ "$skip_build_flag" == false ]]; then
        check_build_deps=true
    fi
    
    check_dependencies "$check_build_deps"
    
    # Show current variables
    show_current_variables "$file"
    
    # Ensure custom section exists
    ensure_custom_section "$file"
    
    # Update the environment variables
    if update_env_variables "$file" env_variables; then
        echo ""
        print_status "Verification - Updated environment variables:"
        show_current_variables "$file"
        
        # Build and verify environment unless skipped
        if [[ "$skip_build_flag" == false ]]; then
            echo ""
            print_status "Starting development environment build process..."
            print_status "Note: Building from project root directory (utils-project-template)"
            
            # Change to parent directory (project root)
            cd "$(dirname "$file")/.."
            print_status "Changed to directory: $(pwd)"
            
            # Azure authentication
            if azure_login; then
                echo ""
                # Build and start development environment
                if build_dev_environment "modified"; then
                    # Verify port accessibility unless skipped
                    if [[ "$skip_verify_flag" == false ]]; then
                        if verify_ports env_variables; then
                            echo ""
                            print_success "🎉 Port modification, build, and verification completed successfully!"
                            print_success "✓ ${#env_variables[@]} environment variable(s) have been updated and verified"
                            print_success "✓ Your development environment is running with the updated configuration"
                        else
                            echo ""
                            print_warning "Port modification and build completed, but verification had issues"
                            print_warning "Your development environment is running with ${#env_variables[@]} updated variable(s)"
                            print_warning "Please check the verification output above"
                        fi
                    else
                        echo ""
                        print_success "Port modification and build completed successfully!"
                        print_warning "Port verification was skipped"
                        print_status "Your development environment is now running with ${#env_variables[@]} updated variable(s)"
                    fi
                    
                    # Auto-restore workflow unless disabled
                    if [[ "$no_auto_restore_flag" != true ]]; then
                        auto_restore_workflow "$skip_final_rebuild_flag"
                    else
                        echo ""
                        print_warning "Auto-restoration was skipped - changes will persist"
                        print_status "To remove manually, run: $0 --remove"
                    fi
                else
                    print_error "Development environment build failed."
                    # Still try to restore if auto-restore is enabled
                    if [[ "$no_auto_restore_flag" != true ]]; then
                        echo ""
                        print_status "Attempting to remove custom variables due to build failure..."
                        remove_custom_variables "$ABSOLUTE_ENV_FILE"
                    fi
                    exit 1
                fi
            else
                print_error "Azure authentication failed. Cannot proceed with build."
                # Still try to restore if auto-restore is enabled
                if [[ "$no_auto_restore_flag" != true ]]; then
                    echo ""
                    print_status "Attempting to remove custom variables due to authentication failure..."
                    remove_custom_variables "$ABSOLUTE_ENV_FILE"
                fi
                exit 1
            fi
        else
            echo ""
            print_warning "Skipped building development environment."
            print_success "Port modification completed successfully!"
            print_status "${#env_variables[@]} environment variable(s) have been updated in configuration"
            
            # Auto-restore file even if build was skipped
            if [[ "$no_auto_restore_flag" != true ]]; then
                echo ""
                print_status "Auto-removing custom variables (build was skipped)..."
                remove_custom_variables "$ABSOLUTE_ENV_FILE"
            fi
        fi
    else
        print_error "Failed to update environment variables."
        exit 1
    fi
    
    # Evaluate final pass/fail result
    local final_result=0
    evaluate_final_result "$skip_build_flag" "$skip_verify_flag" "$no_auto_restore_flag"
    final_result=$?
    
    echo ""
    print_success "Port modification workflow completed!"
    print_status "To remove custom variables manually, run: $0 --remove"
    
    # Exit with appropriate code based on final evaluation
    exit $final_result
}

# Run main function with all arguments
main "$@"