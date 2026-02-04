import 'package:flutter/foundation.dart';
import '../utils/html_cleaning_levels.dart';

/// Service for managing HTML cleaning configuration
class HtmlCleaningConfigService extends ChangeNotifier {
  HtmlCleaningConfig _config = HtmlCleaningConfig.balanced();

  HtmlCleaningConfig get config => _config;

  void setConfig(HtmlCleaningConfig config) {
    if (_config != config) {
      _config = config;
      notifyListeners();
    }
  }

  void setLevel(HtmlCleaningLevel level) {
    HtmlCleaningConfig newConfig;
    switch (level) {
      case HtmlCleaningLevel.minimal:
        newConfig = HtmlCleaningConfig.minimal();
        break;
      case HtmlCleaningLevel.conservative:
        newConfig = HtmlCleaningConfig.conservative();
        break;
      case HtmlCleaningLevel.balanced:
        newConfig = HtmlCleaningConfig.balanced();
        break;
      case HtmlCleaningLevel.aggressive:
        newConfig = HtmlCleaningConfig.aggressive();
        break;
    }
    setConfig(newConfig);
  }

  void toggleStylePreservation() {
    setConfig(
      HtmlCleaningConfig(
        level: _config.level,
        preserveStyles: !_config.preserveStyles,
        preserveImages: _config.preserveImages,
        preserveOfficeElements: _config.preserveOfficeElements,
        enableDebugLogging: _config.enableDebugLogging,
      ),
    );
  }

  void toggleOfficeElementsPreservation() {
    setConfig(
      HtmlCleaningConfig(
        level: _config.level,
        preserveStyles: _config.preserveStyles,
        preserveImages: _config.preserveImages,
        preserveOfficeElements: !_config.preserveOfficeElements,
        enableDebugLogging: _config.enableDebugLogging,
      ),
    );
  }

  void toggleDebugLogging() {
    setConfig(
      HtmlCleaningConfig(
        level: _config.level,
        preserveStyles: _config.preserveStyles,
        preserveImages: _config.preserveImages,
        preserveOfficeElements: _config.preserveOfficeElements,
        enableDebugLogging: !_config.enableDebugLogging,
      ),
    );
  }
}
