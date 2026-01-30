import '../entities/email_message.dart';
import '../entities/mailbox.dart';

/// Repository interface for email operations.
abstract class EmailRepository {
  /// Sync mailboxes from server.
  Future<List<Mailbox>> syncMailboxes(String accountId);

  /// Get cached mailboxes.
  Future<List<Mailbox>> getMailboxes(String accountId);

  /// Sync emails from a specific mailbox.
  Future<List<EmailMessage>> syncEmails(
    String accountId,
    String mailboxPath, {
    bool fullSync = false,
  });

  /// Get cached emails for a mailbox.
  Future<List<EmailMessage>> getEmails(
    String accountId,
    String mailboxPath, {
    int limit = 50,
    int offset = 0,
  });

  /// Get a single email by ID.
  Future<EmailMessage?> getEmailById(String id);

  /// Fetch full email content from server.
  Future<EmailMessage?> fetchFullEmail(
    String accountId,
    String mailboxPath,
    int uid,
  );

  /// Mark email as read/unread.
  Future<void> setReadStatus(
    String accountId,
    String mailboxPath,
    String emailId,
    int uid, {
    required bool isRead,
  });

  /// Mark email as starred/flagged.
  Future<void> setStarredStatus(
    String accountId,
    String mailboxPath,
    String emailId,
    int uid, {
    required bool isStarred,
  });

  /// Move email to another mailbox.
  Future<void> moveEmail(
    String accountId,
    String sourceMailbox,
    String targetMailbox,
    String emailId,
    int uid,
  );

  /// Create a mailbox/folder on the server.
  Future<void> createMailbox(String accountId, String mailboxPath);

  /// Delete email.
  Future<void> deleteEmail(
    String accountId,
    String mailboxPath,
    String emailId,
    int uid, {
    bool permanent = false,
  });

  /// Get unread count for a mailbox.
  Future<int> getUnreadCount(String accountId, String mailboxPath);

  /// Disconnect from server (cleanup).
  Future<void> disconnect();
}
