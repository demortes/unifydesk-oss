# Contacts Feature

## Overview

The contacts feature provides comprehensive contact management with support for multiple accounts, contact synchronization, and integration with email and calendar features.

## Key Features

### 👥 Contact Management
- Create, edit, delete contacts
- Multiple phone numbers, emails, addresses
- Contact photos
- Custom fields and notes
- Birthday and anniversary tracking
- Organization and job title
- Social media profiles

### 📱 Multiple Account Support
- Google Contacts integration
- CardDAV server support
- Multiple contact sources
- Unified contact view
- Account-specific organization

### 🔄 Synchronization
- Two-way sync with CardDAV servers
- Google Contacts API integration
- Offline support with local cache
- Conflict resolution
- Selective sync options

### 🔍 Search & Organization
- Fast contact search
- Search by name, email, phone, organization
- Groups and labels
- Favorites/starred contacts
- Custom categories

### 🔗 Integration
- Quick compose email to contact
- Create calendar event with contact
- Click to call/message (platform dependent)
- Contact sharing (vCard)

## Supported Protocols

### CardDAV
- RFC 6352 compliant
- CardDAV over HTTPS
- Address book discovery
- Property synchronization
- vCard 3.0 and 4.0 support

### Google Contacts API
- OAuth 2.0 authentication
- REST API integration
- Contact groups/labels
- Real-time synchronization

### vCard Format (RFC 6350)
- `.vcf` file import/export
- vCard 3.0 and 4.0
- Standard property support
- Photo embedding

## Architecture

### Data Flow
```
User Action (Create Contact)
    ↓
Presentation Layer (Contact UI)
    ↓
Provider (Contact State)
    ↓
Use Case (CreateContactUseCase)
    ↓
Repository Interface
    ↓
Repository Implementation
    ↓
Data Sources (CardDAV API + Local Cache)
    ↓
Contact Server / Local Database
```

### Components

#### Domain Layer (`lib/features/contacts/domain/`)

**Entities:**
- `ContactAccount`: Contact service account
- `Contact`: Contact information
- `PhoneNumber`: Phone with type (mobile, work, etc.)
- `EmailAddress`: Email with type
- `Address`: Physical address
- `ContactGroup`: Contact grouping/label

**Use Cases:**
- `GetContactsUseCase`: Fetch contacts
- `CreateContactUseCase`: Create new contact
- `UpdateContactUseCase`: Modify contact
- `DeleteContactUseCase`: Remove contact
- `SyncContactsUseCase`: Synchronize with server
- `SearchContactsUseCase`: Search contacts
- `ManageGroupsUseCase`: Manage contact groups

**Repositories:**
- `ContactRepository`: Abstract contact operations

#### Data Layer (`lib/features/contacts/data/`)

**Data Sources:**
- `CardDavDataSource`: CardDAV protocol implementation
- `GoogleContactsDataSource`: Google Contacts API
- `LocalContactsDataSource`: Local storage and cache

**Models:**
- `ContactAccountModel`: Account data model
- `ContactModel`: Contact data model with vCard parsing
- `ContactGroupModel`: Group data model

**Repositories:**
- `ContactRepositoryImpl`: Concrete implementation

#### Presentation Layer (`lib/features/contacts/presentation/`)

**Pages:**
- `ContactListPage`: List of contacts
- `ContactDetailPage`: Contact details view
- `ContactEditPage`: Create/edit contact
- `ContactSettingsPage`: Contact settings
- `GroupManagementPage`: Manage groups

**Widgets:**
- `ContactListItem`: Contact preview in list
- `ContactCard`: Contact display widget
- `ContactEditor`: Contact creation/edit form
- `ContactAvatar`: Contact photo/initials
- `ContactActionBar`: Quick actions (call, email, etc.)

**Providers:**
- `ContactListProvider`: Contact list state
- `ContactDetailProvider`: Single contact state
- `ContactEditorProvider`: Edit state
- `SyncProvider`: Synchronization state

## Configuration

### Adding a CardDAV Account
```dart
final account = ContactAccount(
  type: AccountType.cardDav,
  authMethod: AuthMethod.password,
  displayName: 'Work Contacts',
  serverUrl: 'https://carddav.example.com',
  username: 'user@example.com',
  syncInterval: Duration(hours: 1),
);
```

### Adding Google Contacts
```dart
final account = ContactAccount(
  type: AccountType.google,
  authMethod: AuthMethod.oauth,
  displayName: 'Personal Google',
  email: 'user@gmail.com',
  syncInterval: Duration(minutes: 30),
);
```

### Creating a Contact
```dart
final contact = Contact(
  displayName: 'John Doe',
  givenName: 'John',
  familyName: 'Doe',
  organization: 'Acme Corp',
  jobTitle: 'Software Engineer',
  emails: [
    EmailAddress(
      email: 'john.doe@example.com',
      type: EmailType.work,
      isPrimary: true,
    ),
    EmailAddress(
      email: 'john@personal.com',
      type: EmailType.personal,
    ),
  ],
  phones: [
    PhoneNumber(
      number: '+1-555-0123',
      type: PhoneType.mobile,
      isPrimary: true,
    ),
  ],
  addresses: [
    Address(
      street: '123 Main St',
      city: 'Springfield',
      state: 'IL',
      postalCode: '62701',
      country: 'USA',
      type: AddressType.work,
    ),
  ],
  birthday: DateTime(1990, 5, 15),
  notes: 'Met at conference 2024',
);
```

## Contact Properties

### Standard Fields (vCard 4.0)
- **Name**: Prefix, given, middle, family, suffix
- **Nickname**
- **Organization** and **Job Title**
- **Emails**: Multiple with types (work, home, other)
- **Phones**: Multiple with types (mobile, work, home, fax, etc.)
- **Addresses**: Multiple with types (work, home, other)
- **URLs**: Website, social media profiles
- **Birthday** and **Anniversary**
- **Photo**: Contact image
- **Notes**: Free-form text
- **Categories/Groups**: Organization

### Custom Fields
Support for custom properties:
```dart
contact.customFields = {
  'X-FAVORITE-COLOR': 'Blue',
  'X-PREFERRED-NAME': 'Johnny',
};
```

## Contact Groups

### Group Management
```dart
final group = ContactGroup(
  name: 'Team',
  members: [contact1.id, contact2.id, contact3.id],
  color: Colors.blue,
);
```

### Use Cases
- Organize contacts by team, project, family, etc.
- Quick filtering and access
- Group email/messaging
- Bulk operations

## Import & Export

### Import vCard
```dart
// Import single contact
final contact = await importVCard(file);

// Import multiple contacts
final contacts = await importVCards(file);
```

### Export vCard
```dart
// Export single contact
await exportVCard(contact, file);

// Export multiple contacts
await exportVCards(contacts, file);
```

### Batch Operations
- Import from .vcf file
- Export to .vcf file
- Merge duplicates
- Bulk delete

## Security & Privacy

### Data Storage
- Contacts cached locally with encryption
- Photos stored securely
- Credentials in platform secure storage

### Network Communication
- HTTPS/TLS required for CardDAV
- OAuth 2.0 for Google Contacts
- Certificate validation

### Privacy
- No contact data sent to our servers
- Direct sync with contact provider
- Local-only processing
- User controls data sharing

## Testing

### Unit Tests
```bash
flutter test test/features/contacts/
```

### Integration Tests
```bash
flutter test integration_test/contacts_test.dart
```

## Performance

### Optimization
1. **Pagination**: Load contacts in batches
2. **Indexing**: Fast search with database indices
3. **Lazy Loading**: Load contact details on demand
4. **Photo Caching**: Cache contact photos
5. **Background Sync**: Non-blocking synchronization

### Large Contact Lists
- Efficient list rendering with virtual scrolling
- Search indexing for fast queries
- Thumbnail generation for photos

## Known Limitations

1. **Photo Size**: Very large photos may be compressed
2. **Custom Fields**: Some custom vCard properties may not sync to all services
3. **Duplicate Detection**: Automatic merge requires user confirmation
4. **Group Sync**: Not all CardDAV servers support groups

## Future Enhancements

- [ ] Automatic duplicate detection and merging
- [ ] Contact history (recent interactions)
- [ ] Smart contact suggestions
- [ ] Social media integration
- [ ] QR code business card scanning
- [ ] Contact sharing via NFC
- [ ] Advanced search filters
- [ ] Contact backup and restore

## Troubleshooting

### Common Issues

**Problem**: Contacts not syncing
- Check network connection
- Verify CardDAV credentials
- Check server URL and settings
- Review sync configuration

**Problem**: Duplicate contacts
- Use merge duplicates feature
- Check sync settings for multiple sources
- Verify account configuration

**Problem**: Missing contact fields
- Check vCard version compatibility
- Verify server supports all properties
- Review field mapping

**Problem**: Photo not displaying
- Check photo size and format
- Verify network connection for download
- Clear photo cache

## Resources

- [CardDAV RFC 6352](https://tools.ietf.org/html/rfc6352)
- [vCard RFC 6350](https://tools.ietf.org/html/rfc6350)
- [Google Contacts API](https://developers.google.com/people)
- [CardDAV Protocol Guide](https://sabre.io/dav/building-a-carddav-client/)
