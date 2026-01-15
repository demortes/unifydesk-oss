# UnifyDesk

A privacy-focused, cross-platform communications application built with Flutter. Seamlessly manage your email, calendar, and contacts across all your devices - phones, tablets, foldables, and desktops.

## 🌟 Features

### 📧 Mail
- **Unified Inbox**: View all your email accounts in one place
- **Multiple Account Support**: IMAP, OAuth (Gmail, Outlook, etc.)
- **Secure Communication**: TLS/SSL encryption for all connections
- **Offline Support**: Read and compose emails offline
- **Search & Filters**: Powerful search across all accounts
- **Labels & Folders**: Organize your emails efficiently

### 📅 Calendar
- **Multi-Calendar Sync**: Google Calendar, CalDAV support
- **Event Management**: Create, edit, and manage events
- **Reminders & Notifications**: Never miss an important event
- **Calendar Sharing**: View shared calendars
- **Offline Access**: Access your schedule anytime

### 👥 Contacts
- **Contact Sync**: Google Contacts, CardDAV support
- **Contact Management**: Add, edit, organize contacts
- **Groups & Labels**: Organize contacts efficiently
- **Search**: Quick contact lookup
- **vCard Support**: Import/export contacts

## 🔒 Privacy & Security

- ✅ **Client-Side Only**: No server, your data stays on your device
- ✅ **No Ads**: Completely ad-free experience
- ✅ **No Tracking**: We don't track or collect your data
- ✅ **Secure Protocols**: OAuth 2.0, IMAP/TLS, secure local storage
- ✅ **Encrypted Storage**: Sensitive data encrypted locally
- ✅ **Open Source**: Transparent and auditable code

## 📱 Supported Platforms

| Platform | Status |
|----------|--------|
| Android (Phone) | ✅ Supported |
| Android (Tablet) | ✅ Supported |
| Android (Foldable) | ✅ Supported |
| iOS (iPhone) | ✅ Supported |
| iOS (iPad) | ✅ Supported |
| Windows Desktop | ✅ Supported |
| macOS Desktop | ✅ Supported |
| Linux Desktop | ✅ Supported |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.19.0 or higher)
- Dart SDK (3.3.0 or higher)
- Platform-specific setup:
  - **Android**: Android Studio, Android SDK 21+
  - **iOS**: Xcode 15+, iOS 12+
  - **Desktop**: Platform-specific build tools

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Demortes/unifydesk.git
cd unifydesk
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For Android/iOS
flutter run

# For desktop
flutter run -d windows  # or macos, linux
```

## 🏗️ Project Structure

```
unifydesk/
├── lib/
│   ├── core/              # Core functionality (network, security, utils)
│   ├── features/          # Feature modules (mail, calendar, contacts)
│   │   ├── mail/
│   │   ├── calendar/
│   │   └── contacts/
│   └── shared/            # Shared UI components and themes
├── test/                  # Unit and widget tests
├── integration_test/      # Integration tests
├── docs/                  # Documentation
└── assets/                # Images, icons, fonts
```

For detailed architecture documentation, see [docs/architecture/README.md](docs/architecture/README.md).

## 📖 Documentation

- [Architecture Overview](docs/architecture/README.md)
- [Mail Feature](docs/features/mail/README.md)
- [Calendar Feature](docs/features/calendar/README.md)
- [Contacts Feature](docs/features/contacts/README.md)
- [Privacy & Security](docs/privacy/README.md)
- [Setup Guide](docs/setup/README.md)
- [Contributing](docs/contributing/CONTRIBUTING.md)

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test

# Run with coverage
flutter test --coverage
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](docs/contributing/CONTRIBUTING.md) for details.

### Development Setup
See [Setup Guide](docs/setup/README.md) for detailed development environment setup.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Contributors to email, calendar, and contact protocol libraries
- Open source community

## 📧 Contact & Support

- **Email**: unifydesk@demortes.com
- **Issues**: Please use GitHub Issues for bug reports and feature requests
- **Security**: For security vulnerabilities, please see [SECURITY.md](SECURITY.md)
- **Discussions**: Join our GitHub Discussions for questions and ideas

## 🗺️ Roadmap

- [ ] Enhanced foldable device support with adaptive layouts
- [ ] Advanced email filtering and rules
- [ ] Calendar recurring events with complex patterns
- [ ] Contact merge and duplicate detection
- [ ] End-to-end email encryption (PGP/GPG)
- [ ] Task management integration
- [ ] Custom themes and appearance options
- [ ] Plugin system for extensions

---

**Made with ❤️ for privacy and cross-platform excellence**
