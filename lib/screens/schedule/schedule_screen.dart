import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════
// SCHEDULE DATA MODEL
// ═══════════════════════════════════════════════════════════
class IrrigationSchedule {
  final String id;
  final String label;
  final TimeOfDay startTime;
  final int durationMinutes;
  final List<bool> days; // Mon to Sun (7 days)
  bool isEnabled;

  IrrigationSchedule({
    required this.id,
    required this.label,
    required this.startTime,
    required this.durationMinutes,
    required this.days,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'durationMinutes': durationMinutes,
        'days': days,
        'isEnabled': isEnabled,
      };

  factory IrrigationSchedule.fromMap(Map<String, dynamic> map) =>
      IrrigationSchedule(
        id: map['id'] ?? '',
        label: map['label'] ?? 'Schedule',
        startTime: TimeOfDay(
            hour: map['startHour'] ?? 6, minute: map['startMinute'] ?? 0),
        durationMinutes: map['durationMinutes'] ?? 15,
        days: List<bool>.from(map['days'] ?? List.filled(7, false)),
        isEnabled: map['isEnabled'] ?? true,
      );
}

// ═══════════════════════════════════════════════════════════
// SCHEDULE SCREEN
// ═══════════════════════════════════════════════════════════
class ScheduleScreen extends StatefulWidget {
  final String language;

  const ScheduleScreen({super.key, this.language = 'en'});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<IrrigationSchedule> _schedules = [];
  bool _isLoading = true;
  String _userId = 'default_user';

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
  static const Color _cardGlass = Color(0x40FFFFFF);

  final List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _dayFullNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  bool get isTamil => widget.language == 'ta';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('activeUserIdentifier') ?? 'default_user';
    setState(() => _userId = id);
    await _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final doc =
          await _db.collection('schedules').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final list = (data['schedules'] as List<dynamic>? ?? [])
            .map((e) => IrrigationSchedule.fromMap(e as Map<String, dynamic>))
            .toList();
        setState(() => _schedules = list);
      } else {
        // Default sample schedules
        setState(() {
          _schedules = [
            IrrigationSchedule(
              id: '1',
              label: isTamil ? 'காலை நீர்ப்பாய்ச்சு' : 'Morning Irrigation',
              startTime: const TimeOfDay(hour: 6, minute: 0),
              durationMinutes: 20,
              days: [true, true, true, true, true, false, false],
              isEnabled: true,
            ),
            IrrigationSchedule(
              id: '2',
              label: isTamil ? 'மாலை நீர்ப்பாய்ச்சு' : 'Evening Irrigation',
              startTime: const TimeOfDay(hour: 18, minute: 30),
              durationMinutes: 15,
              days: [false, false, false, false, false, true, true],
              isEnabled: false,
            ),
          ];
        });
      }
    } catch (e) {
      // Use defaults on error
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSchedules() async {
    try {
      await _db.collection('schedules').doc(_userId).set({
        'schedules': _schedules.map((s) => s.toMap()).toList(),
        'updatedAt': DateTime.now(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTamil
              ? '✅ அட்டவணை சேமிக்கப்பட்டது!'
              : '✅ Schedules saved!'),
          backgroundColor: _primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error saving: $e'), backgroundColor: _red),
      );
    }
  }

  void _deleteSchedule(String id) {
    setState(() => _schedules.removeWhere((s) => s.id == id));
    _saveSchedules();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    final h12 = t.hour == 0
        ? 12
        : t.hour > 12
            ? t.hour - 12
            : t.hour;
    return '${h12.toString().padLeft(2, '0')}:$m $period';
  }

  String _activeDaysText(List<bool> days) {
    if (days.every((d) => d)) return isTamil ? 'தினமும்' : 'Every day';
    final active = <String>[];
    for (int i = 0; i < days.length; i++) {
      if (days[i]) active.add(_dayFullNames[i]);
    }
    return active.isEmpty ? (isTamil ? 'இல்லை' : 'None') : active.join(', ');
  }

  // ─── ADD / EDIT DIALOG ────────────────────────────────────
  void _showAddDialog({IrrigationSchedule? existing}) {
    final labelController = TextEditingController(
        text: existing?.label ??
            (isTamil ? 'புது அட்டவணை' : 'New Schedule'));
    TimeOfDay selectedTime =
        existing?.startTime ?? const TimeOfDay(hour: 6, minute: 0);
    int duration = existing?.durationMinutes ?? 20;
    List<bool> days = List<bool>.from(
        existing?.days ?? List.filled(7, false));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            existing != null
                ? (isTamil ? '✏️ திருத்து' : '✏️ Edit Schedule')
                : (isTamil ? '➕ புது அட்டவணை' : '➕ New Schedule'),
            style: const TextStyle(
                color: _text, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                _dialogLabel(isTamil ? 'பெயர்' : 'Label'),
                const SizedBox(height: 8),
                TextField(
                  controller: labelController,
                  style: const TextStyle(color: _text),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: const TextStyle(color: _textMuted),
                  ),
                ),
                const SizedBox(height: 20),

                // Time Picker
                _dialogLabel(
                    isTamil ? 'தொடக்க நேரம்' : 'Start Time'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: _primary,
                            onSurface: _text,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Text('🕐',
                            style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text(
                          _formatTime(selectedTime),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                            fontFamily: 'Courier',
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit,
                            color: _textMuted, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Duration
                _dialogLabel(
                    isTamil ? 'கால அளவு (நிமிடங்கள்)' : 'Duration (minutes)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (duration > 5) {
                          setDialogState(() => duration -= 5);
                        }
                      },
                      icon: const Icon(Icons.remove_circle,
                          color: _red, size: 30),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$duration min',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _text,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (duration < 120) {
                          setDialogState(() => duration += 5);
                        }
                      },
                      icon: const Icon(Icons.add_circle,
                          color: _primary, size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Days
                _dialogLabel(
                    isTamil ? 'நாட்கள்' : 'Repeat Days'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => days[i] = !days[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: days[i]
                              ? _primary.withValues(alpha: 0.2)
                              : _surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                days[i] ? _primary : _textMuted,
                            width: days[i] ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _dayLabels[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: days[i] ? _primary : _textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isTamil ? 'ரத்து' : 'Cancel',
                style: const TextStyle(color: _textMuted),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, Color(0xFF00C96A)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () {
                  final newSchedule = IrrigationSchedule(
                    id: existing?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    label: labelController.text.trim().isEmpty
                        ? (isTamil ? 'அட்டவணை' : 'Schedule')
                        : labelController.text.trim(),
                    startTime: selectedTime,
                    durationMinutes: duration,
                    days: days,
                    isEnabled: existing?.isEnabled ?? true,
                  );
                  setState(() {
                    if (existing != null) {
                      final idx = _schedules
                          .indexWhere((s) => s.id == existing.id);
                      if (idx >= 0) _schedules[idx] = newSchedule;
                    } else {
                      _schedules.add(newSchedule);
                    }
                  });
                  _saveSchedules();
                  Navigator.pop(context);
                },
                child: Text(
                  isTamil ? 'சேமி' : 'Save',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 12,
          color: _textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5),
    );
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
          isTamil ? '📅 நீர்ப்பாசன அட்டவணை' : '📅 Irrigation Schedule',
          style: const TextStyle(
              color: _text, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: _primary, size: 28),
            onPressed: () => _showAddDialog(),
            tooltip: isTamil ? 'புது அட்டவணை' : 'Add Schedule',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                // Header Info Card
                _buildInfoBanner(),

                Expanded(
                  child: _schedules.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _schedules.length,
                          itemBuilder: (context, index) =>
                              _buildScheduleCard(_schedules[index]),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: _primary,
        label: Text(
          isTamil ? 'புது அட்டவணை' : 'Add Schedule',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w800),
        ),
        icon: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildInfoBanner() {
    final activeCount = _schedules.where((s) => s.isEnabled).length;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary.withValues(alpha: 0.15),
            _blue.withValues(alpha: 0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('📅', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTamil
                      ? '$activeCount செயல்படும் அட்டவணை'
                      : '$activeCount Active Schedule${activeCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isTamil
                      ? 'தானியங்கி நீர்ப்பாசன நேர கட்டுப்பாடு'
                      : 'Auto irrigation time control',
                  style: const TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_schedules.length}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                  fontFamily: 'Courier',
                ),
              ),
              Text(
                isTamil ? 'மொத்தம்' : 'Total',
                style: const TextStyle(fontSize: 10, color: _textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(IrrigationSchedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: schedule.isEnabled
              ? _primary.withValues(alpha: 0.3)
              : _textMuted.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: schedule.isEnabled
                        ? _primary.withValues(alpha: 0.15)
                        : _textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    schedule.isEnabled ? '🌿' : '💤',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: schedule.isEnabled ? _text : _textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _activeDaysText(schedule.days),
                        style: const TextStyle(
                            fontSize: 11, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: schedule.isEnabled,
                  onChanged: (v) {
                    setState(() => schedule.isEnabled = v);
                    _saveSchedules();
                  },
                  activeColor: _primary,
                  activeTrackColor: _primary.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time & Duration Row
            Row(
              children: [
                _buildInfoChip(
                  '🕐 ${_formatTime(schedule.startTime)}',
                  schedule.isEnabled ? _primary : _textMuted,
                ),
                const SizedBox(width: 10),
                _buildInfoChip(
                  '⏱ ${schedule.durationMinutes} min',
                  schedule.isEnabled ? _blue : _textMuted,
                ),
                const Spacer(),
                // Edit
                IconButton(
                  onPressed: () => _showAddDialog(existing: schedule),
                  icon: const Icon(Icons.edit_outlined,
                      color: _textSecondary, size: 20),
                  tooltip: 'Edit',
                ),
                // Delete
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: _card,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: Text(
                          isTamil ? '🗑️ நீக்கவா?' : '🗑️ Delete?',
                          style: const TextStyle(color: _text),
                        ),
                        content: Text(
                          '"${schedule.label}" ${isTamil ? 'நீக்கப்படும்' : 'will be deleted'}',
                          style: const TextStyle(color: _textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(isTamil ? 'ரத்து' : 'Cancel',
                                style: const TextStyle(color: _textMuted)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteSchedule(schedule.id);
                            },
                            child: Text(isTamil ? 'நீக்கு' : 'Delete',
                                style: const TextStyle(
                                    color: _red,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: _red, size: 20),
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Days Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final active = schedule.days[i];
                return Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: active && schedule.isEnabled
                        ? _primary.withValues(alpha: 0.2)
                        : _surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active && schedule.isEnabled
                          ? _primary
                          : _textMuted.withValues(alpha: 0.3),
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: active && schedule.isEnabled
                            ? _primary
                            : _textMuted,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
          fontFamily: 'Courier',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(
            isTamil ? 'அட்டவணை இல்லை' : 'No Schedules Yet',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _text),
          ),
          const SizedBox(height: 8),
          Text(
            isTamil
                ? 'புது அட்டவணை சேர்க்க + பட்டனை அழுங்கு'
                : 'Tap + to add your first\nirrigation schedule',
            style: const TextStyle(color: _textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
