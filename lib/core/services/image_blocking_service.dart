import 'package:flutter/foundation.dart';

/// Service for managing remote image blocking preferences
class ImageBlockingService extends ChangeNotifier {
  bool _blockRemoteImages = true;

  bool get blockRemoteImages => _blockRemoteImages;

  void setBlockRemoteImages(bool value) {
    if (_blockRemoteImages != value) {
      _blockRemoteImages = value;
      notifyListeners();
    }
  }

  void toggleBlockRemoteImages() {
    setBlockRemoteImages(!_blockRemoteImages);
  }
}
