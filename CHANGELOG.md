### 0.4.0 (2020-Oct-27)
 * Added Chile region
 * Upgraded Dojo image to fix issues with new Mac FUSE docker volume driver

### 0.3.1 (2020-Jul-02)
* Looks like an untracked change was pushed to the release
* It's not needed, bumping up the version


### 0.3.0 (2020-Apr-27)

* Add support for multiple regions
* Adopt in Germany
* Make randomize functionality available to candidates
* `candidate_prep` does not build a zip archive anymore
* `prepare_candidate_zip` builds the zip archive if needed
* Always release a `latest` release linked to latest version

### 0.2.0 (2020-Mar-26)

 * Introduced a temporary user per each interview, named `interview-<interview_id>`
 * Updated Dojofile to include zip, vim in the docker image
 * Refactored scripts to central `recops.sh`
 * Cleanup of unused files
 * Minor improvements in readme

### 0.1.0 (2020-Feb-09)

Initial `beta` release.
