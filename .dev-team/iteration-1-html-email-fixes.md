# Iteration 1: HTML Email Display Debugging & Fixes

## Issues Identified

### 1. Unstable Dependencies
- Using `flutter_html: ^3.0.0-beta.2` (beta version)
- Need to downgrade to stable version: `^2.2.1`

### 2. HTML Cleaning Too Aggressive
- `_cleanEmailHtml()` might be removing valid content
- Need debug logging to see what's being stripped

### 3. Error Handling Gaps
- HTML rendering failures not always caught
- Need better fallback mechanisms

## Fix Plan

### Phase 1: Dependency Fixes
1. Downgrade flutter_html to stable version
2. Test compatibility with existing code
3. Update styling syntax if needed

### Phase 2: Debug HTML Cleaning
1. Add comprehensive logging to _cleanEmailHtml
2. Create test cases with problematic emails
3. Make cleaning less aggressive

### Phase 3: Improve Error Handling
1. Better try-catch around Html widget
2. Improved fallback to plain text
3. User-friendly error messages

## Acceptance Criteria
- HTML emails render properly without crashes
- Fallback to plain text works reliably 
- Clear debugging information available
- No breaking changes to existing functionality