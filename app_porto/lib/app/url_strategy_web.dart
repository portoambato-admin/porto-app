import 'package:flutter_web_plugins/url_strategy.dart';

void setAppUrlStrategy() {
  // Quita el # de las URLs en Flutter Web
  usePathUrlStrategy();
}
