# Dependency Exclusion Test Script

## Overview

The `test_dependency_exclusion.sh` script automates the testing of application behavior when required dependencies are missing by performing the following key actions:

1. **Backs up the original** `.iqgeorc.jsonc` configuration file
2. **Empties all dependency arrays** in the platform configuration section
3. **Runs `npx project-update`** to apply the dependency-free configuration
4. **Authenticates with Azure** Container Registry for deployment access
5. **Builds and starts** the development environment without dependencies
6. **Tests application accessibility** via HTTP requests to verify expected failure
7. **Auto-restores original configuration** with all dependencies intact
8. **Verifies restoration success** and provides guidance for manual container rebuild if needed

The script validates that the application properly fails when required dependencies are missing and can be successfully restored to working state, ensuring dependency management works as expected.

## Purpose

This script provides automated quality assurance for dependency management, specifically testing:
- Application behavior with missing required dependencies
- Configuration file modification and dependency removal
- Container deployment with insufficient dependencies
- Application failure detection and validation
- Configuration restoration and environment recovery
- Complete workflow from failure simulation to restoration

## Core Functionalities

### 1. **Configuration Management**
- Automatic backup and restoration of `.iqgeorc.jsonc`
- Safe removal of all dependency arrays from platform configuration
- JSON structure preservation during modification
- Comprehensive dependency status reporting

### 2. **Dependency Removal**
- Systematic emptying of devenv, appserver, and tools dependency arrays
- Platform configuration section targeting and modification
- Validation of dependency removal completeness
- Pre and post-modification status comparison

### 3. **Environment Testing**
- Azure Container Registry authentication
- Docker Compose container orchestration with missing dependencies
- Application accessibility testing via HTTP requests
- Expected failure validation and reporting

### 4. **Restoration and Recovery**
- Automatic restoration of original dependency configuration
- Fast restoration without automatic container rebuild
- Clear guidance for manual container rebuild when needed
- Configuration verification and cleanup

### 5. **Workflow Automation**
- Step-by-step progress tracking with colored output
- Configurable workflow steps (skip options for testing)
- Automatic cleanup and restoration on completion
- Comprehensive error handling and recovery

## Test Workflow

```mermaid
graph TD
    A[Start Test] --> B[Backup Configuration]
    B --> C[Show Current Dependencies]
    C --> D[Empty All Dependency Arrays]
    D --> E[Run npx project-update]
    E --> F[Azure Authentication]
    F --> G[Build Environment (No Dependencies)]
    G --> H[Test Application Accessibility]
    H --> I[Validate Expected Failure]
    I --> J[Auto-Restore Configuration]
    J --> K[Run project-update (Restored)]
    K --> L[Verify Restoration Success]
    L --> M[Cleanup & Exit]
```

## Command Usage

### Basic Dependency Exclusion Test
```bash
cd /path/to/qa_test_automation
chmod +x test_dependency_exclusion.sh

# Full workflow with auto-restore
./test_dependency_exclusion.sh

# Manual restore only
./test_dependency_exclusion.sh --restore
```

### Advanced Testing Options
```bash
# Skip container building (config only)
./test_dependency_exclusion.sh --skip-build

# Skip application testing
./test_dependency_exclusion.sh --skip-test

# Skip project update step
./test_dependency_exclusion.sh --skip-update

# Test without auto-restore
./test_dependency_exclusion.sh --no-auto-restore
```

### Configuration Management
```bash
# Use custom configuration file
./test_dependency_exclusion.sh --file /path/to/.iqgeorc.jsonc

# View current dependency status
grep -A 10 '"platform"' ../.iqgeorc.jsonc

# Check backup file
ls -la ../.iqgeorc.jsonc.backup
```

### Container and Application Inspection
```bash
# Check container status
docker ps

# View container logs
docker logs iqgeo_myproj

# Test application manually
curl -I http://localhost/index

# Check container build logs
docker compose -f .devcontainer/docker-compose.yml logs
```

## Success Scenarios

### ✅ **Test Passes When:**

1. **Configuration Operations Succeed**
   - `.iqgeorc.jsonc` file exists and is writable
   - Backup creation completes successfully
   - Dependency arrays are successfully emptied
   - JSON structure remains valid after modification

2. **Project Integration Works**
   - `npx project-update` processes dependency-free configuration
   - Configuration changes apply to repository structure
   - No critical errors during update process
   - Modified configuration is properly validated

3. **Container Operations Complete**
   - Azure Container Registry authentication succeeds
   - Containers build despite missing dependencies
   - Container deployment completes (may have warnings)
   - Development environment starts in degraded state

4. **Application Failure Detection**
   - Application accessibility test returns expected failure codes
   - HTTP requests fail as expected (502, 503, connection refused)
   - Application properly demonstrates dependency requirements
   - Failure behavior is consistent and predictable

5. **Restoration Process Works**
   - Original configuration restores successfully
   - Dependencies are properly restored to all arrays
   - Restoration completes quickly without rebuild
   - Manual rebuild guidance provided when needed

## Failure Scenarios

### ❌ **Test Fails When:**

1. **Prerequisites Missing**
   ```
   Error: npx (Node.js) not found
   Error: docker not found
   Error: az (Azure CLI) not found
   Error: curl not found
   ```

2. **Configuration Issues**
   ```
   Error: .iqgeorc.jsonc not found
   Error: Failed to create backup file
   Error: Failed to modify .iqgeorc.jsonc file
   Error: JSON structure corruption during modification
   ```

3. **Project Update Problems**
   ```
   Error: Project update failed
   Solution: Check Node.js installation, package.json validity, network connectivity
   ```

4. **Authentication Failures**
   ```
   Error: Azure authentication failed
   Solution: Run 'az login' or verify registry access permissions
   ```

5. **Container Build Issues**
   ```
   Error: Development environment build failed
   Solution: Check Docker daemon, image availability, container conflicts
   
   Warning: Containers built but not all services started
   Solution: Expected behavior - some services may fail without dependencies
   ```

6. **Application Testing Problems**
   ```
   Error: Application accessibility test inconclusive
   Error: Unexpected success response (application should fail)
   Solution: Verify dependency removal was complete, check container logs
   ```

7. **Restoration Failures**
   ```
   Error: Failed to restore from backup
   Error: Container rebuild with dependencies failed
   Solution: Check backup file integrity, Docker resources, network connectivity
   ```

## Expected Outcomes

### **Dependency Exclusion States**
- **Success**: Application fails as expected due to missing dependencies
- **Partial Success**: Application partially loads but with errors/warnings
- **Unexpected Success**: Application works despite missing dependencies (investigation needed)
- **Build Failure**: Containers fail to build (acceptable outcome)

### **Application Response Codes**
- **502 Bad Gateway**: Service unavailable due to missing dependencies (EXPECTED)
- **503 Service Unavailable**: Service degraded due to missing components (EXPECTED)
- **Connection Refused**: Application failed to start properly (EXPECTED)
- **200 OK**: Application working despite missing dependencies (UNEXPECTED - needs review)

### **Restoration Verification**
- **Full Restoration**: All dependencies restored, application fully functional
- **Partial Restoration**: Some dependencies restored, application partially working
- **Restoration Failed**: Configuration restored but container rebuild failed
- **Verification Failed**: Cannot confirm restoration success due to testing issues

## Test Output Example

```
[INFO] Current dependency configuration:
  Line 45: "devenv": ["python3", "nodejs", "redis"]
  Line 46: "appserver": ["postgresql", "apache2"]
  Line 47: "tools": ["git", "docker"]

[SUCCESS] Backup created: /path/to/.iqgeorc.jsonc.backup
[SUCCESS] All dependency arrays have been emptied successfully!
[SUCCESS] Project update completed successfully!
[SUCCESS] Azure authentication completed successfully!
[SUCCESS] Development environment build completed successfully!

[INFO] Testing application accessibility...
[WARNING] Application failed to respond (HTTP 502) - This is expected behavior
[SUCCESS] ✓ Application properly failed due to missing dependencies

===========================================
AUTOMATIC RESTORATION PROCESS
===========================================
[SUCCESS] Configuration has been restored to original state
[SUCCESS] ✓ File restoration completed successfully!
[INFO] Note: Final container rebuild skipped for faster execution.
[INFO] If you need containers rebuilt with restored dependencies, run:
[INFO]   docker compose -f ".devcontainer/docker-compose.yml" --profile iqgeo up -d --build
```

## Troubleshooting Guide

### **Configuration Issues**
1. **File not found**: Verify you're in `qa_test_automation` directory
2. **Backup creation fails**: Check write permissions on project root
3. **JSON corruption**: Use `--restore` to recover from backup
4. **Dependency parsing errors**: Verify JSON structure before running

### **Project Update Problems**  
1. **Command not found**: Install Node.js and ensure npm is available
2. **Update fails**: Check `package.json` exists in project root directory
3. **Configuration errors**: Verify `.iqgeorc.jsonc` syntax is valid
4. **Network issues**: Check internet connectivity and npm registry access

### **Container Build Issues**
1. **Docker not running**: Start Docker daemon service
2. **Build failures**: Expected behavior - some containers may fail without dependencies
3. **Port conflicts**: Stop conflicting services or change port mappings
4. **Resource limits**: Free up disk space and memory for container builds

### **Application Testing Issues**
1. **Unexpected success**: Verify dependency removal was complete
2. **Connection timeouts**: Increase wait time, check container startup logs
3. **Inconsistent results**: Run test multiple times, check for race conditions
4. **Network problems**: Verify localhost access and port configurations

### **Restoration Problems**
1. **Backup missing**: Recreate backup from git history or clean repository
2. **Restore fails**: Check file permissions and backup file integrity
3. **Container rebuild issues**: Verify Docker resources and network connectivity
4. **Application still broken**: Check container logs, verify dependency installation

## Dependencies

- **Node.js/npm**: Project update execution and configuration processing
- **Docker**: Container building and deployment
- **Docker Compose**: Multi-container orchestration
- **Azure CLI**: Container registry authentication
- **curl**: Application accessibility testing
- **bash**: Script execution environment
- **Standard utilities**: grep, sed, cp, mv, sleep

## Configuration Files

- **`.iqgeorc.jsonc`**: Main project configuration with dependency arrays
- **`.iqgeorc.jsonc.backup`**: Automatic backup created during testing
- **`package.json`**: Node.js project configuration for project-update
- **`.devcontainer/docker-compose.yml`**: Container deployment specification

## Exit Codes

- **0**: Test completed successfully (dependencies removed, tested, and restored)
- **1**: Test failed due to errors in configuration, build, or restoration process

## Script Options

| Option | Description | Default Behavior |
|--------|-------------|------------------|
| `--file FILE` | Specify custom .iqgeorc.jsonc path | `../.iqgeorc.jsonc` |
| `--restore` | Manual restore from backup only | Run full test workflow |
| `--skip-update` | Skip `npx project-update` step | Run project-update |
| `--skip-build` | Skip container building phase | Build containers |
| `--skip-test` | Skip application accessibility test | Test application |
| `--no-auto-restore` | Skip automatic restoration | Auto-restore after test |

## Notes

- **Expected application failure**: Application should fail when dependencies are missing
- **Auto-restore by default**: Original configuration is automatically restored
- **Safe testing**: Automatic backups prevent permanent configuration loss  
- **Fast execution**: Skips final container rebuild for improved performance
- **Manual rebuild option**: Provides exact command for container rebuild when needed
- **Dependency validation**: Confirms that declared dependencies are actually required
- **Comprehensive logging**: Detailed output for troubleshooting and validation