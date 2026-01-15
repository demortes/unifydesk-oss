# UnifyDesk Folder Structure

## Overview

UnifyDesk follows a feature-based architecture with clean separation of concerns. This document provides a comprehensive overview of the project's folder structure.

## Root Level Structure

```
unifydesk/
├── .github/                  # GitHub-specific files
│   ├── ISSUE_TEMPLATE/       # Issue templates
│   ├── workflows/            # CI/CD workflows
│   └── PULL_REQUEST_TEMPLATE.md
├── android/                  # Android platform code
├── assets/                   # Application assets
│   ├── fonts/
│   ├── icons/
│   └── images/
├── docs/                     # Documentation
├── integration_test/         # Integration tests
├── ios/                      # iOS platform code
├── lib/                      # Main application code
├── linux/                    # Linux platform code
├── macos/                    # macOS platform code
├── test/                     # Unit and widget tests
├── web/                      # Web platform code (if needed)
├── windows/                  # Windows platform code
├── .gitignore
├── analysis_options.yaml     # Dart analyzer configuration
├── LICENSE
├── pubspec.yaml              # Dependencies
├── README.md
└── SECURITY.md
```

## Documentation Structure (`docs/`)

```
docs/
├── architecture/             # Architecture documentation
│   └── README.md            # Clean architecture overview
├── contributing/            # Contribution guidelines
│   └── CONTRIBUTING.md
├── features/                # Feature-specific docs
│   ├── calendar/
│   │   └── README.md       # Calendar feature documentation
│   ├── contacts/
│   │   └── README.md       # Contacts feature documentation
│   └── mail/
│       └── README.md       # Mail feature documentation
├── privacy/                 # Privacy and security docs
│   └── README.md
├── setup/                   # Setup and installation guides
│   └── README.md
└── FOLDER_STRUCTURE.md     # This file
```

## Application Code Structure (`lib/`)

### Root Level (`lib/`)

```
lib/
├── core/                    # Core functionality (shared across features)
├── features/                # Feature modules
├── shared/                  # Shared UI components
└── main.dart                # Application entry point
```

### Core Module (`lib/core/`)

Core functionality shared across all features:

```
core/
├── constants/               # Application constants
│   ├── api_constants.dart   # API endpoints and keys
│   ├── app_constants.dart   # General app constants
│   └── storage_keys.dart    # Storage key constants
├── di/                      # Dependency injection
│   ├── injection.dart       # DI container setup
│   └── injection.config.dart  # Generated DI config
├── errors/                  # Error handling
│   ├── exceptions.dart      # Custom exceptions
│   ├── failures.dart        # Failure types
│   └── error_handler.dart   # Global error handler
├── network/                 # Network layer
│   ├── api_client.dart      # HTTP client wrapper
│   ├── network_info.dart    # Network connectivity checker
│   └── interceptors/        # HTTP interceptors
│       ├── auth_interceptor.dart
│       ├── logging_interceptor.dart
│       └── error_interceptor.dart
├── platform/                # Platform-specific code
│   ├── adaptive/            # Adaptive UI helpers
│   │   ├── breakpoints.dart
│   │   ├── layout_builder.dart
│   │   └── platform_detector.dart
│   ├── android/
│   ├── ios/
│   ├── desktop/
│   └── foldable/            # Foldable device support
├── security/                # Security and encryption
│   ├── encryption_service.dart
│   ├── secure_storage.dart
│   ├── certificate_pinning.dart
│   └── oauth/
│       ├── oauth_client.dart
│       ├── oauth_providers.dart
│       └── token_manager.dart
├── storage/                 # Local storage
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── daos/            # Data access objects
│   │   └── entities/        # Database entities
│   ├── cache/
│   │   └── cache_manager.dart
│   └── preferences/
│       └── preferences_service.dart
└── utils/                   # Utility functions
    ├── date_utils.dart
    ├── extensions/
    │   ├── string_extensions.dart
    │   ├── datetime_extensions.dart
    │   └── list_extensions.dart
    ├── logger.dart
    ├── validators.dart
    └── helpers.dart
```

### Features Module (`lib/features/`)

Each feature follows Clean Architecture with three layers:

```
features/
├── auth/                    # Authentication feature
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   └── auth_local_datasource.dart
│   │   │   └── remote/
│   │   │       └── auth_remote_datasource.dart
│   │   ├── models/
│   │   │   └── user_model.dart
│   │   └── repositories/
│   │       └── auth_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   └── user.dart
│   │   ├── repositories/
│   │   │   └── auth_repository.dart
│   │   └── usecases/
│   │       ├── login_usecase.dart
│   │       ├── logout_usecase.dart
│   │       └── get_current_user_usecase.dart
│   └── presentation/
│       ├── pages/
│       │   ├── login_page.dart
│       │   └── account_setup_page.dart
│       ├── providers/
│       │   └── auth_provider.dart
│       └── widgets/
│           ├── login_form.dart
│           └── oauth_button.dart
│
├── calendar/                # Calendar feature
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   └── calendar_local_datasource.dart
│   │   │   └── remote/
│   │   │       ├── caldav_datasource.dart
│   │   │       └── google_calendar_datasource.dart
│   │   ├── models/
│   │   │   ├── calendar_model.dart
│   │   │   ├── event_model.dart
│   │   │   └── recurrence_rule_model.dart
│   │   └── repositories/
│   │       └── calendar_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── calendar.dart
│   │   │   ├── calendar_account.dart
│   │   │   ├── event.dart
│   │   │   ├── attendee.dart
│   │   │   ├── reminder.dart
│   │   │   └── recurrence_rule.dart
│   │   ├── repositories/
│   │   │   └── calendar_repository.dart
│   │   └── usecases/
│   │       ├── get_events_usecase.dart
│   │       ├── create_event_usecase.dart
│   │       ├── update_event_usecase.dart
│   │       ├── delete_event_usecase.dart
│   │       └── sync_calendars_usecase.dart
│   └── presentation/
│       ├── pages/
│       │   ├── calendar_overview_page.dart
│       │   ├── event_detail_page.dart
│       │   └── event_edit_page.dart
│       ├── providers/
│       │   ├── calendar_provider.dart
│       │   ├── event_list_provider.dart
│       │   └── event_editor_provider.dart
│       └── widgets/
│           ├── month_view.dart
│           ├── week_view.dart
│           ├── day_view.dart
│           ├── event_card.dart
│           └── recurrence_editor.dart
│
├── contacts/                # Contacts feature
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   └── contacts_local_datasource.dart
│   │   │   └── remote/
│   │   │       ├── carddav_datasource.dart
│   │   │       └── google_contacts_datasource.dart
│   │   ├── models/
│   │   │   ├── contact_model.dart
│   │   │   ├── contact_group_model.dart
│   │   │   ├── phone_number_model.dart
│   │   │   ├── email_address_model.dart
│   │   │   └── address_model.dart
│   │   └── repositories/
│   │       └── contact_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── contact.dart
│   │   │   ├── contact_account.dart
│   │   │   ├── contact_group.dart
│   │   │   ├── phone_number.dart
│   │   │   ├── email_address.dart
│   │   │   └── address.dart
│   │   ├── repositories/
│   │   │   └── contact_repository.dart
│   │   └── usecases/
│   │       ├── get_contacts_usecase.dart
│   │       ├── create_contact_usecase.dart
│   │       ├── update_contact_usecase.dart
│   │       ├── delete_contact_usecase.dart
│   │       └── sync_contacts_usecase.dart
│   └── presentation/
│       ├── pages/
│       │   ├── contact_list_page.dart
│       │   ├── contact_detail_page.dart
│       │   └── contact_edit_page.dart
│       ├── providers/
│       │   ├── contact_list_provider.dart
│       │   ├── contact_detail_provider.dart
│       │   └── contact_editor_provider.dart
│       └── widgets/
│           ├── contact_list_item.dart
│           ├── contact_card.dart
│           ├── contact_avatar.dart
│           └── contact_editor_form.dart
│
├── mail/                    # Mail feature
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   └── mail_local_datasource.dart
│   │   │   └── remote/
│   │   │       ├── imap_datasource.dart
│   │   │       ├── smtp_datasource.dart
│   │   │       └── oauth_mail_datasource.dart
│   │   ├── models/
│   │   │   ├── email_account_model.dart
│   │   │   ├── email_message_model.dart
│   │   │   ├── mailbox_model.dart
│   │   │   └── attachment_model.dart
│   │   └── repositories/
│   │       └── mail_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── email_account.dart
│   │   │   ├── email_message.dart
│   │   │   ├── email_address.dart
│   │   │   ├── mailbox.dart
│   │   │   └── attachment.dart
│   │   ├── repositories/
│   │   │   └── mail_repository.dart
│   │   └── usecases/
│   │       ├── get_emails_usecase.dart
│   │       ├── send_email_usecase.dart
│   │       ├── sync_mailboxes_usecase.dart
│   │       ├── search_emails_usecase.dart
│   │       ├── delete_email_usecase.dart
│   │       └── manage_labels_usecase.dart
│   └── presentation/
│       ├── pages/
│       │   ├── mailbox_list_page.dart
│       │   ├── email_list_page.dart
│       │   ├── email_detail_page.dart
│       │   └── compose_email_page.dart
│       ├── providers/
│       │   ├── mailbox_provider.dart
│       │   ├── email_list_provider.dart
│       │   ├── compose_provider.dart
│       │   └── sync_provider.dart
│       └── widgets/
│           ├── email_list_item.dart
│           ├── email_body_viewer.dart
│           ├── attachment_viewer.dart
│           ├── rich_text_editor.dart
│           └── account_switcher.dart
│
└── settings/                # Settings feature
    ├── data/
    │   ├── datasources/
    │   │   └── local/
    │   │       └── settings_local_datasource.dart
    │   ├── models/
    │   │   └── app_settings_model.dart
    │   └── repositories/
    │       └── settings_repository_impl.dart
    ├── domain/
    │   ├── entities/
    │   │   └── app_settings.dart
    │   ├── repositories/
    │   │   └── settings_repository.dart
    │   └── usecases/
    │       ├── get_settings_usecase.dart
    │       └── update_settings_usecase.dart
    └── presentation/
        ├── pages/
        │   ├── settings_page.dart
        │   ├── account_settings_page.dart
        │   ├── sync_settings_page.dart
        │   └── appearance_settings_page.dart
        ├── providers/
        │   └── settings_provider.dart
        └── widgets/
            └── settings_tile.dart
```

### Shared Module (`lib/shared/`)

Shared UI components and utilities:

```
shared/
├── animations/              # Shared animations
│   ├── fade_in_animation.dart
│   └── slide_transition_animation.dart
├── extensions/              # Shared extensions
│   ├── build_context_extensions.dart
│   └── theme_extensions.dart
├── layouts/                 # Adaptive layouts
│   ├── desktop/
│   │   └── desktop_scaffold.dart
│   ├── foldable/
│   │   ├── foldable_detector.dart
│   │   └── foldable_layout.dart
│   ├── mobile/
│   │   └── mobile_scaffold.dart
│   └── tablet/
│       └── tablet_scaffold.dart
├── themes/                  # App theming
│   ├── app_theme.dart
│   ├── color_schemes.dart
│   ├── text_styles.dart
│   └── component_themes/
│       ├── button_theme.dart
│       ├── card_theme.dart
│       └── input_theme.dart
└── widgets/                 # Reusable widgets
    ├── buttons/
    │   ├── primary_button.dart
    │   └── icon_button_widget.dart
    ├── cards/
    │   └── info_card.dart
    ├── dialogs/
    │   ├── confirmation_dialog.dart
    │   └── error_dialog.dart
    ├── inputs/
    │   ├── text_field_widget.dart
    │   └── search_bar_widget.dart
    ├── loading/
    │   ├── loading_indicator.dart
    │   └── shimmer_loading.dart
    └── navigation/
        ├── app_drawer.dart
        ├── bottom_nav_bar.dart
        └── side_navigation_bar.dart
```

## Test Structure (`test/`)

Mirrors the lib structure:

```
test/
├── core/
│   ├── network/
│   ├── security/
│   ├── storage/
│   └── utils/
├── features/
│   ├── auth/
│   ├── calendar/
│   ├── contacts/
│   ├── mail/
│   └── settings/
├── shared/
│   ├── widgets/
│   └── themes/
└── helpers/
    ├── test_helpers.dart
    └── mock_data.dart
```

## Integration Tests (`integration_test/`)

```
integration_test/
├── auth_test.dart
├── calendar_test.dart
├── contacts_test.dart
├── mail_test.dart
└── helpers/
    └── test_setup.dart
```

## Platform-Specific Folders

### Android (`android/`)
Standard Android project structure with Kotlin/Java code.

### iOS (`ios/`)
Standard iOS project structure with Swift/Objective-C code.

### Windows (`windows/`)
Windows desktop runner and native code.

### macOS (`macos/`)
macOS desktop runner and native code.

### Linux (`linux/`)
Linux desktop runner and native code.

## Key Principles

1. **Feature Independence**: Each feature is self-contained
2. **Clear Boundaries**: Strict separation between layers
3. **Dependency Direction**: Outer layers depend on inner layers
4. **Shared Code**: Common code in `core/` and `shared/`
5. **Platform Adaptation**: Platform-specific code isolated
6. **Testability**: Easy to test with mirrored test structure

## Adding a New Feature

1. Create feature folder in `lib/features/`
2. Create `data/`, `domain/`, and `presentation/` subfolders
3. Implement domain layer (entities, repositories, use cases)
4. Implement data layer (models, data sources, repository impl)
5. Implement presentation layer (pages, widgets, providers)
6. Add tests in corresponding `test/features/` folder
7. Add documentation in `docs/features/` folder

## Navigation Between Layers

- **Presentation → Domain**: Through use cases
- **Domain → Data**: Through repository interfaces
- **Data → External**: Through data sources
- **Never**: Data → Domain or Domain → Presentation

---

For more information, see [Architecture Documentation](architecture/README.md).
