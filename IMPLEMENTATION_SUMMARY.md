# Implementation Summary: Interactive Snapshotting

## Overview

This implementation adds interactive snapshotting functionality to the `resultcheck` package, enabling empirical researchers to track changes in their analysis outputs during interactive development and use those snapshots for automated testing.

## Key Features Implemented

### 1. Project Root Detection (`find_root()`)

- **Purpose**: Locate the project root directory to ensure snapshots are stored consistently
- **Implementation**: Uses `rprojroot` to search for markers in this order:
  1. `resultcheck.yml` configuration file
  2. `.Rproj` R project file  
  3. `.git` directory
- **Benefits**: Works regardless of user's current working directory

### 2. Interactive Snapshotting (`snapshot()`)

- **First Use**: Saves the R object to `_resultcheck_snapshots/{script_name}/{name}.rds`
- **Subsequent Uses**: 
  - Compares current object with saved snapshot using `waldo`
  - Shows human-readable differences
  - Prompts user to update if differences found (in interactive mode)
- **Organization**: Snapshots organized by script name for clarity
- **Supported Objects**: Any R object that can be saved with `saveRDS()` (data frames, models, lists, vectors, etc.)

### 3. Test Integration (`expect_snapshot_value()`)

- **Purpose**: Enable automated testing against snapshots
- **Integration**: Works seamlessly with `testthat`
- **Workflow**: 
  1. Create snapshots interactively during analysis
  2. Use `expect_snapshot_value()` in tests to verify outputs match snapshots
  3. Re-run interactively to review and update when needed

### 4. Snapshot File Organization

```
project_root/
  _resultcheck_snapshots/      # Gitignored by default
    script1/
      snapshot1.rds
      snapshot2.rds
    script2/
      snapshot3.rds
```

## Files Added/Modified

### New Files

1. **R/snapshot.R** - Core snapshot functionality:
   - `find_root()`: Project root detection
   - `get_snapshot_path()`: Snapshot file path management
   - `compare_snapshot_values()`: Difference detection using waldo
   - `snapshot()`: Interactive snapshot creation/comparison
   - `expect_snapshot_value()`: Testthat integration

2. **tests/testthat/test-snapshot.R** - Comprehensive test suite (27 tests):
   - Project root finding with different markers
   - Snapshot creation and matching
   - Difference detection
   - Multiple object types
   - File organization

3. **tests/testthat/test-integration.R** - Integration test showing combined sandbox + snapshot workflow

4. **examples_snapshots.R** - Demonstration of snapshot functionality

5. **resultcheck.yml.example** - Configuration file template

### Modified Files

1. **DESCRIPTION** - Added dependencies: `rprojroot`, `rlang`, `waldo`
2. **NAMESPACE** - Exported new functions
3. **README.md** - Added comprehensive documentation section
4. **.gitignore** - Added `_resultcheck_snapshots/` to prevent committing snapshots
5. **.Rbuildignore** - Added snapshot directory pattern

## Dependencies

- **rprojroot**: For project root detection
- **rlang**: For robust programming utilities
- **waldo**: For human-readable object comparisons
- **withr**: Already a dependency, used by sandbox functions

## Testing

- **Total Tests**: 67 tests (38 sandbox + 27 snapshot + 2 integration)
- **Status**: All passing ✓
- **Coverage**: 
  - Project root detection with all marker types
  - Snapshot creation, matching, and difference detection
  - Different object types (data frames, models, lists, vectors)
  - Organization by script name
  - Testthat integration
  - Combined sandbox + snapshot workflow

## Usage Examples

### Interactive Analysis

```r
library(resultcheck)

# Your analysis
model <- lm(mpg ~ wt + hp, data = mtcars)

# Save snapshot (first time)
snapshot(model, "my_regression")
# Message: New snapshot saved: analysis/my_regression.rds

# Later, if model changes
model <- lm(mpg ~ wt + hp + cyl, data = mtcars)
snapshot(model, "my_regression")
# Shows differences and prompts: Update snapshot? (y/n):
```

### Automated Testing

```r
library(testthat)
library(resultcheck)

test_that("regression model is stable", {
  # Setup sandbox
  sandbox <- setup_sandbox(c("data/mydata.rds"))
  
  # Run analysis
  run_in_sandbox("analysis.R", sandbox)
  
  # Load result from sandbox
  model <- readRDS(file.path(sandbox$path, "model.rds"))
  
  # Compare against snapshot
  expect_snapshot_value(model, "my_regression", script_name = "analysis")
  
  # Cleanup
  cleanup_sandbox(sandbox)
})
```

## Design Decisions

1. **RDS Format**: Snapshots saved as `.rds` files for:
   - Efficient storage
   - Exact reproduction of R objects
   - Support for any serializable object

2. **Waldo for Comparisons**: Provides human-readable diffs similar to testthat

3. **Organization by Script**: Prevents naming conflicts and improves clarity

4. **Gitignore by Default**: Snapshots are working files, not source code
   - Users can choose to commit if desired
   - Recommended for teams: commit snapshots to ensure consistency

5. **Interactive Prompting**: Controlled by `interactive` parameter:
   - Default TRUE for interactive sessions
   - Set FALSE for automated contexts

## Security

- No security vulnerabilities detected by CodeQL
- Uses standard R file I/O operations
- Project root detection limited to upward directory traversal only

## Future Enhancements (Not Implemented)

Possible future additions could include:
- Support for visual snapshots (plots) via `vdiffr`
- Configuration options via `resultcheck.yml`
- Automatic snapshot discovery for sandbox copying
- Custom comparison functions for specific object types

## Conclusion

This implementation successfully addresses the requirements in the issue:

✓ Interactive snapshotting for empirical researchers
✓ Human-readable snapshots with difference detection  
✓ Integration with testthat for automated testing
✓ Project root detection without relying on working directory
✓ Organized snapshot file structure
✓ Comprehensive documentation and examples

The functionality is production-ready and all tests pass successfully.
