import 'package:cooli/config/app_config.dart';
import 'package:cooli/utils/enums.dart';

class UrlHelpers {
  static EnumBuildEnvironment get server => AppConfig.server;

  static String get baseURL {
    return 'http://coolie.pythonanywhere.com/api/';
  }

  static String get key {
    return 'coolie_api_key';
  }

  static String get baseUrlApi {
    return 'http://coolie.pythonanywhere.com/api/';
  }
}
