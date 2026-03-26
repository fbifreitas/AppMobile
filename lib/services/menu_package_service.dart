import 'package:flutter/services.dart' show rootBundle;

import '../models/menu_update_package.dart';

class MenuPackageService {
  Future<MenuUpdatePackage> loadFromAssets() async {
    final raw = await rootBundle.loadString(
      'assets/config/menu_update_package_v1.json',
    );
    return MenuUpdatePackage.fromRawJson(raw);
  }
}
