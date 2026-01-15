# Privacy & Security

## Privacy Commitment

This application is designed with **privacy-first** principles:

1. ✅ **No Data Collection**: We don't collect, store, or transmit your personal data to our servers
2. ✅ **No Analytics**: We don't track your usage or behavior
3. ✅ **No Ads**: Completely ad-free, no advertising networks
4. ✅ **No Telemetry**: No crash reports or error tracking sent to us
5. ✅ **Client-Side Only**: All processing happens on your device
6. ✅ **Open Source**: Code is transparent and auditable

## Data Storage

### What We Store Locally

| Data Type | Storage Location | Encryption |
|-----------|------------------|------------|
| Email Credentials | Platform Secure Storage (Keychain/Keystore) | ✅ Platform-level |
| OAuth Tokens | Platform Secure Storage | ✅ Platform-level |
| Email Messages (Cache) | Local Database | ✅ App-level encryption |
| Calendar Events | Local Database | ✅ App-level encryption |
| Contacts | Local Database | ✅ App-level encryption |
| App Settings | Shared Preferences | ⚠️ Non-sensitive data only |

### What We DON'T Store
- ❌ Passwords (OAuth tokens only, stored securely)
- ❌ Email content on external servers
- ❌ Contact information on external servers
- ❌ Calendar data on external servers
- ❌ User analytics or telemetry
- ❌ Device identifiers for tracking

## Network Communication

### Direct Connections Only
All network communication is **directly** between your device and your configured services:
- Your email provider (IMAP/SMTP servers)
- Your calendar provider (CalDAV servers)
- Your contacts provider (CardDAV servers)
- OAuth authentication servers (Google, Microsoft, etc.)

### No Intermediary Servers
- ❌ No proxy servers
- ❌ No data forwarding
- ❌ No API gateways owned by us
- ✅ Direct peer-to-peer communication

### Secure Protocols
All network communication uses secure protocols:
- **IMAP/SMTP**: TLS/SSL (ports 993/465 or STARTTLS)
- **CalDAV/CardDAV**: HTTPS only
- **OAuth**: HTTPS with PKCE
- **Certificate Validation**: Strict certificate checking

## Authentication & Authorization

### OAuth 2.0 with PKCE
For services that support it (Gmail, Outlook, etc.):
- Industry-standard OAuth 2.0 protocol
- PKCE (Proof Key for Code Exchange) for enhanced security
- Tokens stored in platform secure storage
- Automatic token refresh
- Revocable access

### IMAP Authentication
For traditional IMAP servers:
- App-specific passwords recommended
- Credentials stored in platform secure storage
- Support for CRAM-MD5 and other secure auth methods

### No Password Storage
- Passwords never stored in plain text
- OAuth preferred over passwords
- Use platform secure storage for any credentials

## Encryption

### Data at Rest
1. **Platform Secure Storage**:
   - iOS: Keychain with device encryption
   - Android: Keystore System with hardware backing
   - Desktop: Platform-specific secure storage

2. **Local Database**:
   - AES-256 encryption for sensitive data
   - Encryption key stored in platform secure storage
   - Per-user encryption keys

3. **File System**:
   - Leverage platform-level device encryption
   - App sandbox for data isolation

### Data in Transit
1. **TLS/SSL**:
   - TLS 1.2 minimum (prefer TLS 1.3)
   - Strong cipher suites only
   - Certificate pinning for known services

2. **Certificate Validation**:
   - Strict certificate checking
   - No self-signed certificates by default
   - User warnings for certificate issues

## Permissions

### Required Permissions

| Platform | Permission | Reason |
|----------|-----------|--------|
| All | **Internet** | Connect to email/calendar servers |
| Android | **Access Network State** | Check network connectivity |
| iOS/Android | **Notifications** | Email/calendar notifications (optional) |
| Desktop | **File System** | Save attachments, import/export data |

### Optional Permissions
- **Camera**: Scan QR codes for server configuration
- **Contacts**: Import system contacts (user initiated)
- **Calendar**: Import system calendar (user initiated)
- **Biometric**: Unlock app with fingerprint/face (optional)

### Permissions We DON'T Request
- ❌ Location
- ❌ Microphone
- ❌ SMS
- ❌ Phone calls
- ❌ Background location
- ❌ Advertising ID

## Threat Model

### What We Protect Against
1. ✅ **Man-in-the-Middle Attacks**: TLS/SSL with certificate validation
2. ✅ **Local Data Access**: Encryption at rest, platform secure storage
3. ✅ **Network Eavesdropping**: Encrypted communication
4. ✅ **Credential Theft**: Secure storage, OAuth preferred
5. ✅ **Unauthorized Access**: Device-level security (PIN, biometric)

### What We Can't Protect Against
1. ⚠️ **Compromised Device**: If device is rooted/jailbroken or has malware
2. ⚠️ **Compromised Email Server**: We rely on your email provider's security
3. ⚠️ **Physical Device Access**: If attacker has physical access with device unlocked
4. ⚠️ **Weak Passwords**: If you use weak passwords on your email accounts

## Best Practices for Users

### Account Security
1. ✅ Use OAuth when available (Google, Microsoft, etc.)
2. ✅ Enable 2FA on your email accounts
3. ✅ Use strong, unique passwords
4. ✅ Use app-specific passwords for IMAP
5. ✅ Regularly review connected apps

### Device Security
1. ✅ Use device PIN/password/biometric
2. ✅ Enable device encryption (usually default)
3. ✅ Keep OS and app updated
4. ✅ Don't root/jailbreak device
5. ✅ Use device lock screen

### App Security
1. ✅ Enable app lock (if available)
2. ✅ Review app permissions
3. ✅ Clear cache periodically for sensitive data
4. ✅ Remove old accounts you no longer use

## Data Retention

### Automatic Deletion
- Email cache: Configurable retention (default 30 days)
- Sent emails: Stored on mail server, cached locally per settings
- Deleted emails: Removed from local cache after sync
- Account removal: All associated data deleted immediately

### Manual Deletion
Users can manually:
- Clear email cache
- Clear all app data
- Remove individual accounts
- Export and delete data

## Compliance

### GDPR (European Union)
- ✅ No data collection = no GDPR concerns for our services
- ⚠️ Your email provider's GDPR compliance applies
- ✅ Right to be forgotten: Delete account removes all data
- ✅ Data portability: Export features available

### CCPA (California)
- ✅ No data sale (we don't have your data to sell)
- ✅ No data collection for advertising
- ✅ Transparent privacy practices

### Other Regulations
This app is designed to comply with privacy regulations worldwide by:
- Not collecting personal data
- Processing data locally only
- Providing user control over data

## Security Updates

### Reporting Vulnerabilities
If you discover a security vulnerability:
1. **DO NOT** create a public issue
2. Email: unifydesk@demortes.com
3. Use GitHub's private vulnerability reporting
4. Provide details for responsible disclosure

### Security Patches
- Critical security issues: Emergency patch within 24-48 hours
- High severity: Patch within 1 week
- Medium/Low severity: Patch in next regular release

## Audit & Transparency

### Open Source
- Full source code available on GitHub
- Community can audit security practices
- Third-party security audits welcome

### Dependency Management
- Regular dependency updates
- Security vulnerability scanning
- Minimal dependencies for reduced attack surface

## Questions?

For privacy-related questions:
- Read our [FAQ](FAQ.md)
- Check [SECURITY.md](../../SECURITY.md)
- Open a discussion on GitHub

---

**Your privacy is our priority. Your data stays yours.**
