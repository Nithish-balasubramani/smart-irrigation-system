import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_data.dart';
import '../models/irrigation_settings.dart';

/// Service to handle Firebase Realtime Database operations
/// Manages sensor data fetching and pump control
class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _sensorDataSubscription;

  /// Stream for real-time sensor data updates
  Stream<SensorData> getSensorDataStream(String userId) {
    return _database.child('users/$userId/sensorData').onValue.map((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return SensorData.fromJson(data);
      } else {
        // Return default data if no data exists
        return _getDefaultSensorData();
      }
    });
  }

  /// Get sensor data once (not a stream)
  Future<SensorData> getSensorData(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId/sensorData').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return SensorData.fromJson(data);
      } else {
        return _getDefaultSensorData();
      }
    } catch (e) {
      print('Error fetching sensor data: $e');
      return _getDefaultSensorData();
    }
  }

  /// Update pump status in Firebase
  Future<bool> updatePumpStatus(String userId, bool status) async {
    try {
      await _database.child('users/$userId/sensorData/pumpStatus').set(status);

      // Also update timestamp
      await _database
          .child('users/$userId/sensorData/timestamp')
          .set(DateTime.now().toIso8601String());

      return true;
    } catch (e) {
      print('Error updating pump status: $e');
      return false;
    }
  }

  /// Save irrigation settings to Firebase
  Future<bool> saveSettings(String userId, IrrigationSettings settings) async {
    try {
      await _database.child('users/$userId/settings').set(settings.toJson());
      return true;
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }

  /// Get irrigation settings from Firebase
  Future<IrrigationSettings> getSettings(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId/settings').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return IrrigationSettings.fromJson(data);
      } else {
        return IrrigationSettings();
      }
    } catch (e) {
      print('Error fetching settings: $e');
      return IrrigationSettings();
    }
  }

  /// Get water usage statistics for a date range
  Future<List<Map<String, dynamic>>> getWaterUsageStats(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _database
          .child('users/$userId/waterUsageHistory')
          .orderByChild('timestamp')
          .startAt(startDate.toIso8601String())
          .endAt(endDate.toIso8601String())
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        return data.entries.map((entry) {
          return Map<String, dynamic>.from(entry.value as Map);
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching water usage stats: $e');
      return [];
    }
  }

  /// Log water usage to history
  Future<void> logWaterUsage(String userId, double amount) async {
    try {
      await _database.child('users/$userId/waterUsageHistory').push().set({
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging water usage: $e');
    }
  }

  /// Resolve a user node key from either direct key or email field.
  Future<String?> resolveUserId(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return null;

    try {
      final directSnapshot = await _database.child('users/$trimmed').get();
      if (directSnapshot.exists) {
        return trimmed;
      }

      final emailQuery = await _database
          .child('users')
          .orderByChild('email')
          .equalTo(trimmed)
          .limitToFirst(1)
          .get();

      if (emailQuery.exists && emailQuery.value is Map) {
        final map = Map<dynamic, dynamic>.from(emailQuery.value as Map);
        if (map.isNotEmpty) {
          return map.keys.first.toString();
        }
      }

      final usersSnapshot = await _database.child('users').get();
      if (usersSnapshot.exists && usersSnapshot.value is Map) {
        final usersMap = Map<dynamic, dynamic>.from(usersSnapshot.value as Map);
        final target = trimmed.toLowerCase();

        for (final entry in usersMap.entries) {
          final uid = entry.key.toString();
          final node = entry.value;
          if (node is! Map) continue;

          final userNode = Map<dynamic, dynamic>.from(node);
          final profileNode = userNode['profile'] is Map
              ? Map<dynamic, dynamic>.from(userNode['profile'] as Map)
              : <dynamic, dynamic>{};

          final candidates = <String>{
            uid,
            userNode['id']?.toString() ?? '',
            userNode['uid']?.toString() ?? '',
            userNode['userId']?.toString() ?? '',
            userNode['email']?.toString() ?? '',
            userNode['username']?.toString() ?? '',
            userNode['userName']?.toString() ?? '',
            profileNode['id']?.toString() ?? '',
            profileNode['uid']?.toString() ?? '',
            profileNode['email']?.toString() ?? '',
            profileNode['username']?.toString() ?? '',
            profileNode['userName']?.toString() ?? '',
          };

          final matched = candidates
              .where((value) => value.trim().isNotEmpty)
              .map((value) => value.trim().toLowerCase())
              .any((value) => value == target);

          if (matched) {
            return uid;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error resolving user id: $e');
      return null;
    }
  }

  /// Get user profile data (tries both nested profile and root user node).
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final profileSnapshot =
          await _database.child('users/$userId/profile').get();
      if (profileSnapshot.exists && profileSnapshot.value is Map) {
        final profile = Map<String, dynamic>.from(profileSnapshot.value as Map);
        return {
          ...profile,
          'name': _firstNonEmptyString([
            profile['name'],
            profile['fullName'],
            profile['farmerName'],
            profile['username'],
            profile['userName'],
          ]),
          'farm': _firstNonEmptyString([
            profile['farm'],
            profile['farmName'],
            profile['location'],
            profile['address'],
          ]),
        };
      }

      final userSnapshot = await _database.child('users/$userId').get();
      if (userSnapshot.exists && userSnapshot.value is Map) {
        final userMap = Map<String, dynamic>.from(userSnapshot.value as Map);

        if (userMap['profile'] is Map) {
          final profile = Map<String, dynamic>.from(userMap['profile'] as Map);
          return {
            ...profile,
            'name': _firstNonEmptyString([
              profile['name'],
              profile['fullName'],
              profile['farmerName'],
              profile['username'],
              profile['userName'],
              userMap['name'],
              userMap['fullName'],
              userMap['farmerName'],
            ]),
            'farm': _firstNonEmptyString([
              profile['farm'],
              profile['farmName'],
              profile['location'],
              profile['address'],
              userMap['farm'],
              userMap['farmName'],
              userMap['location'],
            ]),
          };
        }

        return {
          ...userMap,
          'name': _firstNonEmptyString([
            userMap['name'],
            userMap['fullName'],
            userMap['farmerName'],
            userMap['username'],
            userMap['userName'],
          ]),
          'farm': _firstNonEmptyString([
            userMap['farm'],
            userMap['farmName'],
            userMap['location'],
            userMap['address'],
          ]),
        };
      }

      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  /// Default sensor data for testing or when no data exists
  SensorData _getDefaultSensorData() {
    return SensorData(
      moistureLevel: 45.0,
      temperature: 28.5,
      humidity: 65.0,
      pumpStatus: false,
      waterUsage: 0.0,
      timestamp: DateTime.now(),
      status: 'normal',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FIRESTORE METHODS - Weather API Configuration
  // ═══════════════════════════════════════════════════════════

  /// Store weather API key in Firestore
  Future<bool> storeWeatherApiKey(String apiKey) async {
    try {
      await _firestore.collection('config').doc('weatherApi').set({
        'apiKey': apiKey,
        'provider': 'OpenWeatherMap',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('Weather API key stored successfully');
      return true;
    } catch (e) {
      print('Error storing weather API key: $e');
      return false;
    }
  }

  /// Get weather API key from Firestore
  Future<String?> getWeatherApiKey() async {
    try {
      final doc = await _firestore.collection('config').doc('weatherApi').get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['apiKey'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching weather API key: $e');
      return null;
    }
  }

  /// Get complete weather API configuration from Firestore
  Future<Map<String, dynamic>?> getWeatherApiConfig() async {
    try {
      final doc = await _firestore.collection('config').doc('weatherApi').get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching weather API config: $e');
      return null;
    }
  }

  /// Update weather API key in Firestore
  Future<bool> updateWeatherApiKey(String apiKey) async {
    try {
      await _firestore.collection('config').doc('weatherApi').update({
        'apiKey': apiKey,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('Weather API key updated successfully');
      return true;
    } catch (e) {
      print('Error updating weather API key: $e');
      return false;
    }
  }

  /// Clean up subscriptions
  void dispose() {
    _sensorDataSubscription?.cancel();
  }
}
