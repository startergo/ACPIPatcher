# Workflow Triggers Update Summary

## Changes Made

All GitHub Actions workflow files have been updated to remove automatic triggers (push and pull request) and only allow manual execution via `workflow_dispatch`.

### Updated Files:

1. **`.github/workflows/stuart-build.yml`**
   - Removed: `push` and `pull_request` triggers
   - Kept: `workflow_dispatch` (manual trigger only)

2. **`.github/workflows/ci.yml`**
   - Removed: `push` and `pull_request` triggers
   - Kept: `workflow_dispatch` (manual trigger only)

3. **`.github/workflows/comprehensive-test.yml`**
   - Removed: `push`, `pull_request`, and `schedule` triggers
   - Kept: `workflow_dispatch` with inputs (manual trigger only)

4. **`.github/workflows/build-and-test.yml`**
   - Removed: `push` and `pull_request` triggers
   - Kept: `workflow_dispatch` with inputs (manual trigger only)

5. **`.github/workflows/stuart-comprehensive.yml`**
   - Removed: `push` and `pull_request` triggers
   - Kept: `workflow_dispatch` (manual trigger only)

### Unchanged Files:

1. **`.github/workflows/test-msys2-action.yml`**
   - Already had only `workflow_dispatch` trigger

2. **`.github/workflows/release.yml`**
   - Kept: `release` trigger (appropriate for release workflow)
   - Kept: `workflow_dispatch` (for manual releases)

## Impact

### Before:
- Workflows triggered automatically on push to master/develop branches
- Workflows triggered automatically on pull requests to master
- Some workflows had scheduled triggers (nightly builds)

### After:
- All workflows must be triggered manually via GitHub Actions UI
- No automatic builds on code changes
- Release workflow still triggers on GitHub releases (appropriate)

## How to Run Workflows

With these changes, all workflows must be triggered manually:

1. Go to your GitHub repository
2. Navigate to the "Actions" tab
3. Select the workflow you want to run
4. Click "Run workflow" button
5. Fill in any required inputs (if applicable)
6. Click "Run workflow" to execute

## Benefits

- **Cost Control**: No automatic builds consuming GitHub Actions minutes
- **Resource Management**: Builds only run when explicitly needed
- **Testing Control**: Developers can choose when to run comprehensive tests
- **Workflow Isolation**: Each workflow can be run independently

## Workflow Purposes

- **`stuart-build.yml`**: Main Stuart-based build system (VS2022 + GCC5)
- **`ci.yml`**: Quick CI checks and basic builds
- **`comprehensive-test.yml`**: Extensive testing across multiple configurations
- **`build-and-test.yml`**: Comprehensive build and test pipeline
- **`stuart-comprehensive.yml`**: Alternative comprehensive Stuart build
- **`test-msys2-action.yml`**: MSYS2 action testing
- **`release.yml`**: Release artifact management (still auto-triggers on releases)

All workflows remain fully functional and can be executed manually when needed.
