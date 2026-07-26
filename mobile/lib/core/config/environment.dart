abstract final class Environment {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const websocketBaseUrl = String.fromEnvironment(
    'WEBSOCKET_BASE_URL',
    defaultValue: 'ws://10.0.2.2:8080/ws',
  );
}