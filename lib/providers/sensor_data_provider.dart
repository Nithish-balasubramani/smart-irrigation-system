import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

/// Provider for managing sensor data and pump control
/// Handles real-time updates from Firebase and pump operations
class SensorDataProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  SensorData? _sensorData;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _sensorDataSubscription;
  bool _lowMoistureAlertEnabled = true;

  // Getters
  SensorData? get sensorData => _sensorData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPumpOn => _sensorData?.pumpStatus ?? false;

  /// Start listening to sensor data stream
  void startListening(String userId, double moistureThreshold) {
    _sensorDataSubscription?.cancel();

    _sensorDataSubscription =
        _firebaseService.getSensorDataStream(userId).listen(
      (data) async {
        _sensorData = data;
        await _checkAlerts(data);
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error fetching sensor data: $error';
        _notificationService.showSystemErrorNotification(_errorMessage!);
        notifyListeners();
      },
    );
  }

  /// Stop listening to sensor data
  void stopListening() {
    _sensorDataSubscription?.cancel();
  }

  /// Fetch sensor data once
  Future<void> fetchSensorData(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _sensorData = await _firebaseService.getSensorData(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching sensor data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle pump status
  Future<bool> togglePump(String userId) async {
    try {
      final newStatus = !isPumpOn;
      final success =
          await _firebaseService.updatePumpStatus(userId, newStatus);

      if (success) {
        // Show notification
        await _notificationService.showPumpStatusNotification(newStatus);

        // Update local state immediately for better UX
        if (_sensorData != null) {
          _sensorData = _sensorData!.copyWith(pumpStatus: newStatus);
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _errorMessage = 'Error toggling pump: $e';
      notifyListeners();
      return false;
    }
  }

  /// Turn pump ON
  Future<bool> turnPumpOn(String userId) async {
    if (isPumpOn) return true;
    return await togglePump(userId);
  }

  /// Turn pump OFF
  Future<bool> turnPumpOff(String userId) async {
    if (!isPumpOn) return true;
    return await togglePump(userId);
  }

  /// Check for alerts based on sensor data
  Future<void> _checkAlerts(SensorData data) async {
    await _notificationService.checkAndNotifyMoisture(
      data.moistureLevel,
      alertEnabled: _lowMoistureAlertEnabled,
    );

    // System error alert (example: sensor not responding)
    if (data.status == 'error') {
      await _notificationService.showSystemErrorNotification(
        'Sensor communication error detected',
      );
    }
  }

  /// Toggle low moisture alert from settings.
  void setLowMoistureAlertEnabled(bool value) {
    _lowMoistureAlertEnabled = value;
    notifyListeners();
  }

  /// Manual moisture check trigger.
  Future<void> checkMoistureNow() async {
    if (_sensorData == null) return;
    await _notificationService.checkAndNotifyMoisture(
      _sensorData!.moistureLevel,
      alertEnabled: _lowMoistureAlertEnabled,
    );
  }

  /// Simulate sensor data update (for testing without Firebase)
  void updateSimulatedData(SensorData data) {
    _sensorData = data;
    notifyListeners();
  }

  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    _firebaseService.dispose();
    super.dispose();
  }
}
