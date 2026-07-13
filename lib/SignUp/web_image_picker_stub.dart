/// Stub for non-web platforms — should never be called (guarded by kIsWeb).
Future<Map<String, dynamic>?> pickImageWebImpl({
  int maxBytes = 2 * 1024 * 1024,
}) async {
  return {'error': 'Web image picker is not available on this platform'};
}
