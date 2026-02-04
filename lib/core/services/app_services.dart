import 'image_blocking_service.dart';
import 'image_allowlist_service.dart';
import 'html_cleaning_config_service.dart';

/// Global service instances for app-wide state management
class AppServices {
  static final ImageBlockingService _imageBlockingService = ImageBlockingService();
  static final ImageAllowlistService _imageAllowlistService = ImageAllowlistService();
  static final HtmlCleaningConfigService _htmlCleaningConfigService = HtmlCleaningConfigService();

  static ImageBlockingService get imageBlockingService => _imageBlockingService;
  static ImageAllowlistService get imageAllowlistService => _imageAllowlistService;
  static HtmlCleaningConfigService get htmlCleaningConfigService => _htmlCleaningConfigService;

  // Prevent instantiation
  AppServices._();
}
