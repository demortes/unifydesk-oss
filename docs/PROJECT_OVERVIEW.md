# UnifyDesk Project Overview

## Quick Start

This document provides a quick overview of the UnifyDesk project structure and how to get started.

## What is UnifyDesk?

UnifyDesk is a privacy-focused, cross-platform communications application that unifies email, calendar, and contacts management across all your devices. Built with Flutter, it supports:

- **Platforms**: Android (phone/tablet/foldable), Windows
- **Features**: Mail with unified inbox, calendar with CalDAV sync, contacts with CardDAV sync
- **Privacy**: Client-side only, no tracking, encrypted storage, no ads

## Project Structure Overview

```
unifydesk/
├── .github/           # GitHub templates and workflows
├── assets/            # Application assets (images, icons, fonts)
├── docs/              # Documentation
├── integration_test/  # Integration tests
├── lib/               # Application source code
│   ├── core/          # Core functionality (network, security, storage)
│   ├── features/      # Feature modules (mail, calendar, contacts)
│   └── shared/        # Shared UI components
├── test/              # Unit and widget tests
└── [platform]/        # Platform-specific code (android, windows)
```

## Key Documentation

1. **[README.md](../README.md)** - Main project documentation
2. **[Architecture](architecture/README.md)** - Clean architecture overview
3. **[Folder Structure](FOLDER_STRUCTURE.md)** - Detailed folder structure
4. **[Setup Guide](setup/README.md)** - Installation and development setup
5. **[Contributing](contributing/CONTRIBUTING.md)** - How to contribute
6. **[Privacy & Security](privacy/README.md)** - Privacy policy and security details
7. **[Security Policy](../SECURITY.md)** - Vulnerability reporting

## Feature Documentation

- **[Mail Feature](features/mail/README.md)** - Email client implementation
- **[Calendar Feature](features/calendar/README.md)** - Calendar management
- **[Contacts Feature](features/contacts/README.md)** - Contact management

## Getting Started

### Prerequisites

- Flutter SDK 3.19.0+
- Dart SDK 3.3.0+
- Platform-specific tools (see [Setup Guide](setup/README.md))

### Installation

```bash
# Clone the repository
git clone https://github.com/Demortes/unifydesk.git
cd unifydesk

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Development Workflow

1. **Read the Documentation**
   - Start with [Architecture](architecture/README.md)
   - Understand [Folder Structure](FOLDER_STRUCTURE.md)
   - Review [Contributing Guidelines](contributing/CONTRIBUTING.md)

2. **Choose a Feature**
   - Check GitHub Issues for tasks
   - Read the feature documentation
   - Understand the domain first

3. **Implement**
   - Follow Clean Architecture principles
   - Write tests alongside code
   - Follow coding standards

4. **Test**
   - Unit tests: `flutter test`
   - Integration tests: `flutter test integration_test`
   - Manual testing on target platforms

5. **Submit**
   - Create a pull request
   - Fill out the PR template
   - Address review feedback

## Architecture Principles

UnifyDesk follows **Clean Architecture** with clear separation of concerns:

```
Presentation Layer (UI)
        ↓
    Use Cases (Business Logic)
        ↓
Repository Interface (Contract)
        ↓
Repository Implementation
        ↓
    Data Sources (Network/Local)
```

### Layer Responsibilities

- **Presentation**: UI components, user interaction, state management
- **Domain**: Business logic, entities, use cases, repository interfaces
- **Data**: Data access, API calls, local storage, repository implementations

### Key Principles

1. ✅ **Dependency Rule**: Inner layers never depend on outer layers
2. ✅ **Separation**: Each feature is independent
3. ✅ **Testability**: Easy to test each layer in isolation
4. ✅ **Maintainability**: Clear structure and boundaries
5. ✅ **Scalability**: Easy to add new features

## Technology Stack

### Core

- **Flutter**: UI framework
- **Dart**: Programming language
- **Riverpod**: State management

### Mail

- **IMAP/SMTP**: Email protocols
- **OAuth 2.0**: Authentication

### Calendar

- **CalDAV**: Calendar sync protocol
- **iCalendar**: Event format (RFC 5545)

### Contacts

- **CardDAV**: Contact sync protocol
- **vCard**: Contact format (RFC 6350)

### Storage

- **SQLite**: Local database
- **Secure Storage**: Encrypted credential storage
- **Shared Preferences**: App settings

### Security

- **TLS/SSL**: Encrypted communication
- **AES-256**: Local data encryption
- **OAuth 2.0 + PKCE**: Secure authentication

## Development Guidelines

### Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for formatting
- Run `flutter analyze` before committing
- Write meaningful variable and function names
- Add comments for complex logic only

### Testing

- **Unit tests**: Test business logic in isolation
- **Widget tests**: Test UI components
- **Integration tests**: Test end-to-end flows
- **Target**: 90%+ code coverage on domain layer

### Git Workflow

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes with clear commits
3. Push and create PR
4. Address review feedback
5. Merge after approval

### Commit Messages

```
feat: add unified inbox filter
fix: resolve calendar sync issue
docs: update setup instructions
test: add mail repository tests
refactor: extract common email logic
```

## Common Tasks

### Adding a New Feature

1. Create feature folder: `lib/features/new_feature/`
2. Create layers: `domain/`, `data/`, `presentation/`
3. Implement domain layer first (entities, use cases)
4. Implement data layer (models, repositories)
5. Implement presentation layer (UI)
6. Add tests for each layer
7. Add documentation

### Adding a New Screen

1. Create page in `lib/features/[feature]/presentation/pages/`
2. Create necessary widgets in `presentation/widgets/`
3. Add navigation route
4. Add state management provider
5. Write widget tests

### Adding a New API Integration

1. Create data source in `lib/features/[feature]/data/datasources/remote/`
2. Implement repository method
3. Create/update use case
4. Update presentation layer
5. Add unit tests

## Troubleshooting

### Common Issues

**Flutter not found**

```bash
export PATH="$PATH:/path/to/flutter/bin"
```

**Dependency conflicts**

```bash
flutter clean
flutter pub get
```

**Android build fails**

- Verify Android SDK is installed
- Check Java version (JDK 17 required)

## Resources

### Flutter

- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter Codelabs](https://flutter.dev/codelabs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

### Protocols

- [IMAP RFC 3501](https://tools.ietf.org/html/rfc3501)
- [CalDAV RFC 4791](https://tools.ietf.org/html/rfc4791)
- [CardDAV RFC 6352](https://tools.ietf.org/html/rfc6352)
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)

### Architecture

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course)

## Getting Help

- **Documentation**: Check the `docs/` folder
- **Issues**: [GitHub Issues](https://github.com/Demortes/unifydesk/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Demortes/unifydesk/discussions)
- **Contributing**: See [CONTRIBUTING.md](contributing/CONTRIBUTING.md)

## License

UnifyDesk is open source software licensed under the [MIT License](../LICENSE).

---

**Ready to contribute? Start with our [Contributing Guide](contributing/CONTRIBUTING.md)!**
