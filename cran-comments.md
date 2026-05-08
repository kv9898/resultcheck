## R CMD check results

0 errors | 0 warnings | 0 notes

## Release summary

This is a patch release (0.2.0 → 0.2.1) that fixes a bug in script name detection.

## Key changes since 0.2.0

* Fixed a bug in `detect_script_name()` where the script name was not correctly detected in certain calling contexts, causing snapshot files to be written to the wrong location.
