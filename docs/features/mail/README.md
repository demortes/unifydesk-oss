# Mail Feature

## Overview

The mail feature provides a comprehensive email client with support for multiple accounts, unified inbox, and modern email protocols.

## Key Features

### 📥 Unified Inbox
- View emails from all accounts in one place
- Smart filtering and sorting
- Quick account switching
- Per-account or unified view toggle

### 🔐 Multiple Account Support
- Add unlimited email accounts
- Support for various protocols:
  - IMAP + SMTP
  - OAuth 2.0 (Gmail, Outlook, Yahoo)
  - Custom server configuration
- Independent sync settings per account

### 📧 Email Management
- Read, compose, reply, forward emails
- Rich text editor with formatting
- Attachment support (view, download, upload)
- Draft auto-save
- Search across all accounts
- Labels and folders
- Mark as read/unread, star, archive
- Bulk operations

### 🔄 Synchronization
- Real-time sync with IMAP IDLE
- Background sync
- Configurable sync intervals
- Selective folder sync
- Offline support with local cache

### 🔍 Search & Filters
- Full-text search across all emails
- Search by sender, subject, date, attachments
- Save search queries
- Advanced filters
- Search within specific accounts or folders

## Supported Protocols

### IMAP (Internet Message Access Protocol)
- IMAP4rev1 (RFC 3501)
- IMAP over TLS (port 993)
- STARTTLS support
- IDLE extension for push notifications

### SMTP (Simple Mail Transfer Protocol)
- SMTP with TLS (port 465)
- SMTP with STARTTLS (port 587)
- Authentication methods: PLAIN, LOGIN, CRAM-MD5

### OAuth 2.0
- Google (Gmail)
- Microsoft (Outlook, Office 365)
- Yahoo Mail
- Custom OAuth providers

## Architecture

### Data Flow
```
User Action
    ↓
Presentation Layer (UI)
    ↓
Provider (State Management)
    ↓
Use Case (Business Logic)
    ↓
Repository Interface
    ↓
Repository Implementation
    ↓
Data Sources (Remote IMAP + Local Cache)
    ↓
Email Server / Local Database
```

### Components

#### Domain Layer (`lib/features/mail/domain/`)

**Entities:**
- `EmailAccount`: Represents an email account
- `EmailMessage`: Email message with metadata
- `Mailbox`: Email folder/mailbox
- `Attachment`: Email attachment
- `EmailAddress`: Sender/recipient address

**Use Cases:**
- `GetEmailsUseCase`: Fetch emails from server
- `SendEmailUseCase`: Send new email
- `SyncMailboxesUseCase`: Synchronize folders
- `SearchEmailsUseCase`: Search through emails
- `ManageLabelsUseCase`: Add/remove labels
- `DeleteEmailUseCase`: Delete or archive emails

**Repositories:**
- `MailRepository`: Abstract interface for mail operations

#### Data Layer (`lib/features/mail/data/`)

**Data Sources:**
- `ImapDataSource`: IMAP protocol implementation
- `SmtpDataSource`: SMTP protocol implementation
- `OAuthDataSource`: OAuth authentication
- `LocalMailDataSource`: Local cache and offline storage

**Models:**
- `EmailAccountModel`: Data model with JSON serialization
- `EmailMessageModel`: Message data model
- `MailboxModel`: Folder data model

**Repositories:**
- `MailRepositoryImpl`: Concrete implementation

#### Presentation Layer (`lib/features/mail/presentation/`)

**Pages:**
- `MailboxListPage`: List of folders/accounts
- `EmailListPage`: List of emails in a folder
- `EmailDetailPage`: Single email view
- `ComposeEmailPage`: Compose/reply interface
- `AccountSettingsPage`: Account configuration

**Widgets:**
- `EmailListItem`: Email preview in list
- `EmailBodyViewer`: Renders email HTML/text
- `AttachmentViewer`: Display attachments
- `RichTextEditor`: Compose email editor
- `AccountSwitcher`: Switch between accounts

**Providers:**
- `MailboxProvider`: Manages mailbox state
- `EmailListProvider`: Manages email list state
- `ComposeProvider`: Manages compose state
- `SyncProvider`: Manages sync operations

## Configuration

### Adding an Account

#### OAuth Account (Gmail)
```dart
final account = EmailAccount(
  type: AccountType.gmail,
  authMethod: AuthMethod.oauth,
  email: 'user@gmail.com',
  displayName: 'Personal Gmail',
);
```

#### IMAP/SMTP Account
```dart
final account = EmailAccount(
  type: AccountType.custom,
  authMethod: AuthMethod.password,
  email: 'user@example.com',
  displayName: 'Work Email',
  imapConfig: ImapConfig(
    host: 'imap.example.com',
    port: 993,
    security: ConnectionSecurity.tls,
  ),
  smtpConfig: SmtpConfig(
    host: 'smtp.example.com',
    port: 465,
    security: ConnectionSecurity.tls,
  ),
);
```

### Sync Settings
```dart
final syncConfig = SyncConfiguration(
  syncInterval: Duration(minutes: 15),
  syncOnStartup: true,
  syncOnlyOnWifi: false,
  enablePush: true, // IMAP IDLE
  cacheDuration: Duration(days: 30),
  downloadAttachments: AttachmentDownload.manual,
);
```

## Security Considerations

### Credential Storage
- OAuth tokens stored in platform secure storage
- IMAP/SMTP passwords stored encrypted
- Never log credentials

### Email Content
- Local cache encrypted
- Attachments encrypted at rest
- Secure deletion when account removed

### Network Communication
- TLS/SSL required by default
- Certificate validation
- No plain-text communication

## Testing

### Unit Tests
```bash
flutter test test/features/mail/
```

### Integration Tests
```bash
flutter test integration_test/mail_test.dart
```

### Test Coverage
- Domain layer: 95%+
- Data layer: 90%+
- Presentation: 85%+

## Performance

### Optimization Strategies
1. **Pagination**: Load emails in batches (50-100 at a time)
2. **Lazy Loading**: Load email bodies on demand
3. **Caching**: Cache frequently accessed emails
4. **Background Sync**: Non-blocking sync operations
5. **Indexing**: Full-text search with database indices

### Memory Management
- Limit cache size (configurable)
- Cleanup old emails
- Compress attachments
- Release unused resources

## Known Limitations

1. **HTML Rendering**: Complex HTML emails may not render perfectly
2. **Large Attachments**: Very large files (>100MB) may cause issues
3. **PGP/GPG**: End-to-end encryption not yet implemented
4. **Exchange**: Native Exchange protocol not supported (use IMAP)

## Future Enhancements

- [ ] PGP/GPG email encryption
- [ ] Advanced email rules and filters
- [ ] Email templates
- [ ] Scheduled sending
- [ ] Read receipts
- [ ] Email signatures with rich formatting
- [ ] Conversation threading improvements
- [ ] S/MIME support

## Troubleshooting

### Common Issues

**Problem**: Emails not syncing
- Check network connection
- Verify IMAP credentials
- Check server settings
- Review sync settings

**Problem**: Cannot send email
- Verify SMTP settings
- Check authentication
- Ensure correct port and security

**Problem**: OAuth login fails
- Clear OAuth tokens
- Re-authenticate
- Check app permissions on provider site

## Resources

- [IMAP RFC 3501](https://tools.ietf.org/html/rfc3501)
- [SMTP RFC 5321](https://tools.ietf.org/html/rfc5321)
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [Gmail API](https://developers.google.com/gmail/api)
- [Microsoft Graph Mail API](https://docs.microsoft.com/en-us/graph/api/resources/mail-api-overview)
