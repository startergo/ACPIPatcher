# GitHub Actions CI/CD Documentation

This document describes the comprehensive GitHub Actions workflows used to build, test, and release ACPIPatcher across multiple platforms.

## Overview

The ACPIPatcher project uses 4 GitHub Actions workflows to ensure code quality, cross-platform compatibility, and automated releases:

| Workflow | Purpose | Trigger | Duration |
|----------|---------|---------|----------|
| **build-and-test.yml** | Comprehensive build & release | Push, PR, Tags | ~15-20 min |
| **ci.yml** | Quick build & validation | Push, PR | ~8-12 min |
| **comprehensive-test.yml** | Advanced testing & analysis | Push, PR, Schedule | ~20-30 min |
| **release.yml** | Release asset management | Release creation | ~2-5 min |

## Workflow Details

### 1. Build and Test (`build-and-test.yml`)

**Purpose**: Primary CI/CD pipeline for building, testing, and releasing ACPIPatcher

**Triggers**:
- Push to `main` or `develop` branches
- Pull requests to `main`
- Git tags starting with `v*`
- Manual dispatch with debug level selection

**Features**:
- ✅ Cross-platform builds (Linux, macOS, Windows)
- ✅ Multi-architecture support (X64, IA32)
- ✅ Debug and Release configurations
- ✅ Static code analysis
- ✅ Automated artifact packaging
- ✅ Release creation for tags
- ✅ Build notifications and summaries

**Build Matrix**:
```yaml
Platform    | Architecture | Toolchain | Status
------------|-------------|-----------|--------
Linux       | X64, IA32   | GCC5      | ✅
macOS       | X64         | XCODE5    | ✅
Windows     | X64, IA32   | VS2019    | ✅
```

**Artifacts Generated**:
- `ACPIPatcher-{BUILD_TYPE}-{ARCH}-{PLATFORM}.{tar.gz|zip}`
- `ACPIPatcher-All-Platforms.tar.gz` (combined package)
- Static analysis results
- Build information files

**Manual Trigger Options**:
```yaml
debug_level:
  description: 'Debug Level (1-4)'
  options: ['1', '2', '3', '4']
  default: '3'
```

### 2. Quick CI (`ci.yml`)

**Purpose**: Fast feedback for development with essential builds and checks

**Triggers**:
- Push to `main` or `develop` branches
- Pull requests to `main`
- Manual dispatch

**Features**:
- ✅ Streamlined build matrix
- ✅ Essential platform coverage
- ✅ Quick static analysis
- ✅ Fail-fast strategy disabled
- ✅ Shorter feedback loop

**Build Matrix**:
```yaml
Platform    | Architecture | Build Types    | Toolchain
------------|-------------|----------------|----------
Linux       | X64, IA32   | RELEASE, DEBUG | GCC5
macOS       | X64         | RELEASE, DEBUG | XCODE5
Windows     | X64, IA32   | RELEASE        | VS2019
```

**Use Cases**:
- Development branch validation
- Pull request checks
- Quick smoke testing
- Pre-commit validation

### 3. Comprehensive Testing (`comprehensive-test.yml`)

**Purpose**: In-depth analysis, security scanning, and compatibility testing

**Triggers**:
- Push to `main` or `develop` branches (when ACPIPatcherPkg/** or workflows change)
- Pull requests to `main`
- Nightly schedule (2 AM UTC)
- Manual dispatch with test level selection

**Features**:
- 🔒 **Security Analysis**: CodeQL, Bandit, dependency scanning
- 📊 **Code Coverage**: Comprehensive coverage analysis
- 🔍 **Static Analysis**: Multiple tools (cppcheck, clang-tidy, PVS-Studio)
- 🧪 **Compatibility Testing**: Multiple EDK II versions
- ⚡ **Performance Testing**: Build time and binary size analysis
- 📋 **Compliance**: MISRA C, coding standards validation

**Manual Trigger Options**:
```yaml
test_level:
  description: 'Test Level'
  options: ['basic', 'standard', 'comprehensive']
  default: 'standard'

enable_coverage:
  description: 'Enable Code Coverage'
  type: boolean
  default: false
```

**Analysis Tools**:
- **Security**: CodeQL, Bandit, Safety
- **Static Analysis**: cppcheck, clang-tidy, PVS-Studio
- **Code Quality**: SonarCloud integration
- **Performance**: Build metrics, binary analysis

### 4. Release Management (`release.yml`)

**Purpose**: Automated release asset upload and management

**Triggers**:
- GitHub release publication
- Manual dispatch with tag specification

**Features**:
- ✅ Automatic asset collection
- ✅ Release artifact upload
- ✅ Asset verification
- ✅ Release notes integration

**Manual Trigger Options**:
```yaml
tag_name:
  description: 'Tag name for release'
  required: true
  default: 'v1.1.0'
```

## Usage Guide

### For Developers

#### Running Workflows Manually

1. **Navigate** to Actions tab in GitHub repository
2. **Select** the desired workflow
3. **Click** "Run workflow"
4. **Configure** parameters (if available)
5. **Monitor** progress in the Actions tab

#### Debug Level Configuration

The `build-and-test.yml` workflow supports custom debug levels:

- **Level 1**: Error messages only
- **Level 2**: Errors + warnings
- **Level 3**: Errors + warnings + info (default)
- **Level 4**: All debug output + verbose logging

#### Interpreting Results

**Build Status Icons**:
- ✅ **Success**: All builds completed successfully
- ❌ **Failure**: One or more builds failed
- 🟡 **In Progress**: Workflow currently running
- ⏸️ **Cancelled**: Workflow was cancelled

**Artifact Downloads**:
- Navigate to the completed workflow run
- Scroll to "Artifacts" section
- Download platform-specific packages

### For Maintainers

#### Release Process

1. **Create and push a tag**:
   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```

2. **Create GitHub Release**:
   - Go to Releases → "Create a new release"
   - Select the tag
   - Add release notes
   - Publish release

3. **Automated Process**:
   - `build-and-test.yml` triggers on tag
   - Builds all platforms and architectures
   - Creates release with assets
   - Uploads artifacts automatically

#### Monitoring and Troubleshooting

**Common Issues**:

1. **EDK II Setup Failures**:
   - Check EDK II version compatibility
   - Verify submodule initialization
   - Review BaseTools compilation

2. **Build Failures**:
   - Check compiler version compatibility
   - Verify toolchain installation
   - Review build log for missing dependencies

3. **Artifact Upload Issues**:
   - Verify GitHub token permissions
   - Check artifact file paths
   - Review upload action logs

**Debugging Steps**:

1. **Enable Debug Output**:
   ```yaml
   env:
     ACTIONS_STEP_DEBUG: true
     ACTIONS_RUNNER_DEBUG: true
   ```

2. **Check Workflow Logs**:
   - Click on failed job
   - Expand error step
   - Review detailed logs

3. **Local Reproduction**:
   ```bash
   # Use act to run GitHub Actions locally
   brew install act
   act -j build-linux
   ```

## Configuration

### Environment Variables

```yaml
EDK2_VERSION: edk2-stable202202    # EDK II version
DEBUG_LEVEL: '3'                   # Default debug level
TEST_LEVEL: 'standard'             # Default test level
```

### Matrix Strategy

The workflows use matrix strategies for cross-platform builds:

```yaml
strategy:
  fail-fast: false  # Continue other builds if one fails
  matrix:
    include:
      - os: linux
        runner: ubuntu-latest
        arch: X64
        build_type: RELEASE
        toolchain: GCC5
      # ... additional configurations
```

### Caching Strategy

**EDK II Caching**:
```yaml
- name: Cache EDK2
  uses: actions/cache@v3
  with:
    path: edk2
    key: edk2-${{ env.EDK2_VERSION }}-${{ matrix.os }}-${{ matrix.arch }}
```

**Benefits**:
- Faster workflow execution
- Reduced external dependencies
- Improved reliability

## Security Considerations

### Secrets Management

The workflows use the following secrets:
- `GITHUB_TOKEN`: Automatic token for release uploads
- Additional secrets may be configured for extended features

### Security Scanning

**Enabled Scans**:
- Dependency vulnerability scanning
- Static analysis security rules
- Code injection prevention
- Input validation checks

### Best Practices

1. **Minimal Permissions**: Workflows use least-privilege access
2. **Input Validation**: All manual inputs are validated
3. **Secure Dependencies**: Pinned action versions
4. **Artifact Integrity**: Checksums and verification

## Performance Optimization

### Build Time Optimization

1. **Parallel Builds**: Matrix strategy enables parallel execution
2. **Caching**: EDK II and dependency caching
3. **Incremental Builds**: Smart rebuild detection
4. **Resource Allocation**: Optimized runner selection

### Resource Usage

| Workflow | Avg Duration | Peak Memory | Artifacts Size |
|----------|-------------|-------------|----------------|
| build-and-test | 15-20 min | 4 GB | 50-100 MB |
| ci | 8-12 min | 2 GB | 30-60 MB |
| comprehensive-test | 20-30 min | 6 GB | 100-200 MB |
| release | 2-5 min | 1 GB | N/A |

## Extending the Workflows

### Adding New Platforms

1. **Update Matrix Configuration**:
   ```yaml
   matrix:
     include:
       - os: new-platform
         runner: platform-runner
         arch: ARCH
         toolchain: TOOLCHAIN
   ```

2. **Add Platform-Specific Steps**:
   ```yaml
   - name: Install Dependencies (New Platform)
     if: matrix.os == 'new-platform'
     run: platform-specific-commands
   ```

### Adding New Tests

1. **Create New Job**:
   ```yaml
   new-test-job:
     name: New Test Suite
     runs-on: ubuntu-latest
     steps:
       - name: Run New Tests
         run: test-commands
   ```

2. **Add Dependencies**:
   ```yaml
   needs: [build-linux, build-macos, build-windows]
   ```

### Custom Analysis Tools

1. **Install Tool**:
   ```yaml
   - name: Install Analysis Tool
     run: installation-commands
   ```

2. **Run Analysis**:
   ```yaml
   - name: Run Analysis
     run: analysis-commands
   ```

3. **Upload Results**:
   ```yaml
   - name: Upload Results
     uses: actions/upload-artifact@v3
     with:
       name: analysis-results
       path: results/
   ```

## Maintenance

### Regular Updates

1. **Action Versions**: Update to latest stable versions quarterly
2. **EDK II Version**: Update when new stable releases available
3. **Tool Versions**: Keep analysis tools current
4. **Runner Images**: Use latest available images

### Monitoring

1. **Workflow Success Rates**: Monitor build reliability
2. **Performance Metrics**: Track execution times
3. **Resource Usage**: Monitor cost and efficiency
4. **Security Alerts**: Address vulnerability reports

### Troubleshooting Guide

**Common Fixes**:

1. **Cache Issues**:
   ```bash
   # Clear cache if builds fail unexpectedly
   # Go to Actions → Caches → Delete problematic cache
   ```

2. **Permission Issues**:
   ```yaml
   permissions:
     contents: read
     actions: read
     security-events: write
   ```

3. **Timeout Issues**:
   ```yaml
   timeout-minutes: 60  # Extend for complex builds
   ```

## Resources

### Documentation Links
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Action Marketplace](https://github.com/marketplace/actions/)

### Project-Specific Resources
- [README.md](README.md) - Main project documentation
- [DEBUG_GUIDE.md](DEBUG_GUIDE.md) - Debugging instructions
- [IMPROVEMENTS.md](IMPROVEMENTS.md) - Code improvements documentation

### Support
- Create an issue for workflow problems
- Check existing workflow runs for similar issues
- Review workflow logs for detailed error information

---

*Last updated: July 7, 2025*
*For questions or improvements, please create an issue or pull request.*
