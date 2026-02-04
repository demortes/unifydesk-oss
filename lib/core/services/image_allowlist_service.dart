import 'package:flutter/foundation.dart';

/// Service for managing sender allowlist (senders whose images are always allowed)
class ImageAllowlistService extends ChangeNotifier {
  final Set<String> _allowlist = <String>{};

  Set<String> get allowlist => Set.unmodifiable(_allowlist);

  bool isAllowed(String address) => _allowlist.contains(address.toLowerCase());

  void allow(String address) {
    if (_allowlist.add(address.toLowerCase())) {
      notifyListeners();
    }
  }

  void disallow(String address) {
    if (_allowlist.remove(address.toLowerCase())) {
      notifyListeners();
    }
  }

  void clear() {
    if (_allowlist.isNotEmpty) {
      _allowlist.clear();
      notifyListeners();
    }
  }
}
