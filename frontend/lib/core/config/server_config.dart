/// Enum to define different server environments
enum ServerEnvironment { production, test }

/// Model to hold server configuration details
class _ServerDetails {
  final String baseUrl;

  const _ServerDetails({
    required this.baseUrl,
  });
}

/// Main configuration class for server settings
class ServerConfig {
  /// Current environment — change this one line to switch servers
  static const ServerEnvironment _environment = ServerEnvironment.production;
  // static const ServerEnvironment _environment = ServerEnvironment.production;

  /// Server configurations
  static const _testConfig = _ServerDetails(
    baseUrl: 'http://35.244.19.78:8000',
  );

  static const _prodConfig = _ServerDetails(
    baseUrl: 'http://34.127.125.215:8000',
  );

  /// Selected configuration based on environment
  static _ServerDetails get _activeConfig {
    switch (_environment) {
      case ServerEnvironment.production:
        return _prodConfig;
      case ServerEnvironment.test:
        return _testConfig;
    }
  }

  static String get baseUrl => _activeConfig.baseUrl;
}
