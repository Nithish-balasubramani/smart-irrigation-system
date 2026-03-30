import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

// ═══════════════════════════════════════════════════════════
// PROFILE EDIT SCREEN
// ═══════════════════════════════════════════════════════════
class ProfileEditScreen extends StatefulWidget {
  final String currentName;
  final String currentFarm;
  final String currentCrop;
  final String currentFarmSize;
  final String language;
  final Function(String name, String farm, String crop, String farmSize)
      onSave;

  const ProfileEditScreen({
    super.key,
    required this.currentName,
    required this.currentFarm,
    required this.currentCrop,
    required this.currentFarmSize,
    required this.language,
    required this.onSave,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _farmController;
  late TextEditingController _cropController;
  late TextEditingController _farmSizeController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isSaving = false;
  String _selectedCrop = 'Wheat';

  final List<Map<String, String>> _cropOptions = [
    {'name': 'Wheat', 'ta': 'கோதுமை', 'icon': '🌾'},
    {'name': 'Rice', 'ta': 'அரிசி', 'icon': '🍚'},
    {'name': 'Corn', 'ta': 'மக்காச்சோளம்', 'icon': '🌽'},
    {'name': 'Cotton', 'ta': 'பருத்தி', 'icon': '☁️'},
    {'name': 'Sugarcane', 'ta': 'கரும்பு', 'icon': '🎋'},
    {'name': 'Tomato', 'ta': 'தக்காளி', 'icon': '🍅'},
    {'name': 'Onion', 'ta': 'வெங்காயம்', 'icon': '🧅'},
    {'name': 'Potato', 'ta': 'உருளைக்கிழங்கு', 'icon': '🥔'},
  ];

  bool get isTamil => widget.language == 'ta';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _farmController = TextEditingController(text: widget.currentFarm);
    _cropController = TextEditingController(text: widget.currentCrop);
    _farmSizeController = TextEditingController(text: widget.currentFarmSize);
    _selectedCrop = widget.currentCrop;

    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmController.dispose();
    _cropController.dispose();
    _farmSizeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack(isTamil ? '⚠️ பெயர் உள்ளிடவும்' : '⚠️ Enter farmer name');
      return;
    }
    if (_farmController.text.trim().isEmpty) {
      _showSnack(isTamil ? '⚠️ பண்ணை பெயர் உள்ளிடவும்' : '⚠️ Enter farm name');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('farmerName', _nameController.text.trim());
      await prefs.setString('farmName', _farmController.text.trim());
      await prefs.setString('cropType', _selectedCrop);
      await prefs.setString('farmSize', _farmSizeController.text.trim());

      // Also save to Firestore
      final userIdentifier = prefs.getString('activeUserIdentifier') ?? '';
      if (userIdentifier.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userIdentifier)
            .set({
          'profile': {
            'name': _nameController.text.trim(),
            'farm': _farmController.text.trim(),
            'cropType': _selectedCrop,
            'farmSize': _farmSizeController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }
        }, SetOptions(merge: true));
      }

      widget.onSave(
        _nameController.text.trim(),
        _farmController.text.trim(),
        _selectedCrop,
        _farmSizeController.text.trim(),
      );

      if (!mounted) return;
      _showSnack(
        isTamil
            ? '✅ சுயவிவரம் சேமிக்கப்பட்டது!'
            : '✅ Profile saved successfully!',
        isSuccess: true,
      );
      Navigator.pop(context);
    } catch (e) {
      _showSnack(isTamil ? '❌ சேமிக்க முடியவில்லை' : '❌ Failed to save');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 28),
                      _buildInfoSection(),
                      const SizedBox(height: 24),
                      _buildCropSection(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: AppColors.cardGlass.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cardGlass.withValues(alpha: 0.3),
                ),
              ),
              child: const Text('←', style: TextStyle(fontSize: 18, color: AppColors.text)),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTamil ? 'சுயவிவரம் திருத்து' : 'Edit Profile',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              Text(
                isTamil ? 'உங்கள் விவரங்களை புதுப்பிக்கவும்' : 'Update your details',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.card.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient1,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('👨‍🌾', style: TextStyle(fontSize: 38)),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bg, width: 2),
                  ),
                  child: const Center(
                    child: Text('✏️', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty
                      ? (isTamil ? 'உங்கள் பெயர்' : 'Your Name')
                      : _nameController.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '📍 ${_farmController.text.isEmpty ? (isTamil ? 'பண்ணை பெயர்' : 'Farm Name') : _farmController.text}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '🌾 $_selectedCrop · ${_farmSizeController.text} acres',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return _buildCard(
      title: isTamil ? '👤 அடிப்படை தகவல்' : '👤 Basic Info',
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: isTamil ? 'விவசாயி பெயர்' : 'Farmer Name',
            hint: isTamil ? 'உங்கள் பெயர் உள்ளிடவும்' : 'Enter your name',
            icon: '👨‍🌾',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _farmController,
            label: isTamil ? 'பண்ணை பெயர்' : 'Farm Name',
            hint: isTamil ? 'பண்ணையின் பெயர்' : 'e.g. Green Valley Farm',
            icon: '🌿',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _farmSizeController,
            label: isTamil ? 'பண்ணை அளவு (ஏக்கர்)' : 'Farm Size (Acres)',
            hint: '5.2',
            icon: '📐',
            isNumeric: true,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildCropSection() {
    return _buildCard(
      title: isTamil ? '🌾 பயிர் வகை' : '🌾 Crop Type',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: _cropOptions.length,
        itemBuilder: (context, index) {
          final crop = _cropOptions[index];
          final isSelected = _selectedCrop == crop['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCrop = crop['name']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardGlass.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(crop['icon']!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    isTamil ? crop['ta']! : crop['name']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: _isSaving ? null : AppColors.gradient1,
          color: _isSaving ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isSaving
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💾', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(
                      isTamil ? 'சேமி' : 'Save Profile',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bg,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardGlass.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String icon,
    bool isNumeric = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardGlass.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: isNumeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
