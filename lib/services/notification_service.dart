import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  // Handle background message
}

/// Service for handling local and push notifications
/// Shows alerts for low moisture, rain prediction, and system errors
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _lowMoistureId = 1001;
  static const int _pumpStatusId = 1002;
  static const int _systemErrorId = 1003;
  static const double lowMoistureThreshold = 40.0;
  static const Duration _lowMoistureAlertInterval = Duration(seconds: 1);

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final DatabaseReference _rootRef = FirebaseDatabase.instance.ref();

  bool _initialized = false;
  String? _fcmToken;
  StreamSubscription<DatabaseEvent>? _irrigationSubscription;
  String? _lastIrrigationStatus;
  Timer? _lowMoistureRepeatTimer;
  double? _latestLowMoistureLevel;

  /// Get FCM token for this device
  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestLocalNotificationPermissions();
    await _createNotificationChannels();

    // Initialize Firebase Messaging
    await _initializeFirebaseMessaging();

    _initialized = true;
  }

  /// Listen to users/{uid}/sensorData and show alert when status becomes LOW.
  void startIrrigationStatusListener([String? userId]) {
    _irrigationSubscription?.cancel();

    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      print('ℹ️ Skipping irrigation listener: user not authenticated');
      return;
    }

    final irrigationRef = _rootRef.child('users/$uid/sensorData');

    print('🔎 Listening for irrigation changes at /users/$uid/sensorData');

    _irrigationSubscription = irrigationRef.onValue.listen((event) {
      final raw = event.snapshot.value;
      if (raw == null) {
        print('ℹ️ /users/$uid/sensorData is empty');
        return;
      }

      if (raw is! Map) {
        print('⚠️ /users/$uid/sensorData value is not a map: $raw');
        return;
      }

      final data = Map<dynamic, dynamic>.from(raw);
      final status = (data['status']?.toString() ?? '').toUpperCase();
      print('📡 /irrigation update received, status=$status, data=$data');

      if (status == _lastIrrigationStatus) {
        return;
      }

      _lastIrrigationStatus = status;

      if (status == 'LOW') {
        showIrrigationAlert();
      }
    }, onError: (error) {
      print('❌ Irrigation listener error: $error');
    });
  }

  Future<void> _requestLocalNotificationPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _createNotificationChannels() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const channel = AndroidNotificationChannel(
      'channelId',
      'Soil Alert',
      description: 'Alerts when irrigation status is low',
      importance: Importance.high,
    );

    await android.createNotificationChannel(channel);
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else {
      print('❌ User declined notification permission');
      return;
    }

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('📱 FCM Token: $_fcmToken');
    // Backend integration point: persist this token server-side for push delivery.

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('🔄 FCM Token refreshed: $newToken');
      // Backend integration point: update token mapping when rotation occurs.
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      // Show local notification when app is in foreground
      await _showNotificationFromRemoteMessage(message);
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notification tapped: ${message.data}');
    // Navigate to specific screen based on message data
    if (message.data['type'] == 'moisture') {
      // Navigate to dashboard or moisture screen
    } else if (message.data['type'] == 'pump') {
      // Navigate to control screen
    }
  }

  /// Show notification from remote message
  Future<void> _showNotificationFromRemoteMessage(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'fcm_default_channel',
      'Push Notifications',
      channelDescription: 'Firebase Cloud Messaging notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      message.hashCode,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      details,
      payload: message.data['payload'],
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to specific screen if needed
    print('Notification tapped: ${response.payload}');
  }

  /// Check moisture on each sensor update and send only on threshold crossing.
  Future<void> checkAndNotifyMoisture(
    double moistureLevel, {
    bool alertEnabled = true,
  }) async {
    if (!alertEnabled) {
      _stopLowMoistureAlerts();
      return;
    }

    if (moistureLevel < lowMoistureThreshold) {
      _latestLowMoistureLevel = moistureLevel;

      if (_lowMoistureRepeatTimer == null) {
        await showLowMoistureAlert(moistureLevel);
        _lowMoistureRepeatTimer =
            Timer.periodic(_lowMoistureAlertInterval, (_) {
          final latest = _latestLowMoistureLevel;
          if (latest == null) return;
          showLowMoistureAlert(latest);
        });
      }
      return;
    }

    _stopLowMoistureAlerts();
  }

  void _stopLowMoistureAlerts() {
    _lowMoistureRepeatTimer?.cancel();
    _lowMoistureRepeatTimer = null;
    _latestLowMoistureLevel = null;
  }

  /// Show low moisture alert
  Future<void> showLowMoistureAlert(double moistureLevel) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'moisture_alerts',
      'Moisture Alerts',
      channelDescription: 'Notifications for low soil moisture levels',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _lowMoistureId,
      'Low Soil Moisture ⚠️',
      'Moisture level is at ${moistureLevel.toStringAsFixed(1)}%. Consider watering your plants.',
      details,
      payload: 'low_moisture',
    );
  }

  /// Show rain prediction alert
  Future<void> showRainPredictionAlert() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'weather_alerts',
      'Weather Alerts',
      channelDescription: 'Rain and weather notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2,
      'Rain Expected 🌧️',
      'Rain is predicted in your area. Irrigation may not be needed.',
      details,
      payload: 'rain_prediction',
    );
  }

  /// Show system error notification
  Future<void> showSystemError(String errorMessage) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'system_alerts',
      'System Alerts',
      channelDescription: 'Critical system errors and warnings',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _systemErrorId,
      'System Error ❌',
      errorMessage,
      details,
      payload: 'system_error',
    );
  }

  /// Compatibility wrapper used by providers.
  Future<void> showSystemErrorNotification(String errorMessage) {
    return showSystemError(errorMessage);
  }

  /// Show pump status notification
  Future<void> showPumpStatusNotification(bool isOn) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pump_alerts',
      'Pump Alerts',
      channelDescription: 'Pump on/off notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _pumpStatusId,
      isOn ? 'Pump Activated 💧' : 'Pump Deactivated',
      isOn ? 'Water pump is now running' : 'Water pump has been turned off',
      details,
      payload: 'pump_status',
    );
  }

  /// Show local notification for LOW irrigation status.
  Future<void> showIrrigationAlert() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channelId',
      'Soil Alert',
      channelDescription: 'Alerts when irrigation status is low',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails generalNotificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      10,
      '🚨 Irrigation Alert',
      'Soil moisture is low! Turn on watering.',
      generalNotificationDetails,
      payload: 'irrigation_low',
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Dispose active listeners when no longer needed.
  Future<void> dispose() async {
    await _irrigationSubscription?.cancel();
    _irrigationSubscription = null;
    _stopLowMoistureAlerts();
  }
}
