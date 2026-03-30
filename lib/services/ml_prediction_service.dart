import 'dart:convert';

import 'package:http/http.dart' as http;

class MlPredictionResult {
  final String prediction;
  final String motor;
  final bool fromApi;

  const MlPredictionResult({
    required this.prediction,
    required this.motor,
    required this.fromApi,
  });
}

class MlPredictionService {
  MlPredictionService._();

  static final MlPredictionService instance = MlPredictionService._();

  // For Android emulator use 10.0.2.2. For real device replace with your PC LAN IP.
  static const String _predictUrl = 'http://10.0.2.2:5000/predict';

  Future<MlPredictionResult> predict({
    required int moisture,
    required int temperature,
  }) async {
    final response = await http.post(
      Uri.parse(_predictUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'moisture': moisture,
        'temperature': temperature,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Prediction API failed with status ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    final prediction = _normalizePrediction(body['prediction']);
    final motor = (body['motor']?.toString() ?? 'OFF').toUpperCase();

    return MlPredictionResult(
      prediction: prediction,
      motor: motor,
      fromApi: true,
    );
  }

  String _normalizePrediction(dynamic value) {
    if (value is num) {
      return value == 1 ? 'High' : 'Low';
    }

    final text = (value?.toString() ?? '').trim();
    if (text.isEmpty) return 'Unknown';

    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}
