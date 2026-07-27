# GabiFlow Mobile - Task Completion Checklist

## When Completing a Development Task

### 1. Code Generation (if models/providers were modified)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Code Formatting
```bash
dart format .
```

### 3. Static Analysis
```bash
flutter analyze
```
- Fix any errors or warnings before proceeding
- TODO comments are ignored but should be addressed

### 4. Run Tests
```bash
flutter test
```
- Ensure all existing tests pass
- Add tests for new functionality

### 5. Manual Testing
- Run the app and test the implemented feature
- Test on both iOS and Android if possible
- Check different screen sizes
- Test offline mode if applicable

### 6. Check for Breaking Changes
- Verify no existing functionality is broken
- Test related features that might be affected

### 7. Update Documentation
- Update code comments if needed
- Update README if adding new features
- Document any new environment variables

### 8. Clean Up
- Remove debug print statements
- Remove commented-out code
- Check for proper error handling

### 9. Performance Check
- Ensure smooth animations (60fps)
- Check memory usage in DevTools
- Verify no unnecessary rebuilds

### 10. Security Review
- No hardcoded secrets or API keys
- Sensitive data uses SecureStorage
- API calls include proper authentication

## Pre-Commit Checklist
- [ ] Code is formatted (`dart format .`)
- [ ] Static analysis passes (`flutter analyze`)
- [ ] Tests pass (`flutter test`)
- [ ] No debug print statements
- [ ] Generated files are up to date
- [ ] App runs without errors
- [ ] Feature works as expected
- [ ] No regression in existing features

## Important Reminders
- **NEVER** modify the backend at `/Users/iremarlopes/Desktop/gabiflow-local`
- **NEVER** alter database schemas directly
- **ALWAYS** use existing backend APIs
- **ALWAYS** include tenant_id in API requests
- **ALWAYS** handle offline scenarios gracefully
- **ALWAYS** test multi-tenant isolation