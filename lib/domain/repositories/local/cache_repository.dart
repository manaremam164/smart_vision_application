abstract class ICacheRepository {
  Future<String?> get(String key);
  Future<bool> set(String key, String value);
  Future<bool> remove(String key);
  Future<bool> contains(String key);
}
