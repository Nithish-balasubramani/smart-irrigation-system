import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';

/// Offline Mode Detection Service
/// Detects WiFi, Firebase, and sensor connectivity status
class OfflineModeService {
  static final OfflineModeService _instance = OfflineModeService._internal();
  factory OfflineModeService() => _instance;
  OfflineModeService._internal();

  // System modes
  static const String online = 'ONLINE';
  static const String wifiOffline = 'WIFI_OFFLINE';
  static const String fbOffline = 'FB_OFFLINE';
  static const String sensorFail = 'SENSOR_FAIL';

  // Current system mode
  String _currentMode = online;
  String get currentMode => _currentMode;

  // Connectivity status
  bool _isWiFiConnected = true;
  bool _isFirebaseConnected = true;
  bool _isSensorHealthy = true;

  // Stream controllers
  final _modeController = StreamController<String>.broadcast();
  Stream<String> get modeStream => _modeController.stream;

  // Connectivity subscription
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _firebaseSubscription;

  /// Initialize the offline detection service
  Future<void> initialize() async {
    // Monitor WiFi connectivity
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      _checkWiFiStatus(
          results.isEmpty ? ConnectivityResult.none : results.first);
    });

    // Monitor Firebase connectivity
    _monitorFirebaseConnection();

    // Initial check
    await _performInitialCheck();
  }

  /// Perform initial connectivity check
  Future<void> _performInitialCheck() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    _checkWiFiStatus(connectivityResults.isEmpty
        ? ConnectivityResult.none
        : connectivityResults.first);
  }

  /// Check WiFi status
  void _checkWiFiStatus(ConnectivityResult result) {
    final wasConnected = _isWiFiConnected;
    _isWiFiConnected = result != ConnectivityResult.none;

    if (wasConnected != _isWiFiConnected) {
      print(
          '📶 WiFi Status Changed: ${_isWiFiConnected ? "Connected" : "Disconnected"}');
      _updateSystemMode();
    }
  }

  /// Monitor Firebase connection
  void _monitorFirebaseConnection() {
    try {
      final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
      _firebaseSubscription = connectedRef.onValue.listen((event) {
        final snapshot = event.snapshot;
        final wasConnected = _isFirebaseConnected;
        _isFirebaseConnected = snapshot.value == true;

        if (wasConnected != _isFirebaseConnected) {
          print(
              '☁️ Firebase Status Changed: ${_isFirebaseConnected ? "Connected" : "Disconnected"}');
          _updateSystemMode();
        }
      });
    } catch (e) {
      print('❌ Error monitoring Firebase: $e');
      _isFirebaseConnected = false;
      _updateSystemMode();
    }
  }

  /// Update system mode based on connectivity
  void _updateSystemMode() {
    final previousMode = _currentMode;

    if (!_isWiFiConnected) {
      _currentMode = wifiOffline;
    } else if (!_isFirebaseConnected) {
      _currentMode = fbOffline;
    } else if (!_isSensorHealthy) {
      _currentMode = sensorFail;
    } else {
      _currentMode = online;
    }

    if (previousMode != _currentMode) {
      print('🔄 System Mode Changed: $previousMode → $_currentMode');
      _modeController.add(_currentMode);
    }
  }

  /// Check sensor health (call this when sensor data is invalid)
  void setSensorHealth(bool isHealthy) {
    if (_isSensorHealthy != isHealthy) {
      _isSensorHealthy = isHealthy;
      print('🌡️ Sensor Health: ${isHealthy ? "OK" : "FAIL"}');
      _updateSystemMode();
    }
  }

  /// Get connectivity status
  Map<String, bool> getConnectivityStatus() {
    return {
      'wifi': _isWiFiConnected,
      'firebase': _isFirebaseConnected,
      'sensor': _isSensorHealthy,
    };
  }

  /// Check if system is online
  bool get isOnline => _currentMode == online;

  /// Check if system is in any offline mode
  bool get isOffline => _currentMode != online;

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _firebaseSubscription?.cancel();
    _modeController.close();
  }
}
