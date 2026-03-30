import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;
import '../main.dart';

// ═══════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════

class IrrigationZone {
  final String id;
  String name;
  String cropType;
  double areaAcres;
  bool pumpOn;
  double moisture;
  double temperature;
  double soilThreshold;
  bool autoIrrigation;
  String status;
  String groupId;
  List<ZoneSchedule> schedules;
  List<double> moistureHistory; // last 7 readings
  int totalLitersToday;
  DateTime? lastIrrigated;

  IrrigationZone({
    required this.id,
    required this.name,
    required this.cropType,
    this.areaAcres = 2.0,
    this.pumpOn = false,
    this.moisture = 45.0,
    this.temperature = 28.0,
    this.soilThreshold = 40.0,
    this.autoIrrigation = true,
    this.status = 'idle',
    this.groupId = 'default',
    List<ZoneSchedule>? schedules,
    List<double>? moistureHistory,
    this.totalLitersToday = 0,
    this.lastIrrigated,
  })  : schedules = schedules ?? [],
        moistureHistory = moistureHistory ?? [45, 42, 38, 50, 55, 48, 45];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cropType': cropType,
        'areaAcres': areaAcres,
        'pumpOn': pumpOn,
        'moisture': moisture,
        'temperature': temperature,
        'soilThreshold': soilThreshold,
        'autoIrrigation': autoIrrigation,
        'status': status,
        'groupId': groupId,
        'schedules': schedules.map((s) => s.toJson()).toList(),
        'moistureHistory': moistureHistory,
        'totalLitersToday': totalLitersToday,
        'lastIrrigated': lastIrrigated?.toIso8601String(),
      };

  factory IrrigationZone.fromJson(Map<String, dynamic> json) => IrrigationZone(
        id: json['id'] ?? '',
        name: json['name'] ?? 'Zone',
        cropType: json['cropType'] ?? 'Wheat',
        areaAcres: (json['areaAcres'] ?? 2.0).toDouble(),
        pumpOn: json['pumpOn'] ?? false,
        moisture: (json['moisture'] ?? 45.0).toDouble(),
        temperature: (json['temperature'] ?? 28.0).toDouble(),
        soilThreshold: (json['soilThreshold'] ?? 40.0).toDouble(),
        autoIrrigation: json['autoIrrigation'] ?? true,
        status: json['status'] ?? 'idle',
        groupId: json['groupId'] ?? 'default',
        schedules: (json['schedules'] as List? ?? [])
            .map((s) => ZoneSchedule.fromJson(Map<String, dynamic>.from(s)))
            .toList(),
        moistureHistory:
            (json['moistureHistory'] as List? ?? [45, 42, 38, 50, 55, 48, 45])
                .map((v) => (v as num).toDouble())
                .toList(),
        totalLitersToday: json['totalLitersToday'] ?? 0,
        lastIrrigated: json['lastIrrigated'] != null
            ? DateTime.tryParse(json['lastIrrigated'])
            : null,
      );
}

class ZoneSchedule {
  String id;
  String time; // "06:30"
  List<bool> days; // Mon-Sun
  bool enabled;
  int durationMinutes;

  ZoneSchedule({
    required this.id,
    required this.time,
    required this.days,
    this.enabled = true,
    this.durationMinutes = 20,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'days': days,
        'enabled': enabled,
        'durationMinutes': durationMinutes,
      };

  factory ZoneSchedule.fromJson(Map<String, dynamic> json) => ZoneSchedule(
        id: json['id'] ?? '',
        time: json['time'] ?? '06:00',
        days: (json['days'] as List? ?? List.filled(7, false))
            .map((d) => d as bool)
            .toList(),
        enabled: json['enabled'] ?? true,
        durationMinutes: json['durationMinutes'] ?? 20,
      );
}

class ZoneGroup {
  final String id;
  String name;
  String icon;
  List<String> zoneIds;

  ZoneGroup({
    required this.id,
    required this.name,
    required this.icon,
    this.zoneIds = const [],
  });
}

// ═══════════════════════════════════════════════════════════
// MAIN ZONES SCREEN
// ═══════════════════════════════════════════════════════════
class ZonesScreen extends StatefulWidget {
  final String language;
  const ZonesScreen({super.key, required this.language});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<IrrigationZone> _zones = [];
  List<ZoneGroup> _groups = [];
  bool _isLoading = true;
  String _userIdentifier = '';
  Timer? _refreshTimer;
  String _viewMode = 'grid'; // grid or list

  bool get isTamil => widget.language == 'ta';

  final List<String> _cropOptions = [
    'Wheat',
    'Rice',
    'Corn',
    'Cotton',
    'Sugarcane',
    'Tomato',
    'Onion',
    'Potato',
    'Groundnut',
    'Millet'
  ];
  final Map<String, String> _cropIcons = {
    'Wheat': '🌾',
    'Rice': '🍚',
    'Corn': '🌽',
    'Cotton': '☁️',
    'Sugarcane': '🎋',
    'Tomato': '🍅',
    'Onion': '🧅',
    'Potato': '🥔',
    'Groundnut': '🥜',
    'Millet': '🌿',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initGroups();
    _loadZones();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _simulateLiveData(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _initGroups() {
    _groups = [
      ZoneGroup(
          id: 'default',
          name: isTamil ? 'அனைத்தும்' : 'All Zones',
          icon: '🗺️'),
      ZoneGroup(
          id: 'north', name: isTamil ? 'வடக்கு' : 'North Farm', icon: '⬆️'),
      ZoneGroup(
          id: 'south', name: isTamil ? 'தெற்கு' : 'South Farm', icon: '⬇️'),
      ZoneGroup(
          id: 'green',
          name: isTamil ? 'கிரீன்ஹவுஸ்' : 'Greenhouse',
          icon: '🏠'),
    ];
  }

  Future<void> _loadZones() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _userIdentifier = prefs.getString('activeUserIdentifier') ?? '';

    try {
      if (_userIdentifier.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userIdentifier)
            .collection('zones')
            .get();
        if (snap.docs.isNotEmpty) {
          setState(() {
            _zones = snap.docs
                .map((d) => IrrigationZone.fromJson(d.data()))
                .toList();
          });
          setState(() => _isLoading = false);
          return;
        }
      }
    } catch (_) {}

    _loadDefaultZones();
    setState(() => _isLoading = false);
  }

  void _loadDefaultZones() {
    _zones = [
      IrrigationZone(
        id: 'zone_1',
        name: isTamil ? 'வடக்கு வயல் - 1' : 'North Field - 1',
        cropType: 'Wheat',
        areaAcres: 3.5,
        moisture: 32.0,
        temperature: 31.0,
        soilThreshold: 40.0,
        pumpOn: false,
        status: 'warning',
        groupId: 'north',
        moistureHistory: [55, 50, 44, 38, 35, 33, 32],
        totalLitersToday: 0,
        schedules: [
          ZoneSchedule(
            id: 's1',
            time: '06:00',
            days: [true, false, true, false, true, false, false],
            durationMinutes: 25,
          ),
        ],
      ),
      IrrigationZone(
        id: 'zone_2',
        name: isTamil ? 'வடக்கு வயல் - 2' : 'North Field - 2',
        cropType: 'Rice',
        areaAcres: 2.0,
        moisture: 68.0,
        temperature: 29.0,
        soilThreshold: 50.0,
        pumpOn: true,
        status: 'active',
        groupId: 'north',
        moistureHistory: [60, 55, 62, 70, 65, 69, 68],
        totalLitersToday: 84,
        lastIrrigated: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      IrrigationZone(
        id: 'zone_3',
        name: isTamil ? 'தெற்கு வயல்' : 'South Field',
        cropType: 'Cotton',
        areaAcres: 4.0,
        moisture: 45.0,
        temperature: 33.0,
        soilThreshold: 35.0,
        pumpOn: false,
        status: 'idle',
        groupId: 'south',
        moistureHistory: [42, 44, 47, 43, 46, 44, 45],
        totalLitersToday: 120,
        lastIrrigated: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      IrrigationZone(
        id: 'zone_4',
        name: isTamil ? 'கிரீன்ஹவுஸ்' : 'Greenhouse',
        cropType: 'Tomato',
        areaAcres: 0.8,
        moisture: 72.0,
        temperature: 26.0,
        soilThreshold: 55.0,
        pumpOn: false,
        status: 'idle',
        groupId: 'green',
        moistureHistory: [65, 70, 68, 75, 72, 74, 72],
        totalLitersToday: 45,
        lastIrrigated: DateTime.now().subtract(const Duration(hours: 1)),
        schedules: [
          ZoneSchedule(
            id: 's2',
            time: '07:30',
            days: [true, true, true, true, true, true, true],
            durationMinutes: 15,
          ),
          ZoneSchedule(
            id: 's3',
            time: '17:00',
            days: [true, true, true, true, true, true, true],
            durationMinutes: 10,
          ),
        ],
      ),
      IrrigationZone(
        id: 'zone_5',
        name: isTamil ? 'தெற்கு தோட்டம்' : 'South Garden',
        cropType: 'Onion',
        areaAcres: 1.5,
        moisture: 28.0,
        temperature: 34.0,
        soilThreshold: 40.0,
        pumpOn: false,
        status: 'warning',
        groupId: 'south',
        moistureHistory: [45, 40, 36, 32, 30, 29, 28],
        totalLitersToday: 0,
      ),
    ];
  }

  void _simulateLiveData() {
    if (!mounted) return;
    final rng = math.Random();
    setState(() {
      for (final z in _zones) {
        z.moisture =
            (z.moisture + (rng.nextDouble() - 0.5) * 2).clamp(10.0, 95.0);
        z.temperature =
            (z.temperature + (rng.nextDouble() - 0.4) * 0.5).clamp(18.0, 45.0);
        if (z.pumpOn) {
          z.moisture = (z.moisture + 0.8).clamp(10.0, 95.0);
          z.totalLitersToday += rng.nextInt(3);
        }
        z.status = z.pumpOn
            ? 'active'
            : z.moisture < z.soilThreshold
                ? 'warning'
                : 'idle';
      }
    });
  }

  Future<void> _saveZone(IrrigationZone zone) async {
    if (_userIdentifier.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userIdentifier)
          .collection('zones')
          .doc(zone.id)
          .set(zone.toJson());
    } catch (_) {}
  }

  Future<void> _deleteZone(String zoneId) async {
    if (_userIdentifier.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userIdentifier)
          .collection('zones')
          .doc(zoneId)
          .delete();
    } catch (_) {}
  }

  void _togglePump(IrrigationZone zone) {
    setState(() {
      zone.pumpOn = !zone.pumpOn;
      zone.status = zone.pumpOn ? 'active' : 'idle';
      if (zone.pumpOn) zone.lastIrrigated = DateTime.now();
    });
    _saveZone(zone);
    FirebaseFirestore.instance.collection('irrigation_data').doc(zone.id).set({
      'motor': zone.pumpOn ? 'ON' : 'OFF',
      'zoneName': zone.name,
      'time': DateTime.now(),
    }, SetOptions(merge: true)).catchError((_) {});
  }

  void _toggleAllPumps(bool on) {
    setState(() {
      for (final z in _zones) {
        z.pumpOn = on;
        z.status = on ? 'active' : 'idle';
        if (on) z.lastIrrigated = DateTime.now();
      }
    });
    for (final z in _zones) {
      _saveZone(z);
    }
    _showSnack(
      on
          ? (isTamil ? '🟢 அனைத்து பம்புகள் தொடங்கின' : '🟢 All pumps started')
          : (isTamil
              ? '🔴 அனைத்து பம்புகள் நிறுத்தப்பட்டன'
              : '🔴 All pumps stopped'),
      isSuccess: on,
    );
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? AppColors.primary : AppColors.red,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDashboardTab(),
                        _buildZonesTab(),
                        _buildScheduleTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    final activeCount = _zones.where((z) => z.pumpOn).length;
    final warnCount = _zones.where((z) => z.status == 'warning').length;
    final totalLiters = _zones.fold(0, (s, z) => s + z.totalLitersToday);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: AppColors.cardGlass.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.cardGlass.withValues(alpha: 0.3)),
                  ),
                  child: const Text('←',
                      style: TextStyle(fontSize: 16, color: AppColors.text)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTamil
                          ? '🗺️ பல பகுதி மேலாண்மை'
                          : '🗺️ Multi-Zone Management',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      isTamil
                          ? '${_zones.length} பகுதிகள் · $activeCount இயங்கும்'
                          : '${_zones.length} zones · $activeCount active',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(
                    () => _viewMode = _viewMode == 'grid' ? 'list' : 'grid'),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _viewMode == 'grid' ? '☰' : '⊞',
                    style:
                        const TextStyle(fontSize: 16, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip('${_zones.length}', isTamil ? 'மொத்தம்' : 'Total',
                  AppColors.blue),
              const SizedBox(width: 8),
              _statChip('$activeCount', isTamil ? 'இயங்கும்' : 'Active',
                  AppColors.primary),
              const SizedBox(width: 8),
              _statChip('$warnCount', isTamil ? 'எச்சரிக்கை' : 'Warning',
                  AppColors.orange),
              const SizedBox(width: 8),
              _statChip('${totalLiters}L', isTamil ? 'இன்று' : 'Today',
                  AppColors.purple),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  isTamil ? '🟢 அனைத்தும் ON' : '🟢 All ON',
                  AppColors.primary,
                  filled: true,
                  onTap: () => _toggleAllPumps(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionBtn(
                  isTamil ? '🔴 அனைத்தும் OFF' : '🔴 All OFF',
                  AppColors.red,
                  onTap: () => _toggleAllPumps(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String val, String lbl, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(val,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: 'Courier')),
            Text(lbl,
                style:
                    const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color,
      {bool filled = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: filled ? AppColors.gradient1 : null,
          color: filled ? null : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border:
              filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: filled ? AppColors.bg : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.card.withValues(alpha: 0.7),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        tabs: [
          Tab(text: isTamil ? '📊 டாஷ்போர்டு' : '📊 Dashboard'),
          Tab(text: isTamil ? '🗺️ பகுதிகள்' : '🗺️ Zones'),
          Tab(text: isTamil ? '⏰ அட்டவணை' : '⏰ Schedule'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    final active = _zones.where((z) => z.pumpOn).toList();
    final warning = _zones.where((z) => z.status == 'warning').toList();
    final idle = _zones.where((z) => z.status == 'idle').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(isTamil ? '📍 குழு சுருக்கம்' : '📍 Group Overview'),
          const SizedBox(height: 8),
          _buildGroupOverview(),
          const SizedBox(height: 20),
          if (active.isNotEmpty) ...[
            _sectionTitle(isTamil
                ? '🟢 இயங்கும் பகுதிகள் (${active.length})'
                : '🟢 Active Zones (${active.length})'),
            const SizedBox(height: 8),
            ...active.map((z) => _buildDashboardZoneCard(z)),
            const SizedBox(height: 16),
          ],
          if (warning.isNotEmpty) ...[
            _sectionTitle(isTamil
                ? '⚠️ கவனம் தேவை (${warning.length})'
                : '⚠️ Needs Attention (${warning.length})'),
            const SizedBox(height: 8),
            ...warning.map((z) => _buildDashboardZoneCard(z)),
            const SizedBox(height: 16),
          ],
          if (idle.isNotEmpty) ...[
            _sectionTitle(isTamil
                ? '😴 நிறுத்தம் (${idle.length})'
                : '😴 Idle (${idle.length})'),
            const SizedBox(height: 8),
            ...idle.map((z) => _buildDashboardZoneCard(z)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildGroupOverview() {
    final realGroups = _groups.where((g) => g.id != 'default').toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: realGroups.length,
      itemBuilder: (_, i) {
        final g = realGroups[i];
        final zones = _zones.where((z) => z.groupId == g.id).toList();
        final active = zones.where((z) => z.pumpOn).length;
        final warn = zones.where((z) => z.status == 'warning').length;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.cardGlass.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(g.icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(g.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 4),
              Text(
                '${zones.length} zones',
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
              if (active > 0)
                Text('$active active',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.primary)),
              if (warn > 0)
                Text('$warn dry',
                    style:
                        const TextStyle(fontSize: 10, color: AppColors.orange)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardZoneCard(IrrigationZone zone) {
    final statusColor = zone.pumpOn
        ? AppColors.primary
        : zone.status == 'warning'
            ? AppColors.orange
            : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: zone.pumpOn
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.cardGlass.withValues(alpha: 0.2),
          width: zone.pumpOn ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: zone.moisture / 100,
                  backgroundColor: AppColors.surface.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    zone.moisture < zone.soilThreshold
                        ? AppColors.orange
                        : AppColors.primary,
                  ),
                  strokeWidth: 4,
                ),
                Text(
                  _cropIcons[zone.cropType] ?? '🌱',
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '💧${zone.moisture.toInt()}% · 🌡️${zone.temperature.toInt()}°C',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                _buildSparkline(zone.moistureHistory, zone.soilThreshold),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  zone.pumpOn
                      ? (isTamil ? 'ON' : 'ON')
                      : zone.status == 'warning'
                          ? (isTamil ? 'வறண்டது' : 'Dry')
                          : (isTamil ? 'சரி' : 'OK'),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _togglePump(zone),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: zone.pumpOn
                        ? AppColors.red.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: zone.pumpOn
                          ? AppColors.red.withValues(alpha: 0.4)
                          : AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      zone.pumpOn ? '⏹' : '▶',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSparkline(List<double> data, double threshold) {
    if (data.isEmpty) return const SizedBox.shrink();
    final max = data.reduce(math.max);
    final min = data.reduce(math.min);
    final range = (max - min).clamp(1.0, 100.0);

    return SizedBox(
      height: 22,
      child: CustomPaint(
        size: const Size(double.infinity, 22),
        painter: _SparklinePainter(data, threshold, min, range),
      ),
    );
  }

  Widget _buildZonesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGroupFilter(),
          const SizedBox(height: 12),
          _viewMode == 'grid' ? _buildZonesGrid() : _buildZonesList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _selectedGroupFilter = 'default';

  Widget _buildGroupFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _groups.map((g) {
          final isSelected = _selectedGroupFilter == g.id;
          final count = g.id == 'default'
              ? _zones.length
              : _zones.where((z) => z.groupId == g.id).length;
          return GestureDetector(
            onTap: () => setState(() => _selectedGroupFilter = g.id),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardGlass.withValues(alpha: 0.2),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(g.icon, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    '${g.name} ($count)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<IrrigationZone> get _filteredZones {
    if (_selectedGroupFilter == 'default') return _zones;
    return _zones.where((z) => z.groupId == _selectedGroupFilter).toList();
  }

  Widget _buildZonesGrid() {
    final zones = _filteredZones;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: zones.length,
      itemBuilder: (_, i) => _buildZoneGridCard(zones[i]),
    );
  }

  Widget _buildZoneGridCard(IrrigationZone zone) {
    final statusColor = zone.pumpOn
        ? AppColors.primary
        : zone.status == 'warning'
            ? AppColors.orange
            : AppColors.textMuted;

    return GestureDetector(
      onLongPress: () => _showZoneOptions(zone),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: zone.pumpOn
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.cardGlass.withValues(alpha: 0.2),
            width: zone.pumpOn ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_cropIcons[zone.cropType] ?? '🌱',
                    style: const TextStyle(fontSize: 22)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    zone.pumpOn
                        ? 'ON'
                        : zone.status == 'warning'
                            ? (isTamil ? 'வறண்டது' : 'Dry')
                            : 'OK',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(zone.name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              '${zone.cropType} · ${zone.areaAcres}ac',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 11)),
                    Text('${zone.moisture.toInt()}%',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontFamily: 'Courier')),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: zone.moisture / 100,
                    backgroundColor: AppColors.surface.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      zone.moisture < zone.soilThreshold
                          ? AppColors.orange
                          : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _togglePump(zone),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: zone.pumpOn ? null : AppColors.gradient1,
                  color: zone.pumpOn
                      ? AppColors.red.withValues(alpha: 0.15)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: zone.pumpOn
                      ? Border.all(color: AppColors.red.withValues(alpha: 0.4))
                      : null,
                ),
                child: Center(
                  child: Text(
                    zone.pumpOn
                        ? (isTamil ? '⏹ நிறுத்து' : '⏹ Stop')
                        : (isTamil ? '▶ தொடங்கு' : '▶ Start'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: zone.pumpOn ? AppColors.red : AppColors.bg,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonesList() {
    final zones = _filteredZones;
    return Column(
      children: zones.map((z) => _buildZoneListCard(z)).toList(),
    );
  }

  Widget _buildZoneListCard(IrrigationZone zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: zone.pumpOn
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.cardGlass.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(_cropIcons[zone.cropType] ?? '🌱',
              style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text)),
                Text(
                  '${zone.cropType} · ${zone.areaAcres}ac · 💧${zone.moisture.toInt()}% · 🌡️${zone.temperature.toInt()}°C',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                if (zone.totalLitersToday > 0)
                  Text(
                    '${isTamil ? "இன்று" : "Today"}: ${zone.totalLitersToday}L',
                    style: const TextStyle(fontSize: 10, color: AppColors.blue),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _showZoneOptions(zone),
                child: const Text('⋮',
                    style: TextStyle(fontSize: 20, color: AppColors.textMuted)),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _togglePump(zone),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: zone.pumpOn ? null : AppColors.gradient1,
                    color: zone.pumpOn
                        ? AppColors.red.withValues(alpha: 0.15)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: zone.pumpOn
                        ? Border.all(
                            color: AppColors.red.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Text(
                    zone.pumpOn ? '⏹' : '▶',
                    style: TextStyle(
                        fontSize: 14,
                        color: zone.pumpOn ? AppColors.red : AppColors.bg),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showZoneOptions(IrrigationZone zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ZoneOptionsSheet(
        zone: zone,
        groups: _groups,
        isTamil: isTamil,
        cropOptions: _cropOptions,
        cropIcons: _cropIcons,
        onSave: (updated) {
          setState(() {
            final idx = _zones.indexWhere((z) => z.id == updated.id);
            if (idx != -1) _zones[idx] = updated;
          });
          _saveZone(updated);
          _showSnack(
            isTamil ? '✅ பகுதி புதுப்பிக்கப்பட்டது' : '✅ Zone updated',
            isSuccess: true,
          );
        },
        onDelete: () {
          setState(() => _zones.removeWhere((z) => z.id == zone.id));
          _deleteZone(zone.id);
          _showSnack(
            isTamil ? '🗑️ பகுதி நீக்கப்பட்டது' : '🗑️ Zone deleted',
          );
        },
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
              isTamil ? '⏰ அனைத்து பகுதி அட்டவணைகள்' : '⏰ All Zone Schedules'),
          const SizedBox(height: 12),
          ..._zones.map((z) => _buildZoneScheduleCard(z)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildZoneScheduleCard(IrrigationZone zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardGlass.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(_cropIcons[zone.cropType] ?? '🌱',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(zone.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                ),
                GestureDetector(
                  onTap: () => _showAddScheduleDialog(zone),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isTamil ? '+ சேர்' : '+ Add',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (zone.schedules.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isTamil
                        ? 'அட்டவணை இல்லை — + சேர் அழுத்தவும்'
                        : 'No schedule — tap + Add',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ),
            )
          else
            ...zone.schedules.map((s) => _buildScheduleRow(zone, s)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Widget _buildScheduleRow(IrrigationZone zone, ZoneSchedule sched) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sched.enabled
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sched.enabled
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.cardGlass.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '⏰ ${sched.time}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            fontFamily: 'Courier'),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${sched.durationMinutes} min',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(7, (i) {
                      final active = sched.days[i];
                      return Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary.withValues(alpha: 0.25)
                              : AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active
                                ? AppColors.primary
                                : AppColors.cardGlass.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _dayLabels[i],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: sched.enabled,
                  onChanged: (v) {
                    setState(() => sched.enabled = v);
                    _saveZone(zone);
                  },
                  activeThumbColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => zone.schedules.remove(sched));
                    _saveZone(zone);
                  },
                  child: const Text('🗑️', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleDialog(IrrigationZone zone) {
    TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 0);
    final durationCtrl = TextEditingController(text: '20');
    final days = List.filled(7, false);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isTamil ? '⏰ அட்டவணை சேர்' : '⏰ Add Schedule',
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                  );
                  if (t != null) setD(() => selectedTime = t);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('⏰', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(
                        selectedTime.format(ctx),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontFamily: 'Courier'),
                      ),
                      const Spacer(),
                      const Text('tap to change',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.cardGlass.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('⏱', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: durationCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: isTamil ? 'நிமிடங்கள்' : 'Duration (min)',
                          hintStyle: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Days',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  return GestureDetector(
                    onTap: () => setD(() => days[i] = !days[i]),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: days[i]
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: days[i]
                              ? AppColors.primary
                              : AppColors.cardGlass.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _dayLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: days[i]
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isTamil ? 'ரத்து' : 'Cancel',
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
            GestureDetector(
              onTap: () {
                final h = selectedTime.hour.toString().padLeft(2, '0');
                final m = selectedTime.minute.toString().padLeft(2, '0');
                final sched = ZoneSchedule(
                  id: 'sched_${DateTime.now().millisecondsSinceEpoch}',
                  time: '$h:$m',
                  days: List.from(days),
                  durationMinutes: int.tryParse(durationCtrl.text) ?? 20,
                );
                setState(() => zone.schedules.add(sched));
                _saveZone(zone);
                Navigator.pop(ctx);
                _showSnack(
                  isTamil ? '✅ அட்டவணை சேர்க்கப்பட்டது' : '✅ Schedule added',
                  isSuccess: true,
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient1,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isTamil ? 'சேர்' : 'Add',
                  style: const TextStyle(
                      color: AppColors.bg, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _showAddZoneDialog,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.gradient1,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(child: Text('➕', style: TextStyle(fontSize: 22))),
      ),
    );
  }

  void _showAddZoneDialog() {
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: '2.0');
    String selectedCrop = 'Wheat';
    String selectedGroup = _groups[1].id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Text('➕', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                isTamil ? 'புதிய பகுதி' : 'New Zone',
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, isTamil ? 'பகுதி பெயர்' : 'Zone Name',
                    isTamil ? 'எ.கா: வடக்கு வயல்' : 'e.g. North Field', '📍'),
                const SizedBox(height: 12),
                _dialogField(areaCtrl,
                    isTamil ? 'பரப்பு (ஏக்கர்)' : 'Area (Acres)', '2.0', '📐',
                    isNumeric: true),
                const SizedBox(height: 12),
                _dialogDropdown(
                  label: isTamil ? 'பயிர் வகை' : 'Crop Type',
                  value: selectedCrop,
                  items: _cropOptions,
                  onChanged: (v) => setD(() => selectedCrop = v!),
                  icon: _cropIcons,
                ),
                const SizedBox(height: 12),
                _dialogDropdown(
                  label: isTamil ? 'குழு' : 'Group',
                  value: selectedGroup,
                  items: _groups
                      .where((g) => g.id != 'default')
                      .map((g) => g.id)
                      .toList(),
                  displayNames: {
                    for (final g in _groups) g.id: '${g.icon} ${g.name}'
                  },
                  onChanged: (v) => setD(() => selectedGroup = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isTamil ? 'ரத்து' : 'Cancel',
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
            GestureDetector(
              onTap: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final z = IrrigationZone(
                  id: 'zone_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  cropType: selectedCrop,
                  areaAcres: double.tryParse(areaCtrl.text) ?? 2.0,
                  groupId: selectedGroup,
                );
                setState(() => _zones.add(z));
                _saveZone(z);
                Navigator.pop(ctx);
                _showSnack(
                  isTamil ? '✅ பகுதி சேர்க்கப்பட்டது' : '✅ Zone added!',
                  isSuccess: true,
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient1,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(isTamil ? 'சேர்' : 'Add',
                    style: const TextStyle(
                        color: AppColors.bg, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: .4));

  Widget _dialogField(
      TextEditingController ctrl, String label, String hint, String icon,
      {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.cardGlass.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(icon, style: const TextStyle(fontSize: 18))),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: isNumeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dialogDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    Map<String, String>? icon,
    Map<String, String>? displayNames,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.cardGlass.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.card,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              items: items
                  .map((i) => DropdownMenuItem(
                        value: i,
                        child: Row(children: [
                          if (icon != null)
                            Text(icon[i] ?? '🌱',
                                style: const TextStyle(fontSize: 16)),
                          if (icon != null) const SizedBox(width: 8),
                          Text(displayNames?[i] ?? i),
                        ]),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoneOptionsSheet extends StatefulWidget {
  final IrrigationZone zone;
  final List<ZoneGroup> groups;
  final bool isTamil;
  final List<String> cropOptions;
  final Map<String, String> cropIcons;
  final Function(IrrigationZone) onSave;
  final VoidCallback onDelete;

  const _ZoneOptionsSheet({
    required this.zone,
    required this.groups,
    required this.isTamil,
    required this.cropOptions,
    required this.cropIcons,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_ZoneOptionsSheet> createState() => _ZoneOptionsSheetState();
}

class _ZoneOptionsSheetState extends State<_ZoneOptionsSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _areaCtrl;
  late String _selectedCrop;
  late String _selectedGroup;
  late double _threshold;
  late bool _autoIrr;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.zone.name);
    _areaCtrl = TextEditingController(text: widget.zone.areaAcres.toString());
    _selectedCrop = widget.zone.cropType;
    _selectedGroup = widget.zone.groupId;
    _threshold = widget.zone.soilThreshold;
    _autoIrr = widget.zone.autoIrrigation;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardGlass,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isTamil ? '✏️ பகுதி திருத்து' : '✏️ Edit Zone',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text),
            ),
            const SizedBox(height: 16),
            _field(
                _nameCtrl, widget.isTamil ? 'பகுதி பெயர்' : 'Zone Name', '📍'),
            const SizedBox(height: 12),
            _field(_areaCtrl,
                widget.isTamil ? 'பரப்பு (ஏக்கர்)' : 'Area (Acres)', '📐',
                isNumeric: true),
            const SizedBox(height: 12),
            _dropdown(
              label: widget.isTamil ? 'பயிர் வகை' : 'Crop Type',
              value: _selectedCrop,
              items: widget.cropOptions,
              icons: widget.cropIcons,
              onChanged: (v) => setState(() => _selectedCrop = v!),
            ),
            const SizedBox(height: 12),
            _dropdown(
              label: widget.isTamil ? 'குழு' : 'Group',
              value: _selectedGroup,
              items: widget.groups
                  .where((g) => g.id != 'default')
                  .map((g) => g.id)
                  .toList(),
              displayNames: {
                for (final g in widget.groups) g.id: '${g.icon} ${g.name}'
              },
              onChanged: (v) => setState(() => _selectedGroup = v!),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.isTamil ? 'மண் வரம்பு' : 'Soil Threshold',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                Text('${_threshold.toInt()}%',
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Courier')),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surface,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _threshold,
                min: 10,
                max: 80,
                onChanged: (v) => setState(() => _threshold = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    widget.isTamil
                        ? 'தானியங்கி நீர்ப்பாய்ச்சு'
                        : 'Auto Irrigation',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                Switch(
                  value: _autoIrr,
                  onChanged: (v) => setState(() => _autoIrr = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.card,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: Text(
                              widget.isTamil ? '🗑️ நீக்கவா?' : '🗑️ Delete?',
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w700)),
                          content: Text(
                              widget.isTamil
                                  ? '"${widget.zone.name}" நீக்கப்படும்'
                                  : '"${widget.zone.name}" will be deleted.',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(widget.isTamil ? 'ரத்து' : 'Cancel',
                                  style: const TextStyle(
                                      color: AppColors.textMuted)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                                widget.onDelete();
                              },
                              child: const Text('Delete',
                                  style: TextStyle(color: AppColors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                            widget.isTamil ? '🗑️ நீக்கு' : '🗑️ Delete',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.red)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      widget.zone.name = _nameCtrl.text.trim().isEmpty
                          ? widget.zone.name
                          : _nameCtrl.text.trim();
                      widget.zone.cropType = _selectedCrop;
                      widget.zone.areaAcres = double.tryParse(_areaCtrl.text) ??
                          widget.zone.areaAcres;
                      widget.zone.groupId = _selectedGroup;
                      widget.zone.soilThreshold = _threshold;
                      widget.zone.autoIrrigation = _autoIrr;
                      Navigator.pop(context);
                      widget.onSave(widget.zone);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient1,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                            widget.isTamil ? '💾 சேமி' : '💾 Save Changes',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.bg)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String icon,
      {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.cardGlass.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(icon, style: const TextStyle(fontSize: 18))),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: isNumeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: ctrl.text,
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    Map<String, String>? icons,
    Map<String, String>? displayNames,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.cardGlass.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.card,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              items: items
                  .map((i) => DropdownMenuItem(
                        value: i,
                        child: Row(children: [
                          if (icons != null)
                            Text(icons[i] ?? '🌱',
                                style: const TextStyle(fontSize: 16)),
                          if (icons != null) const SizedBox(width: 8),
                          Text(displayNames?[i] ?? i),
                        ]),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final double threshold;
  final double min;
  final double range;

  _SparklinePainter(this.data, this.threshold, this.min, this.range);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = const Color(0xFF00FF7F).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final threshPaint = Paint()
      ..color = const Color(0xFFFFA040).withValues(alpha: 0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final normalized = (data[i] - min) / range;
      final y = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final threshY =
        size.height - ((threshold - min) / range).clamp(0.0, 1.0) * size.height;
    canvas.drawLine(
      Offset(0, threshY),
      Offset(size.width, threshY),
      threshPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
