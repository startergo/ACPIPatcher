# GitHub Actions Workflow Structure

## Current Active Workflows

The ACPIPatcher project now has a clean, well-organized set of GitHub Actions workflows with distinct purposes:

### 1. **Build and Test ACPIPatcher** (`build-and-test.yml`)
- **Badge**: [![Build and Test](https://github.com/startergo/ACPIPatcher/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/startergo/ACPIPatcher/actions/workflows/build-and-test.yml)
- **Purpose**: Comprehensive build and testing across all platforms
- **Triggers**: 
  - Push to `main`/`develop` branches
  - Pull requests to `main`
  - Tags starting with `v*`
  - Manual dispatch with debug level selection
- **Platforms**: Linux (Ubuntu), macOS, Windows
- **Features**:
  - Multi-platform builds with proper error handling
  - Comprehensive artifact validation
  - Distribution package creation
  - Build verification and testing

### 2. **Quick CI** (`ci.yml`)
- **Badge**: [![Quick CI](https://github.com/startergo/ACPIPatcher/actions/workflows/ci.yml/badge.svg)](https://github.com/startergo/ACPIPatcher/actions/workflows/ci.yml)
- **Purpose**: Fast continuous integration for rapid feedback
- **Triggers**:
  - Push to `main`/`develop` branches
  - Pull requests to `main`
  - Manual dispatch
- **Platforms**: Linux, macOS, Windows
- **Features**:
  - Matrix builds across architectures (X64, IA32)
  - Both DEBUG and RELEASE configurations
  - Static analysis with CPPCheck
  - Lightweight and fast execution

### 3. **Comprehensive Testing** (`comprehensive-test.yml`)
- **Badge**: [![Comprehensive Testing](https://github.com/startergo/ACPIPatcher/actions/workflows/comprehensive-test.yml/badge.svg)](https://github.com/startergo/ACPIPatcher/actions/workflows/comprehensive-test.yml)
- **Purpose**: Extended testing and validation
- **Triggers**:
  - Weekly schedule (Sundays at 2 AM UTC)
  - Manual dispatch
  - Major releases
- **Features**:
  - Cross-platform compatibility testing
  - Multiple EDK2 versions
  - Extended build configurations
  - Performance benchmarking
  - Long-running stability tests

### 4. **Release ACPIPatcher** (`release.yml`)
- **Purpose**: Automated release creation and asset publishing
- **Triggers**:
  - Tags starting with `v*` (e.g., `v1.0.0`)
- **Features**:
  - Automatic GitHub release creation
  - Multi-platform binary packaging
  - Changelog generation
  - Asset verification and signing

## Workflow Organization Strategy

### **Fast Feedback Loop**
- **Quick CI**: Runs on every push/PR for rapid feedback
- **Build and Test**: More comprehensive testing for main releases

### **Quality Assurance**
- **Comprehensive Testing**: Weekly deep testing and validation
- **Static Analysis**: Integrated into Quick CI for code quality

### **Release Management**
- **Automated Releases**: Tag-triggered builds for consistent releases
- **Multi-platform Artifacts**: Ensures compatibility across all targets

## Historical Changes

### What Was Fixed:
1. **Removed Duplicate Workflow**: Deleted `ci-old.yml` which had the same name as `ci.yml`
2. **Clarified Naming**: Renamed `ci.yml` from "Build ACPIPatcher" to "Quick CI"
3. **Eliminated Confusion**: Each workflow now has a distinct, descriptive name

### Previous Issues:
- ❌ Two workflows named "Build ACPIPatcher" (confusing in GitHub UI)
- ❌ Obsolete `ci-old.yml` file causing duplication
- ❌ YAML syntax errors in heredoc sections

### Current State:
- ✅ Four distinct workflows with clear purposes
- ✅ Proper naming convention
- ✅ No duplicate workflow names
- ✅ All YAML syntax validated

## Workflow Triggers Summary

| Workflow | Push | PR | Tags | Schedule | Manual |
|----------|------|----|----- |----------|--------|
| Build and Test | ✅ main/develop | ✅ main | ✅ v* | ❌ | ✅ |
| Quick CI | ✅ main/develop | ✅ main | ❌ | ❌ | ✅ |
| Comprehensive | ❌ | ❌ | ❌ | ✅ Weekly | ✅ |
| Release | ❌ | ❌ | ✅ v* | ❌ | ❌ |

## Badge Status

All workflow badges are now properly configured in the README.md and will show accurate status for their respective workflows.
