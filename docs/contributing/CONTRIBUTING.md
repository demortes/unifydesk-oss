# Contributing to UnifyDesk

Thank you for your interest in contributing to UnifyDesk! This guide will help you get started.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

### Our Standards
- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report:
1. Check the [existing issues](https://github.com/Demortes/unifydesk/issues)
2. Use the latest version to verify the bug still exists
3. Collect information about the bug

When reporting a bug, use the bug report template and include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Environment details (OS, device, version)

**Important**: Never include sensitive information (passwords, emails, personal data) in bug reports.

### Suggesting Features

Feature suggestions are welcome! Before suggesting:
1. Check if it's already been suggested
2. Consider if it aligns with project goals
3. Think about implementation complexity

Use the feature request template and include:
- Clear description of the feature
- Problem it solves
- Proposed solution
- Use cases
- Platform relevance

### Code Contributions

#### First Time Contributors

Look for issues labeled:
- `good-first-issue`: Suitable for newcomers
- `help-wanted`: We need help with these
- `documentation`: Documentation improvements

#### Development Process

1. **Fork the Repository**
```bash
# Fork on GitHub, then clone your fork
git clone https://github.com/Demortes/unifydesk.git
cd unifydesk
```

2. **Create a Branch**
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

Branch naming conventions:
- `feature/`: New features
- `fix/`: Bug fixes
- `docs/`: Documentation changes
- `refactor/`: Code refactoring
- `test/`: Test additions/changes

3. **Make Your Changes**

Follow our coding standards (see below).

4. **Test Your Changes**
```bash
# Run tests
flutter test

# Check formatting
dart format .

# Run analyzer
flutter analyze

# Test on target platforms
flutter run -d <device>
```

5. **Commit Your Changes**

Write clear, meaningful commit messages:
```bash
git commit -m "feat: add unified inbox filter"
git commit -m "fix: resolve calendar sync issue"
git commit -m "docs: update setup instructions"
```

Commit message format:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Code style/formatting
- `refactor:` Code refactoring
- `test:` Tests
- `chore:` Build/config changes

6. **Push and Create Pull Request**
```bash
git push origin feature/your-feature-name
```

Create a pull request on GitHub using the PR template.

## Coding Standards

### Dart/Flutter Style

Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style).

Key points:
- Use `dartfmt` / `dart format` for formatting
- Line length: 100 characters
- Use trailing commas for better formatting
- Prefer `const` constructors where possible
- Use meaningful variable and function names

### Code Organization

#### File Naming
- Use lowercase with underscores: `email_repository.dart`
- Test files: `email_repository_test.dart`
- Models: `email_model.dart`

#### Class Naming
- Classes: `PascalCase` (e.g., `EmailRepository`)
- Private classes: `_PascalCase` (e.g., `_EmailCache`)

#### Variable Naming
- Variables: `camelCase` (e.g., `emailAddress`)
- Constants: `camelCase` with `const` or `final` (e.g., `const apiVersion = '1.0'`)
- Private: `_camelCase` (e.g., `_privateMethod`)

### Architecture Guidelines

Follow Clean Architecture principles:

1. **Separation of Concerns**: Keep layers separate
2. **Dependency Rule**: Inner layers don't depend on outer layers
3. **Domain First**: Start with domain entities and use cases
4. **Repository Pattern**: Abstract data sources

Example structure:
```dart
// Domain Entity (pure Dart)
class Email {
  final String id;
  final String subject;
  final String from;
  // ...
}

// Use Case
class GetEmailsUseCase {
  final MailRepository repository;

  Future<List<Email>> call(String mailboxId) {
    return repository.getEmails(mailboxId);
  }
}

// Repository Interface (domain)
abstract class MailRepository {
  Future<List<Email>> getEmails(String mailboxId);
}

// Repository Implementation (data)
class MailRepositoryImpl implements MailRepository {
  final ImapDataSource remoteDataSource;
  final LocalMailDataSource localDataSource;

  @override
  Future<List<Email>> getEmails(String mailboxId) {
    // Implementation
  }
}
```

### Testing Guidelines

#### Unit Tests
- Test business logic in isolation
- Use mocks for dependencies
- Aim for 90%+ coverage on domain layer

```dart
void main() {
  group('GetEmailsUseCase', () {
    late GetEmailsUseCase useCase;
    late MockMailRepository mockRepository;

    setUp(() {
      mockRepository = MockMailRepository();
      useCase = GetEmailsUseCase(mockRepository);
    });

    test('should return list of emails from repository', () async {
      // Arrange
      when(mockRepository.getEmails(any))
          .thenAnswer((_) async => [testEmail]);

      // Act
      final result = await useCase('inbox');

      // Assert
      expect(result, [testEmail]);
      verify(mockRepository.getEmails('inbox'));
    });
  });
}
```

#### Widget Tests
- Test UI components
- Test user interactions
- Verify widget behavior

```dart
void main() {
  testWidgets('EmailListItem displays email info', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EmailListItem(email: testEmail),
      ),
    );

    expect(find.text(testEmail.subject), findsOneWidget);
    expect(find.text(testEmail.from), findsOneWidget);
  });
}
```

#### Integration Tests
- Test end-to-end flows
- Use mock servers for network calls
- Test on real devices when possible

### Documentation

#### Code Comments
- Use `///` for public API documentation
- Use `//` for implementation notes
- Don't state the obvious
- Explain *why*, not *what*

```dart
/// Fetches emails from the specified mailbox.
///
/// Returns a list of [Email] objects. Throws [NetworkException]
/// if the connection fails.
///
/// The emails are cached locally for offline access.
Future<List<Email>> getEmails(String mailboxId);
```

#### README Files
- Each feature should have a README in `docs/features/`
- Update docs when changing architecture
- Include code examples for complex features

### Security Guidelines

#### Sensitive Data
- Never log passwords or tokens
- Use secure storage for credentials
- Encrypt sensitive local data

```dart
// ❌ BAD
print('Password: $password');

// ✅ GOOD
logger.debug('Authentication attempt for user: $username');
```

#### Network Security
- Always use HTTPS/TLS
- Validate certificates
- Implement timeout mechanisms

#### Input Validation
- Validate all user input
- Sanitize data before storage
- Prevent injection attacks

### Performance Guidelines

1. **Avoid Unnecessary Rebuilds**
```dart
// Use const constructors
const Text('Hello');

// Use keys for list items
ListView.builder(
  itemBuilder: (context, index) => EmailListItem(
    key: ValueKey(emails[index].id),
    email: emails[index],
  ),
);
```

2. **Efficient State Management**
- Use appropriate state management solution
- Minimize state scope
- Dispose controllers and streams

3. **Optimize Network Calls**
- Implement pagination
- Cache appropriately
- Use background sync

4. **Database Optimization**
- Use indices for frequently queried fields
- Batch operations when possible
- Implement proper cleanup

## Pull Request Process

### Before Submitting

Checklist:
- [ ] Code follows project style guidelines
- [ ] Self-reviewed code
- [ ] Commented complex code sections
- [ ] Updated documentation
- [ ] Added/updated tests
- [ ] All tests pass locally
- [ ] No new warnings introduced
- [ ] Privacy and security considerations addressed

### PR Description

Use the PR template and provide:
- Clear description of changes
- Related issue number
- Type of change (bug fix, feature, etc.)
- Testing done
- Screenshots (for UI changes)
- Privacy/security notes

### Review Process

1. **Automated Checks**: CI must pass
2. **Code Review**: At least one maintainer approval required
3. **Testing**: Reviewer may test manually
4. **Discussion**: Address feedback promptly
5. **Merge**: Maintainer will merge when approved

### After Merge

- Your branch will be deleted
- Changes will be in the next release
- You'll be added to contributors list

## Feature Development Workflow

### 1. Planning Phase
- Open an issue to discuss the feature
- Get feedback from maintainers
- Agree on approach and scope

### 2. Implementation Phase
- Create feature branch
- Implement domain layer first
- Add data layer
- Build UI layer
- Write tests for each layer

### 3. Testing Phase
- Unit tests
- Widget tests
- Integration tests
- Manual testing on multiple platforms

### 4. Documentation Phase
- Update relevant docs
- Add code documentation
- Update README if needed
- Consider adding examples

### 5. Review Phase
- Create pull request
- Address review comments
- Update based on feedback

## Platform-Specific Contributions

### Android/iOS
- Test on both phones and tablets
- Consider foldable devices
- Test different OS versions

### Desktop
- Test on Windows, macOS, and Linux
- Consider window resizing behavior
- Test keyboard shortcuts

### Adaptive UI
- Ensure responsive design
- Test different screen sizes
- Verify layout on all form factors

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Stuck**: Comment on your issue/PR
- **Chat**: Join our Discord/Slack (if available)

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Credited in release notes
- Mentioned in relevant documentation

Thank you for contributing to UnifyDesk! 🎉
