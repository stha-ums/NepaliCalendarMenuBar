# Commit Message Convention

Quick reference for commit messages that trigger automatic releases.

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

| Type | Version Bump | Use For | Example |
|------|--------------|---------|---------|
| `feat` | MINOR | New features | `feat: add keyboard shortcuts` |
| `fix` | PATCH | Bug fixes | `fix: calendar crash on startup` |
| `ci` | NONE (rebuild) | CI/CD rebuilds | `ci: rebuild for deployment` |
| `feat!` | MAJOR | Breaking changes | `feat!: redesign settings API` |
| `docs` | NONE | Documentation | `docs: update README` |
| `style` | NONE | Code formatting | `style: format Swift code` |
| `refactor` | NONE | Code restructuring | `refactor: simplify date conversion` |
| `perf` | NONE | Performance improvements | `perf: optimize calendar rendering` |
| `test` | NONE | Tests | `test: add unit tests for converter` |
| `chore` | NONE | Maintenance | `chore: update dependencies` |

## Scope (Optional)

Specify what part of the app is affected:

```bash
feat(calendar): add week view
fix(ui): menu bar icon alignment
feat(settings): add theme selector
```

## Breaking Changes

Use `!` or `BREAKING CHANGE:` footer:

```bash
# Option 1: Exclamation mark
feat!: remove macOS 11 support

# Option 2: Footer
feat: update calendar API

BREAKING CHANGE: Calendar API now requires authentication
```

## Special: CI Rebuilds

Use `ci:` to rebuild and release the current version without bumping:

```bash
# Rebuild version 0.1.0 without changing version number
git commit -m "ci: rebuild for hotfix deployment"

# Creates:
# - Tag: v0.1.0-latest (or updates existing)
# - Release: "Latest Build (v0.1.0)" marked as pre-release
# - DMG: NepaliDateMacMenuBar-0.1.0-latest.dmg
# - No CHANGELOG.md update
# - No Info.plist version change
```

**When to use `ci:`:**
- Rebuild after fixing CI/CD issues
- Deploy same version to different environment
- Create new build without code changes
- Testing deployment pipeline

## Examples

### Features (Minor Bump)

```bash
# Simple feature
git commit -m "feat: add Nepali public holidays"

# Feature with scope
git commit -m "feat(calendar): add month/year picker"

# Feature with body
git commit -m "feat: add dark mode support

Implements system-wide dark mode support with automatic switching based on system preferences."
```

### Bug Fixes (Patch Bump)

```bash
# Simple fix
git commit -m "fix: date conversion for leap years"

# Fix with scope
git commit -m "fix(ui): menu bar icon size on Retina displays"

# Fix with issue reference
git commit -m "fix: prevent crash when calendar is empty

Fixes #42"
```

### Breaking Changes (Major Bump)

```bash
# Breaking change with !
git commit -m "feat!: redesign calendar view layout"

# Breaking change with footer
git commit -m "feat: update date API

BREAKING CHANGE: NepaliDate initializer now requires month parameter"
```

### No Version Bump

```bash
# Documentation
git commit -m "docs: add setup instructions"

# Code style
git commit -m "style: apply SwiftLint formatting"

# Refactoring
git commit -m "refactor: extract date formatter"

# Chores
git commit -m "chore: update Xcode version"

# Multiple changes
git commit -m "chore: prepare for v2.0.0 release

- Update dependencies
- Fix linting issues
- Update documentation"
```

## Multi-line Commits

```bash
git commit -m "feat: add event filtering

Users can now filter calendar events by:
- Calendar name
- Event type
- Date range

Closes #15"
```

## Reverting

```bash
git commit -m "revert: feat: add experimental feature

This reverts commit abc123def456.

Reason: Feature caused performance issues"
```

## Tips

1. **Keep subject line under 72 characters**
2. **Use imperative mood**: "add" not "added" or "adds"
3. **Don't capitalize first letter** after type
4. **No period at the end** of subject
5. **Reference issues** in body or footer: `Fixes #123`
6. **Explain why, not what** in the body

## Quick Commands

```bash
# Feature
git commit -m "feat: your feature description"

# Bug fix
git commit -m "fix: your fix description"

# Documentation
git commit -m "docs: your doc change"

# Breaking change
git commit -m "feat!: your breaking change"
```

## Checking Your Commits

View commits since last release:

```bash
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

Check what version bump will happen:

```bash
git log $(git describe --tags --abbrev=0)..HEAD --pretty=format:"%s" | grep -E "^feat:|^fix:|^feat!:"
```

## Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)

