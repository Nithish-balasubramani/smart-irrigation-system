import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/ml_prediction_service.dart';

class IrrigationScreen extends StatelessWidget {
  const IrrigationScreen({super.key});

  String predictWaterNeed(int moisture, int temperature) {
    if (moisture < 30 || temperature > 35) {
      return 'High';
    }
    if (moisture < 60) {
      return 'Medium';
    }
    return 'Low';
  }

  String getMotorStatus(int moisture) {
    return moisture < 30 ? 'ON' : 'OFF';
  }

  MlPredictionResult _fallbackPrediction(int moisture, int temperature) {
    return MlPredictionResult(
      prediction: predictWaterNeed(moisture, temperature),
      motor: getMotorStatus(moisture),
      fromApi: false,
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Irrigation System'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('irrigation_data')
            .doc('sensor1')
            .snapshots(),
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

          return FutureBuilder<MlPredictionResult>(
            future: MlPredictionService.instance.predict(
              moisture: moisture,
              temperature: temperature,
            ),
            builder: (context, predictionSnapshot) {
              final result = predictionSnapshot.data ??
                  _fallbackPrediction(moisture, temperature);

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 5,
                      child: ListTile(
                        leading:
                            const Icon(Icons.water_drop, color: Colors.blue),
                        title: const Text('Soil Moisture'),
                        subtitle: Text('$moisture %'),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      elevation: 5,
                      child: ListTile(
                        leading:
                            const Icon(Icons.thermostat, color: Colors.red),
                        title: const Text('Temperature'),
                        subtitle: Text('$temperature C'),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      elevation: 5,
                      child: ListTile(
                        leading:
                            const Icon(Icons.analytics, color: Colors.green),
                        title: const Text('Water Need (ML Prediction)'),
                        subtitle: Text(
                          result.fromApi
                              ? result.prediction
                              : '${result.prediction} (fallback)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      elevation: 5,
                      child: ListTile(
                        leading: const Icon(Icons.power, color: Colors.orange),
                        title: const Text('Motor Status'),
                        subtitle: Text(result.motor),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
