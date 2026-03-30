import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/firebase_service.dart';
import '../services/ml_prediction_service.dart';
import '../services/notification_service.dart';
import 'ai/explainable_ai_screen.dart';
import 'analytics/analytics_screen.dart';
import 'export/data_export_screen.dart';
import 'schedule/schedule_screen.dart';
import 'water_budget/water_budget_screen.dart';
import 'zones_screen.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isDarkMode = true;
  String _language = 'en';
  String? _fcmToken;
  String _weatherSummary = '-';
  int _rainChance = 0;
  final List<FlSpot> _historyMoisture = <FlSpot>[];
  double _chartIndex = 0;

  static const Map<String, Map<String, String>> _tr = {
    'en': {
      'title': 'Smart Irrigation Hub',
      'moisture': 'Soil Moisture',
      'temperature': 'Temperature',
      'prediction': 'Water Need (ML)',
      'motor': 'Motor Status',
      'weather': 'Weather (Rain Prediction)',
      'history': 'Historical Moisture',
      'tools': 'Feature Tools',
      'quickSchedule': 'Quick Schedule',
      'addSchedule': 'Add Schedule',
      'zones': 'Multi-zone Support',
      'fcm': 'Push Notifications (FCM)',
      'tokenReady': 'FCM token ready',
      'tokenMissing': 'FCM token not available yet',
      'darkMode': 'Dark Mode',
      'language': 'Language',
      'saved': 'Saved successfully',
    },
    'ta': {
      'title': 'நுண்ணறிவு நீர்ப்பாசன மையம்',
      'moisture': 'மண் ஈரப்பதம்',
      'temperature': 'வெப்பநிலை',
      'prediction': 'நீர் தேவைக் கணிப்பு (ML)',
      'motor': 'மோட்டார் நிலை',
      'weather': 'வானிலை (மழை கணிப்பு)',
      'history': 'கடந்த ஈரப்பத வரலாறு',
      'tools': 'அம்ச கருவிகள்',
      'quickSchedule': 'விரைவு அட்டவணை',
      'addSchedule': 'அட்டவணை சேர்',
      'zones': 'பல பகுதி ஆதரவு',
      'fcm': 'அறிவிப்புகள் (FCM)',
      'tokenReady': 'FCM டோக்கன் தயார்',
      'tokenMissing': 'FCM டோக்கன் இன்னும் இல்லை',
      'darkMode': 'இரவு தோற்றம்',
      'language': 'மொழி',
      'saved': 'வெற்றிகரமாக சேமிக்கப்பட்டது',
    },
    'hi': {
      'title': 'स्मार्ट सिंचाई हब',
      'moisture': 'मिट्टी नमी',
      'temperature': 'तापमान',
      'prediction': 'पानी आवश्यकता (ML)',
      'motor': 'मोटर स्थिति',
      'weather': 'मौसम (बारिश पूर्वानुमान)',
      'history': 'नमी का पुराना डेटा',
      'tools': 'फ़ीचर टूल्स',
      'quickSchedule': 'त्वरित शेड्यूल',
      'addSchedule': 'शेड्यूल जोड़ें',
      'zones': 'मल्टी-ज़ोन सपोर्ट',
      'fcm': 'पुश नोटिफिकेशन (FCM)',
      'tokenReady': 'FCM टोकन उपलब्ध',
      'tokenMissing': 'FCM टोकन अभी उपलब्ध नहीं',
      'darkMode': 'डार्क मोड',
      'language': 'भाषा',
      'saved': 'सफलतापूर्वक सेव किया गया',
    },
  };

  String t(String key) => _tr[_language]?[key] ?? _tr['en']![key] ?? key;

  @override
  void initState() {
    super.initState();
    _initializeScreenState();
  }

  Future<void> _initializeScreenState() async {
    await NotificationService().initialize();
    setState(() => _fcmToken = NotificationService().fcmToken);
    await _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final apiKey = await FirebaseService().getWeatherApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        if (mounted) {
          setState(() {
            _weatherSummary = 'API key missing';
            _rainChance = 0;
          });
        }
        return;
      }

      final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=Chennai&appid=$apiKey&units=metric',
      );
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Weather request failed');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final weather = (body['weather'] as List<dynamic>? ?? <dynamic>[])
          .firstWhere((_) => true, orElse: () => <String, dynamic>{});
      final description = weather is Map<String, dynamic>
          ? (weather['description']?.toString() ?? 'clear')
          : 'clear';
      final clouds = (body['clouds'] as Map<String, dynamic>? ?? {})['all'];
      final cloudPercent = clouds is num ? clouds.toInt() : 0;

      if (mounted) {
        setState(() {
          _weatherSummary = description;
          _rainChance = cloudPercent;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _weatherSummary = 'Unavailable';
          _rainChance = 0;
        });
      }
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  String _predictWaterNeed(int moisture, int temperature) {
    if (moisture < 30 || temperature > 35) return 'High';
    if (moisture < 60) return 'Medium';
    return 'Low';
  }

  String _motorStatusForMoisture(int moisture) => moisture < 30 ? 'ON' : 'OFF';

  MlPredictionResult _fallbackPrediction(int moisture, int temperature) {
    return MlPredictionResult(
      prediction: _predictWaterNeed(moisture, temperature),
      motor: _motorStatusForMoisture(moisture),
      fromApi: false,
    );
  }

  void _appendHistoryPoint(int moisture) {
    if (_historyMoisture.length > 60) {
      _historyMoisture.removeAt(0);
    }
    _historyMoisture.add(FlSpot(_chartIndex, moisture.toDouble()));
    _chartIndex += 1;
  }

  Future<void> _addQuickSchedule() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
    );
    if (picked == null) return;

    final payload = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'label': 'Quick ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
      'startHour': picked.hour,
      'startMinute': picked.minute,
      'durationMinutes': 20,
      'days': List<bool>.filled(7, true),
      'isEnabled': true,
    };

    await _firestore.collection('schedules').doc('default_user').set(
      {
        'schedules': FieldValue.arrayUnion([payload]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('saved'))),
    );
  }

  Future<void> _subscribeAlerts() async {
    await FirebaseMessaging.instance.subscribeToTopic('weather_alerts');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscribed to weather_alerts')),
    );
  }

  Future<void> _unsubscribeAlerts() async {
    await FirebaseMessaging.instance.unsubscribeFromTopic('weather_alerts');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unsubscribed from weather_alerts')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDarkMode ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('title')),
          actions: [
            IconButton(
              tooltip: t('darkMode'),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              icon: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.language),
              onSelected: (value) => setState(() => _language = value),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'en', child: Text('English')),
                PopupMenuItem(value: 'ta', child: Text('Tamil')),
                PopupMenuItem(value: 'hi', child: Text('Hindi')),
              ],
            ),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('irrigation_data').doc('sensor1').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading data'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() ?? <String, dynamic>{};
            final moisture = _toInt(data['moisture']);
            final temperature = _toInt(data['temperature']);
            _appendHistoryPoint(moisture);

            return FutureBuilder<MlPredictionResult>(
              future: MlPredictionService.instance.predict(
                moisture: moisture,
                temperature: temperature,
              ),
              builder: (context, predictionSnapshot) {
                final result = predictionSnapshot.data ?? _fallbackPrediction(moisture, temperature);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sensorTile(Icons.water_drop, t('moisture'), '$moisture %'),
                    const SizedBox(height: 10),
                    _sensorTile(Icons.thermostat, t('temperature'), '$temperature C'),
                    const SizedBox(height: 10),
                    _sensorTile(
                      Icons.psychology,
                      t('prediction'),
                      result.fromApi ? result.prediction : '${result.prediction} (fallback)',
                    ),
                    const SizedBox(height: 10),
                    _sensorTile(Icons.power, t('motor'), result.motor),
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.cloud),
                        title: Text(t('weather')),
                        subtitle: Text('$_weatherSummary • Rain chance $_rainChance%'),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadWeather,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('history'), style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 180,
                              child: LineChart(
                                LineChartData(
                                  minY: 0,
                                  maxY: 100,
                                  lineBarsData: [
                                    LineChartBarData(
                                      isCurved: true,
                                      spots: _historyMoisture,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: false),
                                    ),
                                  ],
                                  titlesData: const FlTitlesData(
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('quickSchedule'), style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _addQuickSchedule,
                              icon: const Icon(Icons.schedule),
                              label: Text(t('addSchedule')),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.notifications_active),
                        title: Text(t('fcm')),
                        subtitle: Text(_fcmToken == null ? t('tokenMissing') : t('tokenReady')),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(onPressed: _subscribeAlerts, child: const Text('On')),
                            OutlinedButton(onPressed: _unsubscribeAlerts, child: const Text('Off')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(t('tools'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _toolButton(context, 'Schedule', const ScheduleScreen()),
                        _toolButton(context, t('zones'), ZonesScreen(language: _language)),
                        _toolButton(context, 'Analytics', const AnalyticsScreen()),
                        _toolButton(context, 'Water Budget', const WaterBudgetScreen()),
                        _toolButton(context, 'Explainable AI', const ExplainableAIScreen()),
                        _toolButton(context, 'Export CSV/PDF', DataExportScreen(language: _language)),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _sensorTile(IconData icon, String title, String value) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Widget _toolButton(BuildContext context, String text, Widget screen) {
    return FilledButton.tonal(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Text(text),
    );
  }
}
