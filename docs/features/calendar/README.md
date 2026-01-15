# Calendar Feature

## Overview

The calendar feature provides comprehensive calendar management with support for multiple calendars, event scheduling, and synchronization with popular calendar services.

## Key Features

### 📅 Multi-Calendar Support
- View multiple calendars simultaneously
- Calendar-specific colors and visibility
- Merge multiple accounts (Google, CalDAV, etc.)
- Per-calendar sync settings

### 📆 Event Management
- Create, edit, delete events
- All-day and timed events
- Recurring events with advanced patterns
- Event reminders and notifications
- Event attachments and notes
- Location support with maps integration
- Attendee management

### 🔄 Synchronization
- Two-way sync with CalDAV servers
- Google Calendar integration
- Offline support with local cache
- Real-time updates
- Conflict resolution

### 🔍 Views & Navigation
- Month view
- Week view
- Day view
- Agenda/list view
- Mini calendar widget
- Quick date navigation

### 🔔 Reminders & Notifications
- Multiple reminders per event
- Customizable reminder times
- Local notifications
- Snooze functionality

## Supported Protocols

### CalDAV
- RFC 4791 compliant
- CalDAV over HTTPS
- Calendar discovery
- Property synchronization
- Recurring event support (RRULE)

### Google Calendar API
- OAuth 2.0 authentication
- REST API integration
- Real-time updates
- Shared calendar access

### iCalendar Format (RFC 5545)
- `.ics` file import/export
- Standard format compatibility
- VEVENT, VTODO support

## Architecture

### Data Flow
```
User Action (Create Event)
    ↓
Presentation Layer (Calendar UI)
    ↓
Provider (Event State)
    ↓
Use Case (CreateEventUseCase)
    ↓
Repository Interface
    ↓
Repository Implementation
    ↓
Data Sources (CalDAV API + Local Cache)
    ↓
Calendar Server / Local Database
```

### Components

#### Domain Layer (`lib/features/calendar/domain/`)

**Entities:**
- `CalendarAccount`: Calendar service account
- `Calendar`: Individual calendar
- `Event`: Calendar event
- `Attendee`: Event participant
- `Reminder`: Event reminder/alarm
- `RecurrenceRule`: Recurring event pattern

**Use Cases:**
- `GetEventsUseCase`: Fetch events for date range
- `CreateEventUseCase`: Create new event
- `UpdateEventUseCase`: Modify existing event
- `DeleteEventUseCase`: Remove event
- `SyncCalendarsUseCase`: Synchronize with server
- `SearchEventsUseCase`: Search events

**Repositories:**
- `CalendarRepository`: Abstract calendar operations

#### Data Layer (`lib/features/calendar/data/`)

**Data Sources:**
- `CalDavDataSource`: CalDAV protocol implementation
- `GoogleCalendarDataSource`: Google Calendar API
- `LocalCalendarDataSource`: Local storage and cache

**Models:**
- `CalendarAccountModel`: Account data model
- `CalendarModel`: Calendar data model
- `EventModel`: Event data model with iCal parsing

**Repositories:**
- `CalendarRepositoryImpl`: Concrete implementation

#### Presentation Layer (`lib/features/calendar/presentation/`)

**Pages:**
- `CalendarOverviewPage`: Main calendar view
- `EventDetailPage`: Event details
- `EventEditPage`: Create/edit event
- `CalendarSettingsPage`: Calendar settings
- `CalendarListPage`: Manage calendars

**Widgets:**
- `MonthView`: Month calendar grid
- `WeekView`: Week timeline view
- `DayView`: Day schedule view
- `EventCard`: Event display widget
- `EventEditor`: Event creation/edit form
- `RecurrenceEditor`: Recurring event setup

**Providers:**
- `CalendarProvider`: Calendar state management
- `EventListProvider`: Event list state
- `EventEditorProvider`: Event editing state
- `SyncProvider`: Synchronization state

## Configuration

### Adding a CalDAV Account
```dart
final account = CalendarAccount(
  type: AccountType.caldav,
  authMethod: AuthMethod.password,
  displayName: 'Work Calendar',
  serverUrl: 'https://caldav.example.com',
  username: 'user@example.com',
  syncInterval: Duration(minutes: 15),
);
```

### Adding Google Calendar
```dart
final account = CalendarAccount(
  type: AccountType.google,
  authMethod: AuthMethod.oauth,
  displayName: 'Personal Google',
  email: 'user@gmail.com',
  syncInterval: Duration(minutes: 10),
);
```

### Creating an Event
```dart
final event = Event(
  title: 'Team Meeting',
  description: 'Weekly team sync',
  startTime: DateTime(2025, 1, 15, 10, 0),
  endTime: DateTime(2025, 1, 15, 11, 0),
  location: 'Conference Room A',
  reminders: [
    Reminder(minutesBefore: 15),
    Reminder(minutesBefore: 60),
  ],
  attendees: [
    Attendee(email: 'alice@example.com', name: 'Alice'),
    Attendee(email: 'bob@example.com', name: 'Bob'),
  ],
);
```

### Recurring Events
```dart
final event = Event(
  title: 'Daily Standup',
  startTime: DateTime(2025, 1, 15, 9, 0),
  endTime: DateTime(2025, 1, 15, 9, 15),
  recurrenceRule: RecurrenceRule(
    frequency: Frequency.daily,
    until: DateTime(2025, 12, 31),
    byWeekDay: [WeekDay.monday, WeekDay.wednesday, WeekDay.friday],
  ),
);
```

## Recurring Event Patterns

### Supported Patterns (RFC 5545)
- **Daily**: Every N days
- **Weekly**: Specific days of week
- **Monthly**: By day of month or week
- **Yearly**: By date or pattern
- **Custom**: Complex RRULE patterns

### Examples
```
Daily: FREQ=DAILY;INTERVAL=1
Weekly: FREQ=WEEKLY;BYDAY=MO,WE,FR
Monthly: FREQ=MONTHLY;BYMONTHDAY=15
Yearly: FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=25
```

## Security & Privacy

### Data Storage
- Events cached locally with encryption
- Credentials in platform secure storage
- Calendar data encrypted at rest

### Network Communication
- HTTPS/TLS required for CalDAV
- OAuth 2.0 for Google Calendar
- Certificate validation

### Privacy
- No event data sent to our servers
- Direct sync with calendar provider
- Local-only processing

## Testing

### Unit Tests
```bash
flutter test test/features/calendar/
```

### Integration Tests
```bash
flutter test integration_test/calendar_test.dart
```

## Performance

### Optimization
1. **Event Caching**: Cache events locally
2. **Range Loading**: Only load visible date range
3. **Lazy Rendering**: Render events on-demand
4. **Background Sync**: Non-blocking synchronization
5. **Indexing**: Database indices for fast queries

### Date Range Management
- Load events for visible range + buffer
- Paginate when loading large date ranges
- Prune old cached events

## Known Limitations

1. **Complex Recurrence**: Some very complex RRULE patterns may not be fully supported
2. **Time Zones**: Ensure device time zone is correct for accurate event display
3. **Large Calendars**: Calendars with thousands of events may have performance impact
4. **Shared Calendars**: Limited support for managing shared calendar permissions

## Future Enhancements

- [ ] Task/TODO integration (VTODO)
- [ ] Event proposals and voting
- [ ] Calendar sharing and permissions management
- [ ] Natural language event creation
- [ ] Smart scheduling suggestions
- [ ] Calendar overlay (combine multiple calendars)
- [ ] Event templates
- [ ] Time zone converter

## Troubleshooting

### Common Issues

**Problem**: Events not syncing
- Check network connection
- Verify calendar credentials
- Check CalDAV server URL
- Review sync settings

**Problem**: Recurring events not displaying
- Ensure RRULE is valid
- Check date range being queried
- Verify local timezone settings

**Problem**: Cannot create events
- Verify write permissions on calendar
- Check server availability
- Ensure calendar is not read-only

## Resources

- [CalDAV RFC 4791](https://tools.ietf.org/html/rfc4791)
- [iCalendar RFC 5545](https://tools.ietf.org/html/rfc5545)
- [Google Calendar API](https://developers.google.com/calendar)
- [CalDAV Protocol Guide](https://sabre.io/dav/building-a-caldav-client/)
