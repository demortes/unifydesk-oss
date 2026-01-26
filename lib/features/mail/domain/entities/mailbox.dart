import 'package:equatable/equatable.dart';

/// Represents a mailbox/folder on an email server.
class Mailbox extends Equatable {
  const Mailbox({
    required this.accountId,
    required this.name,
    required this.path,
    this.delimiter = '/',
    this.flags = const [],
    this.totalMessages = 0,
    this.unreadMessages = 0,
    this.isSelectable = true,
    this.isSubscribed = true,
  });

  /// Account this mailbox belongs to.
  final String accountId;

  /// Display name of the mailbox.
  final String name;

  /// Full path of the mailbox.
  final String path;

  /// Hierarchy delimiter (usually "/" or ".").
  final String delimiter;

  /// Mailbox flags from server.
  final List<String> flags;

  /// Total number of messages.
  final int totalMessages;

  /// Number of unread messages.
  final int unreadMessages;

  /// Whether this mailbox can be selected.
  final bool isSelectable;

  /// Whether user is subscribed to this mailbox.
  final bool isSubscribed;

  /// Check if this is a special mailbox.
  bool get isInbox =>
      path.toLowerCase() == 'inbox' || flags.contains(r'\Inbox');
  bool get isSent =>
      flags.contains(r'\Sent') || path.toLowerCase().contains('sent');
  bool get isDrafts =>
      flags.contains(r'\Drafts') || path.toLowerCase().contains('draft');
  bool get isTrash =>
      flags.contains(r'\Trash') || path.toLowerCase().contains('trash');
  bool get isJunk =>
      flags.contains(r'\Junk') ||
      path.toLowerCase().contains('spam') ||
      path.toLowerCase().contains('junk');
  bool get isArchive =>
      flags.contains(r'\Archive') || path.toLowerCase().contains('archive');

  /// Get an icon for this mailbox type.
  String get iconName {
    if (isInbox) return 'inbox';
    if (isSent) return 'send';
    if (isDrafts) return 'drafts';
    if (isTrash) return 'delete';
    if (isJunk) return 'warning';
    if (isArchive) return 'archive';
    return 'folder';
  }

  Mailbox copyWith({
    String? accountId,
    String? name,
    String? path,
    String? delimiter,
    List<String>? flags,
    int? totalMessages,
    int? unreadMessages,
    bool? isSelectable,
    bool? isSubscribed,
  }) {
    return Mailbox(
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      path: path ?? this.path,
      delimiter: delimiter ?? this.delimiter,
      flags: flags ?? this.flags,
      totalMessages: totalMessages ?? this.totalMessages,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      isSelectable: isSelectable ?? this.isSelectable,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }

  @override
  List<Object?> get props => [
        accountId,
        name,
        path,
        delimiter,
        flags,
        totalMessages,
        unreadMessages,
        isSelectable,
        isSubscribed,
      ];
}
