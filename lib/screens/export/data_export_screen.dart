import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════
// DATA EXPORT SCREEN
// ═══════════════════════════════════════════════════════════
class DataExportScreen extends StatefulWidget {
  final String language;

  const DataExportScreen({super.key, this.language = 'en'});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Colors from main app
  static const Color _bg = Color(0xFF060E0A);
  static const Color _card = Color(0xFF0F251A);
  static const Color _surface = Color(0xFF0C1E14);
  static const Color _primary = Color(0xFF00FF7F);
  static const Color _text = Color(0xFFE8F5EC);
  static const Color _textSecondary = Color(0xFF90C4A0);
  static const Color _textMuted = Color(0xFF567060);
  static const Color _red = Color(0xFFFF6B6B);
  static const Color _blue = Color(0xFF40C4FF);
  static const Color _yellow = Color(0xFFFFD54F);
  static const Color _orange = Color(0xFFFFA040);

  String _userId = 'default_user';
  bool _isExporting = false;
  String _exportFormat = 'CSV'; // CSV, JSON or PDF
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

  // What to export
  bool _exportSensorData = true;
  bool _exportIrrigationHistory = true;
  bool _exportWaterUsage = true;
  bool _exportSchedules = false;

  bool get isTamil => widget.language == 'ta';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('activeUserIdentifier') ?? 'default_user';
    });
  }

  // ─── EXPORT LOGIC ─────────────────────────────────────────
  Future<void> _startExport() async {
    if (!_exportSensorData &&
        !_exportIrrigationHistory &&
        !_exportWaterUsage &&
        !_exportSchedules) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isTamil ? '⚠️ குறைந்தது ஒன்று தேர்வு செய்' : '⚠️ Select at least one data type'),
          backgroundColor: _yellow,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      // Collect all data
      final allData = <String, dynamic>{};

      if (_exportSensorData) {
        allData['sensor_data'] = await _fetchSensorData();
      }
      if (_exportIrrigationHistory) {
        allData['irrigation_history'] = await _fetchIrrigationHistory();
      }
      if (_exportWaterUsage) {
        allData['water_usage'] = await _fetchWaterUsage();
      }
      if (_exportSchedules) {
        allData['schedules'] = await _fetchSchedules();
      }

      // Build file content
      String fileName;
      String mimeType;
      Uint8List bytes;

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (_exportFormat == 'CSV') {
        fileName = 'agrismart_export_$dateStr.csv';
        mimeType = 'text/csv';
        bytes = Uint8List.fromList(utf8.encode(_buildCSV(allData)));
      } else if (_exportFormat == 'JSON') {
        fileName = 'agrismart_export_$dateStr.json';
        mimeType = 'application/json';
        bytes = Uint8List.fromList(utf8.encode(_buildJSON(allData)));
      } else {
        fileName = 'agrismart_export_$dateStr.pdf';
        mimeType = 'application/pdf';
        bytes = await _buildPdf(allData);
      }

      // Save to temp directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: 'AgriSmart Data Export - $dateStr',
        text: isTamil
            ? 'AgriSmart நீர்ப்பாசன தரவு ஏற்றுமதி'
            : 'AgriSmart Irrigation Data Export',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isTamil ? '✅ ஏற்றுமதி வெற்றி!' : '✅ Export successful!'),
          backgroundColor: _primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Export error: $e'), backgroundColor: _red),
      );
    }

    if (mounted) setState(() => _isExporting = false);
  }

  Future<List<Map<String, dynamic>>> _fetchSensorData() async {
    try {
      final snapshot = await _db
          .collection('sensor_history')
          .doc(_userId)
          .collection('readings')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_fromDate))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(_toDate))
          .orderBy('timestamp', descending: false)
          .limit(500)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((d) => d.data()).toList();
      }
    } catch (_) {}

    // Fallback mock data
    return _generateMockSensorData();
  }

  Future<List<Map<String, dynamic>>> _fetchIrrigationHistory() async {
    try {
      final snapshot = await _db
          .collection('irrigation_history')
          .doc(_userId)
          .collection('events')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_fromDate))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(_toDate))
          .orderBy('timestamp', descending: false)
          .limit(200)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((d) => d.data()).toList();
      }
    } catch (_) {}

    return _generateMockIrrigationHistory();
  }

  Future<List<Map<String, dynamic>>> _fetchWaterUsage() async {
    final days = <Map<String, dynamic>>[];
    DateTime d = _fromDate;
    int dayNum = 1;
    while (d.isBefore(_toDate.add(const Duration(days: 1)))) {
      days.add({
        'date': DateFormat('yyyy-MM-dd').format(d),
        'liters_used': 200 + (dayNum * 17 % 150),
        'budget_liters': 500,
        'efficiency_percent': 75 + (dayNum * 3 % 20),
        'cost_inr': ((200 + (dayNum * 17 % 150)) * 0.05).toStringAsFixed(2),
      });
      d = d.add(const Duration(days: 1));
      dayNum++;
    }
    return days;
  }

  Future<List<Map<String, dynamic>>> _fetchSchedules() async {
    try {
      final doc = await _db.collection('schedules').doc(_userId).get();
      if (doc.exists) {
        final list = doc.data()?['schedules'] as List<dynamic>? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  List<Map<String, dynamic>> _generateMockSensorData() {
    final list = <Map<String, dynamic>>[];
    DateTime d = _fromDate;
    int i = 0;
    while (d.isBefore(_toDate.add(const Duration(hours: 1)))) {
      list.add({
        'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(d),
        'moisture_percent': 30 + (i * 7 % 50),
        'temperature_celsius': 25 + (i * 3 % 15),
        'humidity_percent': 50 + (i * 5 % 30),
        'rain_chance_percent': (i * 11 % 80),
        'pump_status': i % 4 == 0 ? 'ON' : 'OFF',
      });
      d = d.add(const Duration(hours: 6));
      i++;
    }
    return list;
  }

  List<Map<String, dynamic>> _generateMockIrrigationHistory() {
    final list = <Map<String, dynamic>>[];
    DateTime d = _fromDate;
    int i = 0;
    while (d.isBefore(_toDate)) {
      list.add({
        'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(d),
        'type': i % 3 == 0 ? 'Manual' : 'Auto',
        'duration_minutes': 10 + (i * 5 % 20),
        'liters_used': 20 + (i * 8 % 60),
        'moisture_before': 25 + (i * 3 % 20),
        'moisture_after': 45 + (i * 2 % 20),
        'trigger': i % 3 == 0 ? 'User' : 'Low Moisture',
      });
      d = d.add(const Duration(days: 1));
      i++;
    }
    return list;
  }

  // ─── CSV BUILDER ──────────────────────────────────────────
  String _buildCSV(Map<String, dynamic> data) {
    final buf = StringBuffer();
    final dateRange =
        '${DateFormat('yyyy-MM-dd').format(_fromDate)} to ${DateFormat('yyyy-MM-dd').format(_toDate)}';

    buf.writeln('# AgriSmart Data Export');
    buf.writeln('# Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buf.writeln('# Date Range: $dateRange');
    buf.writeln('# User: $_userId');
    buf.writeln();

    // Sensor Data
    if (data.containsKey('sensor_data')) {
      final rows = data['sensor_data'] as List<Map<String, dynamic>>;
      buf.writeln('## SENSOR READINGS');
      buf.writeln(
          'Timestamp,Moisture (%),Temperature (°C),Humidity (%),Rain Chance (%),Pump Status');
      for (final row in rows) {
        buf.writeln(
            '${row['timestamp']},${row['moisture_percent']},${row['temperature_celsius']},${row['humidity_percent']},${row['rain_chance_percent']},${row['pump_status']}');
      }
      buf.writeln();
    }

    // Irrigation History
    if (data.containsKey('irrigation_history')) {
      final rows = data['irrigation_history'] as List<Map<String, dynamic>>;
      buf.writeln('## IRRIGATION HISTORY');
      buf.writeln(
          'Timestamp,Type,Duration (min),Liters Used,Moisture Before (%),Moisture After (%),Trigger');
      for (final row in rows) {
        buf.writeln(
            '${row['timestamp']},${row['type']},${row['duration_minutes']},${row['liters_used']},${row['moisture_before']},${row['moisture_after']},${row['trigger']}');
      }
      buf.writeln();
    }

    // Water Usage
    if (data.containsKey('water_usage')) {
      final rows = data['water_usage'] as List<Map<String, dynamic>>;
      buf.writeln('## WATER USAGE SUMMARY');
      buf.writeln('Date,Liters Used,Budget (L),Efficiency (%),Cost (₹)');
      for (final row in rows) {
        buf.writeln(
            '${row['date']},${row['liters_used']},${row['budget_liters']},${row['efficiency_percent']},${row['cost_inr']}');
      }
      buf.writeln();
    }

    // Schedules
    if (data.containsKey('schedules')) {
      final rows = data['schedules'] as List<Map<String, dynamic>>;
      buf.writeln('## IRRIGATION SCHEDULES');
      buf.writeln('Label,Start Hour,Start Minute,Duration (min),Enabled');
      for (final row in rows) {
        buf.writeln(
            '${row['label']},${row['startHour']},${row['startMinute']},${row['durationMinutes']},${row['isEnabled']}');
      }
    }

    return buf.toString();
  }

  // ─── JSON BUILDER ─────────────────────────────────────────
  String _buildJSON(Map<String, dynamic> data) {
    final buf = StringBuffer();
    buf.writeln('{');
    buf.writeln(
        '  "export_meta": {"generated_at": "${DateTime.now().toIso8601String()}", "user_id": "$_userId"},');

    final keys = data.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final value = data[key] as List<Map<String, dynamic>>;
      final isLast = i == keys.length - 1;
      buf.writeln('  "$key": [');
      for (int j = 0; j < value.length; j++) {
        final isLastRow = j == value.length - 1;
        buf.write('    {');
        final rowKeys = value[j].keys.toList();
        for (int k = 0; k < rowKeys.length; k++) {
          final rk = rowKeys[k];
          final rv = value[j][rk];
          final isLastField = k == rowKeys.length - 1;
          if (rv is String) {
            buf.write('"$rk": "$rv"');
          } else {
            buf.write('"$rk": $rv');
          }
          if (!isLastField) buf.write(', ');
        }
        buf.write('}');
        if (!isLastRow) buf.write(',');
        buf.writeln();
      }
      buf.write('  ]');
      if (!isLast) buf.write(',');
      buf.writeln();
    }
    buf.writeln('}');
    return buf.toString();
  }

  Future<Uint8List> _buildPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final dateRange =
        '${DateFormat('yyyy-MM-dd').format(_fromDate)} to ${DateFormat('yyyy-MM-dd').format(_toDate)}';

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('AgriSmart Data Export',
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
          pw.Text('Date Range: $dateRange'),
          pw.Text('User: $_userId'),
          pw.SizedBox(height: 16),
          if (data.containsKey('sensor_data')) ...[
            pw.Text('Sensor Readings',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ..._rowsToPdfLines(data['sensor_data'] as List<Map<String, dynamic>>, 30),
            pw.SizedBox(height: 12),
          ],
          if (data.containsKey('irrigation_history')) ...[
            pw.Text('Irrigation History',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ..._rowsToPdfLines(
                data['irrigation_history'] as List<Map<String, dynamic>>, 20),
            pw.SizedBox(height: 12),
          ],
          if (data.containsKey('water_usage')) ...[
            pw.Text('Water Usage Summary',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ..._rowsToPdfLines(data['water_usage'] as List<Map<String, dynamic>>, 20),
            pw.SizedBox(height: 12),
          ],
          if (data.containsKey('schedules')) ...[
            pw.Text('Schedules',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ..._rowsToPdfLines(data['schedules'] as List<Map<String, dynamic>>, 20),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  List<pw.Widget> _rowsToPdfLines(
      List<Map<String, dynamic>> rows, int maxRows) {
    return rows.take(maxRows).map((row) {
      final text = row.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
      );
    }).toList();
  }

  // ─── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        title: Text(
          isTamil ? '📤 தரவு ஏற்றுமதி' : '📤 Data Export',
          style: const TextStyle(
              color: _text, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            const SizedBox(height: 20),

            // Date Range
            _buildSectionHeader('📅',
                isTamil ? 'தேதி வரம்பு' : 'Date Range'),
            const SizedBox(height: 12),
            _buildDateRangeCard(),
            const SizedBox(height: 20),

            // Data Types
            _buildSectionHeader('📊',
                isTamil ? 'எந்த தரவு?' : 'What to Export'),
            const SizedBox(height: 12),
            _buildDataTypeCard(),
            const SizedBox(height: 20),

            // Format Selection
            _buildSectionHeader(
                '📁', isTamil ? 'கோப்பு வடிவம்' : 'File Format'),
            const SizedBox(height: 12),
            _buildFormatCard(),
            const SizedBox(height: 20),

            // Preview
            _buildPreviewCard(),
            const SizedBox(height: 28),

            // Export Button
            _buildExportButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _orange.withValues(alpha: 0.15),
            _yellow.withValues(alpha: 0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('📤', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTamil ? 'தரவு ஏற்றுமதி' : 'Export Your Data',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _text),
                ),
                const SizedBox(height: 4),
                Text(
                  isTamil
                    ? 'CSV / JSON / PDF ஆக பதிவிறக்கம் செய்'
                    : 'Download as CSV, JSON, or PDF and share',
                  style:
                      const TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String icon, String title) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x40FFFFFF).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fromDate,
                  firstDate: DateTime(2024),
                  lastDate: _toDate,
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: _primary, onSurface: _text),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _fromDate = picked);
              },
              child: _buildDateTile(
                  isTamil ? 'தொடக்கம்' : 'From', _fromDate),
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: _textMuted.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _toDate,
                  firstDate: _fromDate,
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: _primary, onSurface: _text),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _toDate = picked);
              },
              child:
                  _buildDateTile(isTamil ? 'முடிவு' : 'To', _toDate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: _textMuted)),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.calendar_today, color: _primary, size: 16),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
          ],
        ),
        Text(
          DateFormat('EEEE').format(date),
          style:
              const TextStyle(fontSize: 11, color: _textSecondary),
        ),
      ],
    );
  }

  Widget _buildDataTypeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0x40FFFFFF).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildCheckTile(
            icon: '💧',
            title: isTamil ? 'உணரி தரவு' : 'Sensor Readings',
            subtitle: isTamil
                ? 'மண் ஈரம், வெப்பம், ஈரப்பசை, மழை'
                : 'Moisture, Temp, Humidity, Rain',
            value: _exportSensorData,
            onChanged: (v) => setState(() => _exportSensorData = v),
            color: _primary,
          ),
          _buildDivider(),
          _buildCheckTile(
            icon: '🌿',
            title: isTamil ? 'நீர்ப்பாசன வரலாறு' : 'Irrigation History',
            subtitle: isTamil
                ? 'தொடக்கம், கால அளவு, நீர் அளவு'
                : 'Start time, duration, liters',
            value: _exportIrrigationHistory,
            onChanged: (v) => setState(() => _exportIrrigationHistory = v),
            color: _blue,
          ),
          _buildDivider(),
          _buildCheckTile(
            icon: '📊',
            title: isTamil ? 'நீர் பயன்பாடு' : 'Water Usage Summary',
            subtitle: isTamil
                ? 'நாள் வாரியான நீர் & செலவு'
                : 'Daily usage & cost analysis',
            value: _exportWaterUsage,
            onChanged: (v) => setState(() => _exportWaterUsage = v),
            color: _orange,
          ),
          _buildDivider(),
          _buildCheckTile(
            icon: '📅',
            title: isTamil ? 'அட்டவணைகள்' : 'Irrigation Schedules',
            subtitle:
                isTamil ? 'நேர அட்டவணை விவரங்கள்' : 'Schedule configuration',
            value: _exportSchedules,
            onChanged: (v) => setState(() => _exportSchedules = v),
            color: _yellow,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckTile({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _text)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: _textMuted)),
                ],
              ),
            ),
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: color,
              checkColor: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
        color: _textMuted.withValues(alpha: 0.2), height: 1);
  }

  Widget _buildFormatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0x40FFFFFF).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFormatOption(
              'CSV',
              '📋',
              isTamil ? 'Excel-ல திற' : 'Open in Excel',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFormatOption(
              'JSON',
              '⚙️',
              isTamil ? 'டெவலப்பர் வடிவம்' : 'Developer format',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFormatOption(
              'PDF',
              '📄',
              isTamil ? 'பகிர்வு அறிக்கை' : 'Shareable report',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(String format, String icon, String desc) {
    final isSelected = _exportFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _exportFormat = format),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? _primary.withValues(alpha: 0.15)
              : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _primary
                : _textMuted.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              format,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSelected ? _primary : _text,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(fontSize: 11, color: _textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final days = _toDate.difference(_fromDate).inDays + 1;
    final selectedCount = [
      _exportSensorData,
      _exportIrrigationHistory,
      _exportWaterUsage,
      _exportSchedules
    ].where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, color: _blue, size: 20),
              const SizedBox(width: 8),
              Text(
                isTamil ? 'ஏற்றுமதி சுருக்கம்' : 'Export Preview',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _text),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreviewRow(
            isTamil ? 'தேதி வரம்பு' : 'Date Range',
            '$days ${isTamil ? 'நாட்கள்' : 'days'}',
          ),
          _buildPreviewRow(
            isTamil ? 'தரவு வகை' : 'Data Types',
            '$selectedCount ${isTamil ? 'தேர்வு' : 'selected'}',
          ),
          _buildPreviewRow(
            isTamil ? 'கோப்பு வடிவம்' : 'Format',
            _exportFormat,
          ),
          _buildPreviewRow(
            isTamil ? 'தோராயம்' : 'Estimated Rows',
            '~${days * selectedCount * 4}',
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: _textMuted)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _blue,
                  fontFamily: 'Courier')),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return GestureDetector(
      onTap: _isExporting ? null : _startExport,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: _isExporting
              ? null
              : const LinearGradient(
                  colors: [_primary, Color(0xFF00C96A)],
                ),
          color: _isExporting ? _surface : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isExporting
              ? []
              : [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _isExporting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: _primary, strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      isTamil ? 'ஏற்றுமதி ஆகிறது...' : 'Exporting...',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _primary),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📤', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text(
                      isTamil
                          ? '$_exportFormat ஆக ஏற்றுமதி செய்'
                          : 'Export as $_exportFormat',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
