/// HTML cleaning levels for email rendering
/// 
/// This system provides different levels of HTML cleaning to balance
/// security, compatibility, and content preservation.

enum HtmlCleaningLevel {
  /// Minimal cleaning - only essential safety measures
  /// - Decode quoted-printable
  /// - Remove script tags
  /// - Basic XSS protection
  /// Use when: Email appears broken with higher levels
  minimal,
  
  /// Conservative cleaning - moderate compatibility improvements
  /// - Minimal cleaning +
  /// - Remove DOCTYPE and XML declarations
  /// - Simple MSO conditional comment removal
  /// - Basic style tag cleanup
  /// Use when: Default level causes issues but minimal is insufficient
  conservative,
  
  /// Balanced cleaning - good compatibility with content preservation
  /// - Conservative cleaning +
  /// - Remove head tags but preserve title
  /// - Remove VML elements
  /// - Clean xmlns attributes
  /// - Remove most MSO properties
  /// Use when: Best balance of compatibility and content (RECOMMENDED DEFAULT)
  balanced,
  
  /// Aggressive cleaning - maximum compatibility (current behavior)
  /// - Balanced cleaning +
  /// - Remove ALL style blocks
  /// - Remove ALL head content
  /// - Extensive MSO/Office cleanup
  /// - HTML tag simplification
  /// Use when: Email has extensive Office/Outlook formatting
  aggressive,
}

class HtmlCleaningConfig {
  final HtmlCleaningLevel level;
  final bool preserveStyles;
  final bool preserveImages;
  final bool preserveOfficeElements;
  final bool enableDebugLogging;
  
  const HtmlCleaningConfig({
    this.level = HtmlCleaningLevel.balanced,
    this.preserveStyles = false,
    this.preserveImages = true,
    this.preserveOfficeElements = false,
    this.enableDebugLogging = true,
  });
  
  /// Create config for minimal cleaning
  factory HtmlCleaningConfig.minimal() => const HtmlCleaningConfig(
    level: HtmlCleaningLevel.minimal,
    preserveStyles: true,
    preserveImages: true,
    preserveOfficeElements: true,
    enableDebugLogging: true,
  );
  
  /// Create config for conservative cleaning
  factory HtmlCleaningConfig.conservative() => const HtmlCleaningConfig(
    level: HtmlCleaningLevel.conservative,
    preserveStyles: true,
    preserveImages: true,
    preserveOfficeElements: false,
    enableDebugLogging: true,
  );
  
  /// Create config for balanced cleaning (recommended default)
  factory HtmlCleaningConfig.balanced() => const HtmlCleaningConfig(
    level: HtmlCleaningLevel.balanced,
    preserveStyles: false,
    preserveImages: true,
    preserveOfficeElements: false,
    enableDebugLogging: true,
  );
  
  /// Create config for aggressive cleaning (current behavior)
  factory HtmlCleaningConfig.aggressive() => const HtmlCleaningConfig(
    level: HtmlCleaningLevel.aggressive,
    preserveStyles: false,
    preserveImages: true,
    preserveOfficeElements: false,
    enableDebugLogging: true,
  );
  
  String get description {
    switch (level) {
      case HtmlCleaningLevel.minimal:
        return 'Minimal cleaning - preserves most content, may have compatibility issues';
      case HtmlCleaningLevel.conservative:
        return 'Conservative cleaning - good content preservation with basic compatibility fixes';
      case HtmlCleaningLevel.balanced:
        return 'Balanced cleaning - recommended default with good compatibility and content preservation';
      case HtmlCleaningLevel.aggressive:
        return 'Aggressive cleaning - maximum compatibility, may remove some content';
    }
  }
}
