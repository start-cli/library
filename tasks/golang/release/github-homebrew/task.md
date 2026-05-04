# Go Project Release Process (GitHub + Homebrew Tap)

Release a Go project to GitHub with Homebrew tap distribution. Execute each step in order.

## Prerequisites

Confirm these values with the user before starting:

- PROJECT_REPO: GitHub repository (e.g., `username/project`)
- TAP_REPO: Homebrew tap repository (e.g., `username/homebrew-tap`)
- BINARY_NAME: Name of the compiled binary

Requirements:

- Write access to both repositories
- Go 1.21+ installed
- Git configured with proper credentials
- GitHub CLI (`gh`) installed and authenticated
- All planned features/fixes merged to main branch

## Release Process

Steps:

1. Pre-release review
2. Run pre-release validation
3. Determine version number
4. Update CHANGELOG.md
5. Commit changes
6. Create and push git tag
7. Create GitHub Release
8. Update Homebrew tap
9. Verify installation
10. Clean up

## Step 1: Pre-Release Review

Perform a brief holistic review of the codebase before release. This is a quick glance to identify obvious issues, not a full code review.

Review the following:

1. Active project status - Check for any active work-in-progress. Verify all planned changes are complete and ready for release.

2. Recent changes - Review commits since the last release tag. Look for:
   - Incomplete work (TODO, FIXME, XXX comments in changed files)
   - Obvious errors or missing error handling
   - Changes that lack corresponding tests

3. Documentation currency - Quick check that:
   - `README.md` reflects current functionality
   - Command help text matches implementation (`BINARY_NAME --help`)
   - `AGENTS.md` is accurate

4. Code cleanliness - Scan `internal/` for:
   - Dead code or commented-out blocks
   - Debug statements (fmt.Println, log.Println not part of normal output)
   - Hardcoded values that should be configurable

Commands to assist review:

```bash
# Find TODOs/FIXMEs in Go files
rg -i "TODO|FIXME|XXX" --type go

# Show commits since last release
PREV_VERSION=$(git describe --tags --abbrev=0 origin/main)
git log ${PREV_VERSION}..HEAD --oneline

# List recently modified Go files
git diff --name-only ${PREV_VERSION}..HEAD -- "*.go"
```

Decision: Report GO if no blocking issues found, or NO-GO with specific concerns that must be addressed before release.

## Step 2: Pre-Release Validation

Run validation checks:

```bash
# Ensure on main branch with latest changes
# Do this for both the code repository and the homebrew-tap repository
git checkout main
git pull origin main

# Check required tools are installed
for cmd in golangci-lint ineffassign gocyclo; do
  command -v "$cmd" &>/dev/null || echo "WARNING: $cmd not found - install before proceeding"
done

# Check formatting (should produce no output)
gofmt -l .

# Run linters
go vet ./...
golangci-lint run
ineffassign ./...

# Check cyclomatic complexity (functions over 15)
gocyclo -over 15 .

# Verify all tests pass
go test -v ./...

# Verify build works
go build -o BINARY_NAME
./BINARY_NAME --version
rm BINARY_NAME

# Verify clean working directory
git status
```

Expected results:

- `gofmt -l .` produces no output (all files formatted)
- `go vet ./...` reports no issues
- `golangci-lint run` reports no errors (warnings acceptable)
- `ineffassign ./...` reports no issues
- `gocyclo -over 15 .` reports no functions (or acceptable exceptions)
- All tests pass
- Build completes without errors
- `BINARY_NAME --version` shows current version
- `git status` shows clean working tree

Linter installation (if not already installed):

```bash
# golangci-lint (comprehensive linter)
brew install golangci-lint
# or: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Individual linters
go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
go install github.com/gordonklaus/ineffassign@latest
```

If any validation fails, stop and fix issues before proceeding. After fixing, commit and push all changes to main. The working tree must be clean before moving to the next step.

## Step 3: Determine Version Number

Set the version number using [Semantic Versioning](https://semver.org/):

- MAJOR: Breaking API changes (1.0.0 → 2.0.0)
- MINOR: New features, backward compatible (1.0.0 → 1.1.0)
- PATCH: Bug fixes only (1.0.0 → 1.0.1)

```bash
# Check current version and capture for reuse in later steps
export PREV_VERSION=$(git describe --tags --abbrev=0 origin/main 2>/dev/null || echo "")
echo "Current version: ${PREV_VERSION:-none}"

# Set new version (example: v1.0.0)
export VERSION="1.0.0"
echo "Releasing version: v${VERSION}"
```

## Step 4: Update CHANGELOG.md

Note: Skip this step for v0 releases.

Review changes since last release and update CHANGELOG.md:

```bash
# Show changes since previous version (or all commits if first release)
if [ -z "$PREV_VERSION" ]; then
  echo "First release - showing all commits:"
  git log --oneline
else
  echo "Changes since ${PREV_VERSION}:"
  git log ${PREV_VERSION}..HEAD --oneline
fi

# Review the changes and categorize them
# Then edit CHANGELOG.md manually
```

Update CHANGELOG.md by adding a new version section with:

- Added: New features
- Changed: Changes to existing functionality
- Fixed: Bug fixes
- Deprecated: Features marked for removal
- Removed: Removed features
- Security: Security fixes

Example format:

```markdown
## [1.0.0] - 2026-01-09

### Added

- Initial release with core functionality
- Feature description here

[Unreleased]: https://github.com/PROJECT_REPO/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/PROJECT_REPO/releases/tag/v1.0.0
```

## Step 5: Commit Changes

Commit the CHANGELOG:

```bash
# Stage and commit changes
git add CHANGELOG.md
git commit -m "chore: prepare for v${VERSION} release"
git push origin main
```

## Step 6: Create and Push Git Tag

Create an annotated git tag:

```bash
# Review changes using PREV_VERSION from Step 3
if [ -z "$PREV_VERSION" ]; then
  git log --oneline | head -10
else
  git log ${PREV_VERSION}..HEAD --oneline
fi

# Create one-line summary from the changes above
# Examples: "Initial release", "Add markdown conversion", "Fix API authentication"
SUMMARY="Your one-line summary here"

# Create and push annotated tag
git tag -a "v${VERSION}" -m "Release v${VERSION} - ${SUMMARY}"
git push origin "v${VERSION}"

# Verify tag exists
git tag -l -n9 "v${VERSION}"
```

## Step 7: Create GitHub Release

Note: Ensure the release notes are human readable, not just a list of commits.

Create the GitHub Release with release notes:

```bash
# Get tarball SHA256 for Homebrew (will use in Step 8)
TARBALL_URL="https://github.com/${PROJECT_REPO}/archive/refs/tags/v${VERSION}.tar.gz"
if command -v shasum &>/dev/null; then
  TARBALL_SHA256=$(curl -sL "$TARBALL_URL" | shasum -a 256 | cut -d' ' -f1)
else
  TARBALL_SHA256=$(curl -sL "$TARBALL_URL" | sha256sum | cut -d' ' -f1)
fi
echo "Tarball SHA256: $TARBALL_SHA256"

# Review commits to write release notes (using PREV_VERSION from Step 3)
if [ -n "$PREV_VERSION" ]; then
  git log ${PREV_VERSION}..v${VERSION} --oneline
else
  git log --oneline | head -20
fi

# Create GitHub Release using gh CLI
# Write human-readable release notes categorised under headings like:
# New Commands, Features, Improvements, Fixes
gh release create "v${VERSION}" \
  --title "Release v${VERSION}" \
  --notes "REPLACE_WITH_HUMAN_READABLE_NOTES"

# Verify release was created
gh release view "v${VERSION}"
```

Note: GitHub automatically attaches source archives (tar.gz, zip) to releases. Homebrew builds from the tar.gz archive.

## Step 8: Update Homebrew Tap

Update the Homebrew formula with the new version:

```bash
# Navigate to local clone of TAP_REPO
cd <tap-repo-directory>
git pull origin main

# Display tarball info from Step 7
echo "Tarball URL: $TARBALL_URL"
echo "Tarball SHA256: $TARBALL_SHA256"

# Edit Formula/BINARY_NAME.rb following the existing format:
# Update url, sha256, ldflags, test block, and any other version-specific fields

# After editing, commit and push
git add Formula/BINARY_NAME.rb
git commit -m "BINARY_NAME: update to ${VERSION}"
git push origin main

# Return to project directory
cd -
```

Formula example (Formula/BINARY_NAME.rb):

```ruby
class BinaryName < Formula
  desc "Project description"
  homepage "https://github.com/PROJECT_REPO"
  url "https://github.com/PROJECT_REPO/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "abc123..."  # Use TARBALL_SHA256 value
  license "MPL-2.0"

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    system "go", "build", *std_go_args(ldflags: "-X main.version=1.0.0", output: bin/"BINARY_NAME")
  end

  test do
    assert_match "1.0.0", shell_output("#{bin}/BINARY_NAME --version")
  end
end
```

## Step 9: Verify Installation

Test the Homebrew installation:

```bash
# Update and reinstall
brew update
brew reinstall <tap-user>/tap/BINARY_NAME

# Verify version
BINARY_NAME --version  # Should show new version

# Test basic functionality
BINARY_NAME <simple-command>  # Run a simple command to verify
```

Expected results:

- `BINARY_NAME --version` displays new version
- No errors during installation

If installation fails, debug with:

```bash
brew audit --strict <tap-user>/tap/BINARY_NAME
brew install --verbose <tap-user>/tap/BINARY_NAME
```

## Step 10: Clean Up

Complete the release:

```bash
# Verify release is live
gh release view "v${VERSION}"

# Check Homebrew tap was updated
cd <tap-repo-directory>
git log -1
cd -

# Verify clean state
git status
```

Release is complete!

Monitor for issues:

- Watch GitHub issues for bug reports
- Monitor Homebrew installation feedback
- Be ready to release a patch if critical issues arise

## Rollback Procedure

If critical issues are discovered after release:

Option 1: Patch Release (Recommended)

```bash
# Fix the issue, then release patch version (e.g., v1.0.1)
# Follow the standard release process
```

Option 2: Delete Release (Last resort - use only for critical security issues)

```bash
# Delete GitHub release
gh release delete "v${VERSION}" --yes

# Delete tags
git push origin --delete "v${VERSION}"
git tag -d "v${VERSION}"

# Revert Homebrew tap
cd <tap-repo-directory>
git revert HEAD
git push origin main
cd -
```

## Quick Reference

One-command release workflow:

```bash
# Set version
export VERSION="1.0.0"

# Get previous version for change summary
PREV_VERSION=$(git describe --tags --abbrev=0 origin/main)

# 1. Pre-release review (see Step 1 for details)
rg -i "TODO|FIXME|XXX" --type go  # Should be empty or acceptable

# 2. Validation
go test -v ./...
golangci-lint run
git status  # Should be clean

# 3. Update CHANGELOG.md (skip for v0 releases), then commit
git add CHANGELOG.md
git commit -m "chore: prepare for v${VERSION} release"
git push origin main

# 4. Create tag with summary
SUMMARY="Your summary here"
git tag -a "v${VERSION}" -m "Release v${VERSION} - ${SUMMARY}"
git push origin "v${VERSION}"

# 5. Create GitHub Release (write human-readable notes, not raw commits)
git log ${PREV_VERSION}..v${VERSION} --oneline  # Review commits for context
gh release create "v${VERSION}" --title "Release v${VERSION}" \
  --notes "REPLACE_WITH_HUMAN_READABLE_NOTES"

# 6. Get tarball SHA256
if command -v shasum &>/dev/null; then
  TARBALL_SHA256=$(curl -sL "https://github.com/${PROJECT_REPO}/archive/refs/tags/v${VERSION}.tar.gz" | shasum -a 256 | cut -d' ' -f1)
else
  TARBALL_SHA256=$(curl -sL "https://github.com/${PROJECT_REPO}/archive/refs/tags/v${VERSION}.tar.gz" | sha256sum | cut -d' ' -f1)
fi
echo "SHA256: $TARBALL_SHA256"

# 7. Update Homebrew (edit Formula/BINARY_NAME.rb with VERSION and SHA256)
cd <tap-repo-directory>
# Edit Formula/BINARY_NAME.rb
git add Formula/BINARY_NAME.rb
git commit -m "BINARY_NAME: update to ${VERSION}"
git push origin main
cd -

# 8. Test
brew update && brew reinstall <tap-user>/tap/BINARY_NAME
BINARY_NAME --version
```

## Troubleshooting

Tests failing

- Run: `go test -v ./...` to see detailed output
- Fix all failures before proceeding
- Never release with failing tests

Tarball not available

- Wait 1-2 minutes after pushing tag
- Verify tag exists: `git ls-remote --tags origin | grep v${VERSION}`
- Check: https://github.com/PROJECT_REPO/tags

Homebrew formula issues

- Audit: `brew audit --strict <tap-user>/tap/BINARY_NAME`
- Common: Incorrect SHA256, wrong URL format, Ruby syntax
- Fix and push updated formula

Installation fails

- Verbose output: `brew install --verbose <tap-user>/tap/BINARY_NAME`
- View formula: `brew cat <tap-user>/tap/BINARY_NAME`
- Verify tarball: `curl -I https://github.com/${PROJECT_REPO}/archive/refs/tags/v${VERSION}.tar.gz`
