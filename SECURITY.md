# Security Policy

## Supported Versions

We release security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

### Responsible Disclosure

We take security seriously. If you discover a security vulnerability, please follow these steps:

1. **Email**: Send details to unifydesk@demortes.com
   - Use subject line: "Security Vulnerability Report - UnifyDesk"
   - Include detailed description of the vulnerability
   - Include steps to reproduce (if applicable)
   - Suggest a fix (if you have one)

2. **Private Vulnerability Reporting** (GitHub):
   - Use GitHub's private vulnerability reporting feature
   - Navigate to Security > Advisories > New draft security advisory

3. **Expected Response Time**:
   - Initial response: Within 48 hours
   - Status update: Within 7 days
   - Fix timeline: Depends on severity

### What to Include

Please provide as much information as possible:

- Type of vulnerability
- Affected components/features
- Steps to reproduce
- Potential impact
- Affected versions
- Suggested mitigation (if known)

### What NOT to Include

- Do not include actual exploit code publicly
- Do not test vulnerabilities on production systems you don't own
- Do not share vulnerability details publicly until we've addressed it

## Vulnerability Severity

We classify vulnerabilities using the following severity levels:

### Critical
- Remote code execution
- Complete authentication bypass
- Full data exposure
- Mass credential theft

**Response**: Emergency patch within 24-48 hours

### High
- Privilege escalation
- Significant data exposure
- Authentication bypass (limited)
- SQL injection or similar

**Response**: Patch within 7 days

### Medium
- Limited information disclosure
- Cross-site scripting (XSS)
- Denial of service (limited impact)
- Insecure defaults

**Response**: Patch in next release (typically 2-4 weeks)

### Low
- Minor information disclosure
- Issues requiring physical access
- Theoretical vulnerabilities

**Response**: Scheduled for future release

## Security Features

UnifyDesk implements several security measures:

### Data Protection
- ✅ End-to-end encryption for local storage
- ✅ Platform secure storage for credentials (Keychain/Keystore)
- ✅ No server-side data storage
- ✅ Encrypted communication (TLS/SSL)
- ✅ Certificate validation

### Authentication
- ✅ OAuth 2.0 with PKCE
- ✅ No password storage (tokens only)
- ✅ Secure credential management
- ✅ Automatic token refresh
- ✅ App-level locking (optional)

### Network Security
- ✅ TLS 1.2+ required
- ✅ Certificate pinning for known services
- ✅ No plain-text communication
- ✅ Request timeout protection
- ✅ Rate limiting

### Code Security
- ✅ Regular dependency updates
- ✅ Automated vulnerability scanning
- ✅ Code review process
- ✅ Static analysis (flutter analyze)
- ✅ Security-focused testing

## Security Best Practices for Users

### Account Security
1. Use OAuth when available (Gmail, Outlook, etc.)
2. Enable 2FA on your email accounts
3. Use strong, unique passwords
4. Use app-specific passwords for IMAP
5. Regularly review connected applications

### Device Security
1. Enable device lock (PIN/password/biometric)
2. Keep OS and app updated
3. Enable device encryption (usually default)
4. Don't root/jailbreak your device
5. Be cautious with third-party app stores

### App Security
1. Download only from official sources (App Store, Play Store, official website)
2. Enable app lock if available
3. Review app permissions
4. Clear cache for sensitive data periodically
5. Remove unused accounts

## Security Updates

### Update Policy
- Critical security patches: Released immediately
- High severity: Released within 7 days
- Medium/Low severity: Included in regular releases

### Update Notifications
Users will be notified of security updates through:
- In-app notifications
- GitHub security advisories
- Release notes
- Project website/blog

### Applying Updates
Users should:
1. Enable auto-updates when possible
2. Check for updates regularly
3. Apply security updates promptly
4. Review release notes for security fixes

## Known Security Considerations

### Limitations
1. **Device Security**: We can't protect against compromised devices (malware, root/jailbreak)
2. **Physical Access**: Device must be physically secure
3. **Email Provider**: We rely on email provider's security
4. **Network**: Public WiFi may pose risks (use VPN)
5. **Backups**: Ensure device backups are encrypted

### Threats We Protect Against
✅ Man-in-the-middle attacks (TLS/SSL)
✅ Local data access (encryption)
✅ Network eavesdropping (encrypted communication)
✅ Credential theft (secure storage)
✅ Unauthorized access (device security)

### Threats Beyond Our Control
⚠️ Compromised device (malware, root/jailbreak)
⚠️ Compromised email server
⚠️ Physical device access (unlocked)
⚠️ Social engineering attacks
⚠️ Weak user passwords on email accounts

## Disclosure Policy

### Our Commitment
1. We will acknowledge receipt of vulnerability reports within 48 hours
2. We will provide regular updates on fix progress
3. We will credit reporters (unless they prefer to remain anonymous)
4. We will coordinate disclosure timing with reporter

### Disclosure Timeline
1. **Day 0**: Vulnerability reported privately
2. **Day 1-2**: Initial acknowledgment
3. **Day 7**: Status update provided
4. **Day X**: Fix developed and tested
5. **Day Y**: Fix released
6. **Day Y+7**: Public disclosure (after users have time to update)

### Coordinated Disclosure
- We prefer 90 days for complex issues
- We will work with reporters on disclosure timing
- We will credit researchers appropriately
- Public disclosure only after fix is available

## Security Audit

### Third-Party Audits
We welcome security audits from:
- Security researchers
- Academic institutions
- Professional security firms
- Community contributors

### Audit Scope
In scope:
- Application code (open source on GitHub)
- Dependencies and libraries
- Network communication
- Local storage and encryption
- Authentication mechanisms

Out of scope:
- Physical security
- Social engineering
- Denial of service
- Email provider infrastructure
- User's device security

## Bug Bounty

Currently, UnifyDesk does not have a bug bounty program. However, we:
- Acknowledge security researchers in release notes
- Provide credit in security advisories
- May offer swag/recognition for significant findings

## Security Resources

### For Developers
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [Flutter Security Best Practices](https://flutter.dev/docs/security)
- [Dart Security](https://dart.dev/guides/security)

### For Users
- [Privacy Documentation](docs/privacy/README.md)
- [Setup Guide](docs/setup/README.md)
- Email provider security documentation

## Contact

**Security Team**: unifydesk@demortes.com

**PGP Key**: [If available, provide PGP public key for encrypted communication]

**Response Times**:
- Critical: 24-48 hours
- High: 7 days
- Medium: 2-4 weeks
- Low: Next release cycle

---

Thank you for helping keep UnifyDesk and its users safe!
