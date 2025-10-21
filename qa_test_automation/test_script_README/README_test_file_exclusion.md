# File Exclusion Test Script

## Overview

The `test_file_exclusion.sh` script automates the testing of file exclusion functionality in the IQGeo Utils-Project-Template by performing the following key actions:

1. **Creates temporary backup** of the original `.iqgeorc.jsonc` configuration file
2. **Resets exclude_file_paths** to an empty array to clear existing exclusions
3. **Updates the platform version** to a specified target version (default: 7.2)
4. **Sets file exclusion** to include only the specified dockerfile (`.devcontainer/dockerfile`)
5. **Runs `npx project-update`** to apply configuration changes to the repository
6. **Verifies file exclusion** using git status to confirm excluded files don't appear in changes
7. **Auto-restores original configuration** and runs project-update to return to clean state
8. **Generates comprehensive test reports** showing pass/fail status for each step

The script validates that file exclusion functionality works correctly by ensuring excluded files don't appear in git status after configuration updates, confirming the exclude_file_paths setting is properly implemented.

## Purpose

This script provides automated quality assurance for file exclusion configuration, specifically testing:
- Configuration file modification for exclude_file_paths settings
- Platform version update functionality
- Project update integration with exclusion settings
- Git status verification to confirm exclusion effectiveness
- Complete workflow validation from configuration to verification

## Core Functionalities

### 1. **Configuration Management**
- Automatic temporary backup and restoration of `.iqgeorc.jsonc`
- Safe modification of JSON configuration with validation
- exclude_file_paths array manipulation (reset and set operations)
- Platform version updating with precise targeting
- Fast restoration without permanent backup files

### 2. **File Exclusion Testing**
- Reset exclusions to empty state for clean testing
- Single file exclusion setting (replaces all existing entries)
- Configurable exclusion file specification
- Validation that exclusions are properly applied

### 3. **Project Integration**
- `npx project-update` execution to apply changes
- Directory management for proper command execution
- Configuration change propagation to repository structure
- Integration with existing project build processes

### 4. **Git Verification**
- Git status checking to verify exclusion effectiveness
- Parsing of git status output for excluded file detection
- Comprehensive reporting of git changes and exclusions
- Validation that excluded files remain untracked

### 5. **Test Automation**
- Step-by-step progress tracking with colored output
- Configurable workflow options (skip flags for testing)
- Comprehensive error handling and recovery
- Detailed success/failure reporting with actionable feedback

## Test Workflow

```mermaid
graph TD
    A[Start Test] --> B[Check Prerequisites]
    B --> C[Backup Configuration]
    C --> D[Show Current Config]
    D --> E[Reset exclude_file_paths to Empty]
    E --> F[Update Platform Version]
    F --> G[Set File Exclusion]
    G --> H[Run npx project-update]
    H --> I[Wait for Changes]
    I --> J[Verify with Git Status]
    J --> K[Generate Test Report]
    K --> L[Auto-Restore Original Config]
    L --> M[Run project-update (Restored)]
    M --> N[Cleanup & Exit]
```

## Command Usage

### Basic File Exclusion Test
```bash
cd /path/to/qa_test_automation
chmod +x test_file_exclusion.sh

# Full test with default settings (includes auto-restore)
./test_file_exclusion.sh
```

### Advanced Configuration Options
```bash
# Use custom platform version
./test_file_exclusion.sh --version 7.3

# Use custom configuration file
./test_file_exclusion.sh --file /path/to/.iqgeorc.jsonc

# Skip project update step
./test_file_exclusion.sh --skip-update

# Skip git status verification
./test_file_exclusion.sh --skip-git

# Test without auto-restore (leaves modified configuration)
./test_file_exclusion.sh --no-auto-restore
```

### Configuration Management
```bash
# View current exclude_file_paths setting
grep -A 5 '"exclude_file_paths"' ../.iqgeorc.jsonc

# Check platform version
grep '"version"' ../.iqgeorc.jsonc

# Note: Script uses temporary backup files that are automatically cleaned up
# Use version control to restore if needed: git checkout ../.iqgeorc.jsonc
```

### Git and Project Inspection
```bash
# Check git status manually
git status --porcelain

# Run project update manually
npx project-update

# Check for excluded file changes
git status | grep '.devcontainer/dockerfile'
```

## Success Scenarios

### ✅ **Test Passes When:**

1. **Configuration Operations Succeed**
   - `.iqgeorc.jsonc` file exists and is writable
   - Backup creation completes successfully
   - exclude_file_paths array is reset to empty
   - Platform version is updated correctly

2. **File Exclusion Settings Work**
   - exclude_file_paths is set to specified file only
   - JSON structure remains valid after modifications
   - Configuration changes are properly saved
   - No syntax errors in resulting configuration

3. **Project Integration Works**
   - `npx project-update` executes without errors
   - Configuration changes apply to repository structure
   - Project files are updated according to new settings
   - No critical errors during update process

4. **Git Verification Passes**
   - Git status runs successfully
   - Excluded file does not appear in git status output
   - Other expected files may appear as modified
   - File exclusion is properly functioning

5. **Workflow Completion**
   - All test steps complete successfully
   - Comprehensive test report generated
   - Original configuration automatically restored
   - Clean exit with success status and no leftover files

## Failure Scenarios

### ❌ **Test Fails When:**

1. **Prerequisites Missing**
   ```
   Error: npx (Node.js) not found
   Error: git not found
   Error: .iqgeorc.jsonc not found
   ```

2. **Configuration Issues**
   ```
   Error: Failed to create backup file
   Error: Failed to modify file
   Error: JSON structure corruption during modification
   Error: Platform version not found in configuration
   ```

3. **File Exclusion Problems**
   ```
   Error: exclude_file_paths not found in configuration
   Error: Failed to reset exclude_file_paths to empty array
   Error: Failed to set file exclusion
   Warning: File exclusion was already set correctly
   ```

4. **Project Update Failures**
   ```
   Error: Project update failed
   Solution: Check Node.js installation, package.json validity, network connectivity
   ```

5. **Git Verification Issues**
   ```
   Error: Failed to run 'git status'
   Solution: Ensure you are in a git repository, check git installation
   
   Error: Excluded file appears in git status output
   Solution: File exclusion not working properly, check exclude_file_paths configuration
   ```

6. **Directory and Path Problems**
   ```
   Error: Not in correct directory for project-update
   Error: package.json not found
   Solution: Verify script is run from correct location, check project structure
   ```

## Expected Outcomes

### **File Exclusion States**
- **Success**: Excluded file does not appear in git status after changes
- **Partial Success**: Some exclusions work but configuration has issues
- **Failure**: Excluded file still appears in git status (exclusion not working)
- **Error**: Cannot verify due to git or configuration problems

### **Configuration Results**
- **Updated Successfully**: Platform version and exclusions set correctly
- **Already Current**: No changes needed, already in desired state
- **Partial Update**: Some settings updated, others failed
- **Update Failed**: Configuration modification unsuccessful

### **Git Status Verification**
- **Exclusion Working**: Target file excluded, other files may show as modified
- **Exclusion Failed**: Target file appears in git status (indicates problem)
- **No Changes**: No files modified by update process
- **Git Error**: Cannot verify due to git repository issues

## Test Output Example

```
[INFO] File Exclusion Test Script for Utils-Project-Template

[INFO] Current configuration:
  Line 11: "version": "7.1",
  Line 45: "exclude_file_paths": [".devcontainer/dockerfile", "README.md"]

[SUCCESS] Backup created: ../.iqgeorc.jsonc.backup
[INFO] Line 45: Reset exclude_file_paths from [".devcontainer/dockerfile", "README.md"] to empty array
[SUCCESS] exclude_file_paths successfully reset to empty array!

[INFO] Line 11: Updated platform version from '7.1' to '7.2'
[SUCCESS] Platform version successfully updated to '7.2' on line 11!

[INFO] Line 45: Set exclude_file_paths to only include '.devcontainer/dockerfile'
[SUCCESS] File exclusion successfully set on line 45!

[SUCCESS] Project update completed successfully!
[SUCCESS] ✓ SUCCESS: '.devcontainer/dockerfile' does not appear in git status output
[SUCCESS] File exclusion is working correctly!

==========================================
FILE EXCLUSION TEST SUMMARY
==========================================
✓ Test completed successfully!
✓ exclude_file_paths was reset to empty array
✓ Platform version was updated to '7.2'
✓ File exclusion was set to only include '.devcontainer/dockerfile'
✓ Project update completed without errors
✓ File exclusion verification passed - '.devcontainer/dockerfile' was properly excluded

===========================================
AUTOMATIC RESTORATION PROCESS
===========================================
[SUCCESS] ✓ Configuration has been restored to original state
[SUCCESS] ✓ File restoration completed successfully!
```

## Troubleshooting Guide

### **Configuration Issues**
1. **File not found**: Verify you're in `qa_test_automation` directory with parent containing `.iqgeorc.jsonc`
2. **Backup creation fails**: Check write permissions on project root directory
3. **JSON corruption**: Use `--restore` to recover from backup
4. **Version not found**: Verify `.iqgeorc.jsonc` has proper platform section structure

### **Project Update Problems**
1. **Command not found**: Install Node.js and ensure npm/npx are available
2. **Update fails**: Check `package.json` exists in project root directory
3. **Network issues**: Check internet connectivity and npm registry access
4. **Configuration errors**: Verify `.iqgeorc.jsonc` syntax is valid before update

### **Git Verification Issues**
1. **Git not found**: Install git or ensure it's in system PATH
2. **Not a git repository**: Run script from within a git repository
3. **Exclusion not working**: Check project-update applied changes correctly
4. **Unexpected git output**: Review git status manually to understand changes

### **File Exclusion Problems**
1. **Exclusion file not excluded**: Verify exclude_file_paths was set correctly
2. **Wrong file excluded**: Check EXCLUSION_FILE variable matches EXCLUDED_FILE_CHECK
3. **No files to exclude**: Ensure target file exists and would normally be modified
4. **Multiple exclusions**: Script replaces all exclusions with single target file

### **Directory and Path Issues**
1. **Wrong working directory**: Script changes to parent directory for project-update
2. **Relative path issues**: Verify ../.iqgeorc.jsonc path resolves correctly
3. **Permission denied**: Check file and directory permissions for modifications
4. **Path not found**: Ensure project structure matches expected layout

## Dependencies

- **Node.js/npm**: Project update execution and configuration processing
- **Git**: Version control status verification and exclusion validation
- **bash**: Script execution environment
- **Standard utilities**: grep, sed, cp, mv, mktemp, sleep

## Configuration Files

- **`.iqgeorc.jsonc`**: Main project configuration with platform version and exclusions
- **`/tmp/iqgeorc_backup.XXXXXX`**: Temporary backup created during testing (auto-cleaned)
- **`package.json`**: Node.js project configuration for project-update command
- **`.devcontainer/dockerfile`**: Default target file for exclusion testing

## Exit Codes

- **0**: Test completed successfully (file exclusion working properly)
- **1**: Test failed due to errors in configuration, update, or verification process

## Script Options

| Option | Description | Default Behavior |
|--------|-------------|------------------|
| `--file FILE` | Specify custom .iqgeorc.jsonc path | `../.iqgeorc.jsonc` |
| `--version VER` | Specify target platform version | `7.2` |
| `--skip-update` | Skip `npx project-update` step | Run project-update |
| `--skip-git` | Skip git status verification | Verify with git status |
| `--no-auto-restore` | Skip automatic restore at completion | Auto-restore after test |

## Known Limitations

⚠️ **Critical Issue**: Test only works if dockerfile has not already been modified and is present in uncommitted changes. This is a design limitation noted in the script comments.

## Important Notes

- **File exclusion limitation**: Test only works if dockerfile hasn't been modified and appears in uncommitted changes
- **Single file exclusion**: Script replaces all existing exclusions with target file only
- **Platform version targeting**: Updates version in platform section only (not global version)
- **Git repository required**: Verification step requires script to be run within git repository
- **Automatic restoration**: Temporary backup enables automatic restoration of original configuration
- **Clean testing**: Script resets exclusions to empty before setting target exclusion
- **Cross-platform compatibility**: Works on macOS and Linux environments