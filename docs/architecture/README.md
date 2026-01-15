# Architecture Overview

## Design Philosophy

This application follows **Clean Architecture** principles with a feature-based folder structure, ensuring:
- **Separation of Concerns**: Clear boundaries between layers
- **Testability**: Easy to test each component independently
- **Maintainability**: Easy to understand and modify
- **Scalability**: Easy to add new features
- **Platform Agnostic**: Core logic independent of platform

## Architecture Layers

### 1. Presentation Layer
**Location**: `lib/features/*/presentation/`

Responsible for UI and user interaction.
- **Pages**: Full screen widgets (main UI screens)
- **Widgets**: Reusable UI components
- **Providers**: State management (using Riverpod/Provider/Bloc)

**Dependencies**: Domain layer only (no direct access to data layer)

### 2. Domain Layer
**Location**: `lib/features/*/domain/`

Contains business logic and rules.
- **Entities**: Core business objects (pure Dart classes)
- **Use Cases**: Business logic operations
- **Repositories**: Abstract interfaces (contracts)

**Dependencies**: None (pure Dart, no Flutter dependencies)

### 3. Data Layer
**Location**: `lib/features/*/data/`

Handles data operations and external communication.
- **Models**: Data transfer objects (DTOs)
- **Repositories**: Concrete implementations of domain repositories
- **Data Sources**: External data access (network, local storage)

**Dependencies**: Domain layer for contracts

### 4. Core Layer
**Location**: `lib/core/`

Shared functionality across the application.
- **Network**: HTTP clients, API configuration
- **Security**: Encryption, secure storage, OAuth
- **Storage**: Local database, cache management
- **Platform**: Platform-specific adaptations
- **DI**: Dependency injection setup
- **Utils**: Helper functions and extensions
- **Constants**: App-wide constants
- **Errors**: Error handling and exceptions

### 5. Shared Layer
**Location**: `lib/shared/`

Shared UI components and theming.
- **Widgets**: Reusable widgets across features
- **Themes**: App theming and styling
- **Layouts**: Adaptive layouts for different form factors
- **Animations**: Shared animations
- **Extensions**: Dart and Flutter extensions

## Data Flow

```
User Interaction (UI)
        ↓
Presentation Layer (Widget/Page)
        ↓
Provider/State Management
        ↓
Use Case (Business Logic)
        ↓
Repository Interface (Domain)
        ↓
Repository Implementation (Data)
        ↓
Data Source (Network/Local)
        ↓
External Service (IMAP/CalDAV/etc)
```

## Feature Structure

Each feature (mail, calendar, contacts) follows this structure:

```
feature/
├── data/
│   ├── datasources/
│   │   ├── remote/         # Network data sources
│   │   └── local/          # Local storage data sources
│   ├── models/             # DTOs with JSON serialization
│   └── repositories/       # Repository implementations
├── domain/
│   ├── entities/           # Business objects
│   ├── repositories/       # Repository contracts
│   └── usecases/           # Business logic
└── presentation/
    ├── pages/              # Full screens
    ├── widgets/            # Feature-specific widgets
    └── providers/          # State management
```

## Cross-Platform Adaptations

### Responsive Design Strategy
The app adapts to different form factors using:
- **Breakpoints**: Define different layouts for different screen sizes
- **Adaptive Widgets**: Use platform-specific widgets when appropriate
- **Layout Builders**: Dynamically adjust layout based on constraints

### Form Factor Categories
1. **Mobile** (< 600dp): Single-pane, bottom navigation
2. **Tablet** (600-840dp): Two-pane, side navigation
3. **Foldable**: Adaptive to folded/unfolded states
4. **Desktop** (> 840dp): Multi-pane, menu bar navigation

### Platform-Specific Implementations
Located in `lib/core/platform/`:
- Navigation patterns (bottom nav vs side nav vs menu bar)
- File pickers
- System integrations
- Platform-specific UI components

## State Management

**Recommended**: Riverpod (or Provider/Bloc)

### State Management Architecture
- **Providers**: Expose data and business logic
- **StateNotifier**: Manage complex state
- **FutureProvider**: Handle async operations
- **StreamProvider**: Handle real-time updates

## Security Architecture

### Data at Rest
- Sensitive credentials stored in platform secure storage (Keychain/Keystore)
- Local database encrypted
- App-level encryption for email cache

### Data in Transit
- TLS/SSL for all network communication
- Certificate pinning for known services
- OAuth 2.0 with PKCE for authentication

### Privacy Principles
1. **No external servers**: All data processed locally
2. **Minimal permissions**: Request only necessary permissions
3. **User control**: Users own their data
4. **Transparency**: Open source and auditable

## Testing Strategy

### Unit Tests (`test/`)
- Test business logic in isolation
- Test data transformations
- Test utility functions

### Widget Tests (`test/`)
- Test UI components
- Test widget behavior
- Test user interactions

### Integration Tests (`integration_test/`)
- Test end-to-end flows
- Test platform integrations
- Test real network calls (with mock servers)

## Dependency Management

### Core Dependencies
- **flutter**: Framework
- **riverpod**: State management
- **imap_client**: IMAP protocol
- **caldav**: Calendar sync
- **carddav**: Contacts sync
- **oauth2**: Authentication
- **flutter_secure_storage**: Secure credential storage
- **sqflite**: Local database
- **http**: Network requests

### Development Dependencies
- **flutter_test**: Testing framework
- **mockito**: Mocking
- **integration_test**: Integration testing
- **flutter_lints**: Linting rules

## Performance Considerations

1. **Lazy Loading**: Load data as needed
2. **Pagination**: Load large lists in chunks
3. **Caching**: Cache frequently accessed data
4. **Background Sync**: Sync data in background
5. **Efficient Rendering**: Use const constructors, optimize rebuilds
6. **Platform Channels**: Use for performance-critical operations

## Scalability

### Adding New Features
1. Create feature folder structure
2. Define entities and use cases
3. Implement repositories and data sources
4. Build UI components
5. Wire up with dependency injection
6. Add tests

### Modifying Existing Features
1. Identify the layer that needs changes
2. Make changes following the dependency rule
3. Update tests
4. Ensure backward compatibility if needed

## Further Reading

- [Mail Feature Architecture](../features/mail/ARCHITECTURE.md)
- [Calendar Feature Architecture](../features/calendar/ARCHITECTURE.md)
- [Contacts Feature Architecture](../features/contacts/ARCHITECTURE.md)
- [Security Implementation](../privacy/SECURITY.md)
