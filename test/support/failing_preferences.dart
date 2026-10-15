import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class FailingPreferences extends InMemorySharedPreferencesStore {
  FailingPreferences() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}
