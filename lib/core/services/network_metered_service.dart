import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service that detects whether the current active network is metered.
///
/// On Android this delegates to a platform MethodChannel implemented in
/// `MainActivity` (method `isActiveNetworkMetered`). On other platforms it
/// falls back to treating mobile connections as metered via
/// `connectivity_plus`.
class NetworkMeteredService {
  static const MethodChannel _channel = MethodChannel('unifydesk/network');

  /// Returns true when the active network should be treated as metered.
  Future<bool> isActiveNetworkMetered() async {
    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>('isActiveNetworkMetered');
        if (res != null) return res;
      }
    } catch (_) {
      // ignore and fallback
    }

    final conn = await Connectivity().checkConnectivity();
    return conn == ConnectivityResult.mobile;
  }
}

final networkMeteredServiceProvider = Provider((ref) => NetworkMeteredService());
