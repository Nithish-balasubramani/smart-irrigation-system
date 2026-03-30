import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/irrigation_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/zones_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettingsController.instance.load();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().initialize();
  NotificationService().startIrrigationStatusListener();

  if (kDebugMode) {
    Future<void>.delayed(const Duration(seconds: 3), () {
      NotificationService().showIrrigationAlert();
    });
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF060E0A),
  ));
  runApp(const AgriSmartApp());
}

// ═══════════════════════════════════════════════════════════
// MODERN COLOR PALETTE - Dark Green Theme with Glassmorphism
// ═══════════════════════════════════════════════════════════
class AppColors {
  static const bg = Color(0xFF060E0A);
  static const bg2 = Color(0xFF09160F);
  static const surface = Color(0xFF0C1E14);
  static const card = Color(0xFF0F251A);
  static const cardGlass = Color(0x40FFFFFF);

  static const primary = Color(0xFF00FF7F);
  static const primaryDark = Color(0xFF00C96A);
  static const accent = Color(0xFF00F5FF);

  static const blue = Color(0xFF40C4FF);
  static const yellow = Color(0xFFFFD54F);
  static const red = Color(0xFFFF6B6B);
  static const orange = Color(0xFFFFA040);
  static const purple = Color(0xFFB39DDB);

  static const text = Color(0xFFE8F5EC);
  static const textSecondary = Color(0xFF90C4A0);
  static const textMuted = Color(0xFF567060);

  static const gradient1 = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGlass = LinearGradient(
    colors: [
      Color.fromRGBO(16, 37, 26, 0.15),
      Color.fromRGBO(16, 37, 26, 0.05),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ═══════════════════════════════════════════════════════════
// API CONFIGURATION
// ═══════════════════════════════════════════════════════════
class AppConfig {
  static const String weatherApiKey = '547eeaed95e89d6f553c74c020543fba';
  static const String weatherApiUrl =
      'https://api.openweathermap.org/data/2.5/weather';
}

// ═══════════════════════════════════════════════════════════
// TRANSLATIONS
// ═══════════════════════════════════════════════════════════
class AppStrings {
  static Map<String, Map<String, String>> translations = {
    'en': {
      'appName': 'AgriSmart',
      'tagline': 'Smart Irrigation AI',
      'login': 'Sign In',
      'email': 'farmer@email.com',
      'password': 'Password',
      'home': 'Home',
      'ai': 'AI',
      'water': 'Water',
      'crops': 'Crops',
      'settings': 'Settings',
      'goodMorning': 'Good Morning',
      'farmerName': 'Rajesh Kumar',
      'farm': 'Raj Farm · Punjab',
      'live': 'LIVE',
      'moisture': 'Soil Moisture',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'rain': 'Rain Chance',
      'pumpStatus': 'Pump Status',
      'running': 'Running',
      'idle': 'Idle',
      'startPump': 'Start Pump',
      'stopPump': 'Stop Pump',
      'aiRecommendation': 'AI Recommendation',
      'irrigateNow': 'Irrigate Now',
      'skip': 'Skip Today',
      'todayUsage': 'Today\'s Usage',
      'weekly': 'Weekly',
      'aiPrediction': 'AI Prediction',
      'waterUsage': 'Water Usage',
      'cropManager': 'Crop Manager',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'systemConfig': 'System Config',
      'autoIrrigation': 'Auto Irrigation',
      'autoIrrigationDesc': 'AI controls pumps automatically',
      'rainLock': 'Rain Lock',
      'rainLockDesc': 'Skip irrigation on rain forecast',
      'thresholds': 'Thresholds',
      'soilThreshold': 'Soil Threshold',
      'soilThresholdDesc': 'Irrigate below this %',
      'rainThreshold': 'Rain Threshold',
      'rainThresholdDesc': 'Block above this %',
      'emergencyLevel': 'Emergency Level',
      'emergencyLevelDesc': 'Force irrigation',
      'saveSettings': 'Save Settings',
      'settingsSaved': '⚙️ Settings saved successfully!',
      'deviceInfo': 'Device Info',
      'signOut': 'Sign Out',
      'signOutConfirm': 'Are you sure you want to sign out?',
      'cancel': 'Cancel',
      'mlOptimizer': 'ML-based irrigation optimizer',
      'sensorInputs': 'Sensor Inputs',
      'moistureLabel': 'MOISTURE',
      'temp': 'TEMP',
      'humid': 'HUMIDITY',
      'rainLabel': 'RAIN',
      'cropType': 'CROP TYPE',
      'farmSizeLabel': 'FARM SIZE (ACRES)',
      'runPrediction': 'Run Prediction',
      'predictionResults': 'Prediction Results',
      'runPredictionMsg': 'Run prediction to see AI recommendations',
      'trackHistory': 'Track your irrigation history',
      'thisWeek': 'THIS WEEK',
      'aiSaved': 'AI SAVED',
      'efficiency': 'EFFICIENCY',
      'usageChart': 'Usage Chart',
      'aiPredicted': 'AI Predicted',
      'actual': 'Actual',
      'dailyHistory': 'Daily History',
      'dry': 'Dry',
      'optimal': 'Optimal',
      'hot': 'Hot',
      'normal': 'Normal',
      'stable': 'Stable',
      'rainLockStatus': 'Rain Lock',
      'clear': 'Clear',
      'close': 'Close',
      'soilDryMsg': 'Soil Dry — Moisture at',
      'irrigationNeeded': 'irrigation needed.',
      'currentMoisture': 'Current moisture levels are acceptable',
    },
    'ta': {
      'appName': 'அக்ரிஸ்மார்ட்',
      'tagline': 'நுட்பமான நீர்பாசன AI',
      'login': 'உள்நுழை',
      'email': 'farmer@email.com',
      'password': 'கடவுச்சொல்',
      'home': 'முகப்பு',
      'ai': 'AI',
      'water': 'நீர்',
      'crops': 'பயிர்',
      'settings': 'அமைப்பு',
      'goodMorning': 'காலை வணக்கம்',
      'farmerName': 'ராஜேஷ் குமார்',
      'farm': 'ராஜ் பண்ணை · புஞ்சை',
      'live': 'நேரடி',
      'moisture': 'மண் ஈரப்பதம்',
      'temperature': 'வெப்பநிலை',
      'humidity': 'ஈரப்பசை',
      'rain': 'மழை வாய்ப்பு',
      'pumpStatus': 'பம்ப் நிலை',
      'running': 'இயங்குகிறது',
      'idle': 'நிறுத்தம்',
      'startPump': 'பம்ப் தொடங்கு',
      'stopPump': 'பம்ப் நிறுத்து',
      'aiRecommendation': 'AI பரிந்துரை',
      'irrigateNow': 'இப்போது நீர்ப்பாய்ச்சு',
      'skip': 'இன்று தவிர்',
      'todayUsage': 'இன்றைய பயன்பாடு',
      'weekly': 'வாராந்திர',
      'aiPrediction': 'AI கணிப்பு',
      'waterUsage': 'நீர் பயன்பாடு',
      'cropManager': 'பயிர் மேலாளர்',
      'language': 'மொழி',
      'darkMode': 'இரவு தோற்றம்',
      'systemConfig': 'முறைமை அமைப்பு',
      'autoIrrigation': 'தானியங்கி நீர்ப்பாய்ச்சு',
      'autoIrrigationDesc': 'AI பம்புகளை தானாகவே கட்டுப்படுத்துகிறது',
      'rainLock': 'மழை பூட்டு',
      'rainLockDesc': 'மழை முன்னறிவிப்பில் நீர்ப்பாய்ச்சு தவிர்',
      'thresholds': 'வரம்புகள்',
      'soilThreshold': 'மண் வரம்பு',
      'soilThresholdDesc': 'இந்த % க்கு கீழே நீர் விடு',
      'rainThreshold': 'மழை வரம்பு',
      'rainThresholdDesc': 'இந்த % க்கு மேல் தடை',
      'emergencyLevel': 'அவசர நிலை',
      'emergencyLevelDesc': 'கட்டாய நீர்ப்பாய்ச்சு',
      'saveSettings': 'அமைப்புகளை சேமி',
      'settingsSaved': '⚙️ அமைப்புகள் வெற்றிகரமாக சேமிக்கப்பட்டன!',
      'deviceInfo': 'சாதன தகவல்',
      'signOut': 'வெளியேறு',
      'signOutConfirm': 'நீங்கள் வெளியேற விரும்புகிறீர்களா?',
      'cancel': 'ரத்து',
      'mlOptimizer': 'ML அடிப்படையிலான நீர்ப்பாய்ச்சு மேம்படுத்தி',
      'sensorInputs': 'உணரி உள்ளீடுகள்',
      'moistureLabel': 'ஈரப்பதம்',
      'temp': 'வெப்பம்',
      'humid': 'ஈரத்தன்மை',
      'rainLabel': 'மழை',
      'cropType': 'பயிர் வகை',
      'farmSizeLabel': 'பண்ணை அளவு (ஏக்கர்)',
      'runPrediction': 'கணிப்பு இயக்கு',
      'predictionResults': 'கணிப்பு முடிவுகள்',
      'runPredictionMsg': 'AI பரிந்துரைகளைக் காண கணிப்பை இயக்கவும்',
      'trackHistory': 'உங்கள் நீர்ப்பாசன வரலாற்றைக் கண்காணிக்கவும்',
      'thisWeek': 'இந்த வாரம்',
      'aiSaved': 'AI சேமித்தது',
      'efficiency': 'திறன்',
      'usageChart': 'பயன்பாட்டு விளக்கப்படம்',
      'aiPredicted': 'AI கணித்தது',
      'actual': 'உண்மையான',
      'dailyHistory': 'தினசரி வரலாறு',
      'dry': 'வறண்ட',
      'optimal': 'உகந்த',
      'hot': 'வெப்பம்',
      'normal': 'இயல்பான',
      'stable': 'நிலையான',
      'rainLockStatus': 'மழை பூட்டு',
      'clear': 'தெளிவான',
      'close': 'மூடு',
      'soilDryMsg': 'மண் வறண்டது — ஈரப்பதம்',
      'irrigationNeeded': 'நீர்ப்பாய்ச்சு தேவை.',
      'currentMoisture': 'தற்போதைய ஈரப்பத நிலைகள் ஏற்கத்தக்கவை',
    },
  };
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._();

  static final AppSettingsController instance = AppSettingsController._();

  String _language = 'en';
  bool _isDarkMode = true;

  String get language => _language;
  bool get isDarkMode => _isDarkMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? 'en';
    _isDarkMode = prefs.getBool('darkMode') ?? true;
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (_language == language) return;
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppSettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    return scope?.notifier ?? AppSettingsController.instance;
  }
}

// ═══════════════════════════════════════════════════════════
// MAIN APP
// ═══════════════════════════════════════════════════════════
class AgriSmartApp extends StatelessWidget {
  const AgriSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      notifier: AppSettingsController.instance,
      child: AnimatedBuilder(
        animation: AppSettingsController.instance,
        builder: (context, _) {
          final settings = AppSettingsController.instance;
          return MaterialApp(
            title: 'AgriSmart',
            debugShowCheckedModeBanner: false,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF4FBF7),
              fontFamily: 'System',
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryDark,
                secondary: AppColors.accent,
                surface: Colors.white,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppColors.bg,
              fontFamily: 'System',
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.accent,
                surface: AppColors.surface,
              ),
            ),
            routes: {
              '/irrigation': (context) => const IrrigationScreen(),
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SPLASH SCREEN - Check Login State
// ═══════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1)); // Brief splash delay

    // Initialize Firebase Weather API Key in Firestore (non-blocking)
    _initializeWeatherApiKey(); // Run in background, don't wait

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final savedLanguage = prefs.getString('language') ?? 'en';
    final savedUserIdentifier = prefs.getString('activeUserIdentifier') ?? '';
    final firebaseUser = AuthService().currentUser;
    final effectiveIdentifier = savedUserIdentifier.isNotEmpty
        ? savedUserIdentifier
        : (firebaseUser?.uid ?? '');

    if (!mounted) return;

    if (isLoggedIn && firebaseUser != null) {
      // User is logged in, go to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            language: savedLanguage,
            userIdentifier: effectiveIdentifier,
          ),
        ),
      );
    } else {
      if (isLoggedIn) {
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('activeUserIdentifier');
      }

      if (!mounted) return;

      // User not logged in, go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  /// Initialize or verify weather API key in Firestore
  Future<void> _initializeWeatherApiKey() async {
    try {
      final firebaseService = FirebaseService();

      // Check if API key already exists in Firestore with timeout
      final existingKey = await firebaseService
          .getWeatherApiKey()
          .timeout(const Duration(seconds: 5));

      if (existingKey == null || existingKey.isEmpty) {
        // Store the API key from AppConfig
        await firebaseService
            .storeWeatherApiKey(AppConfig.weatherApiKey)
            .timeout(const Duration(seconds: 5));
        print('Weather API key initialized in Firestore');
      } else {
        print('Weather API key already exists in Firestore');
      }
    } catch (e) {
      print('Error initializing weather API key (will retry later): $e');
      // Non-blocking: app continues to load even if Firestore fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.gradient1,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '🌾',
                  style: TextStyle(fontSize: 50),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AgriSmart',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smart Irrigation AI',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LOGIN SCREEN - Modern Glassmorphism Design
// ═══════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  String _language = 'en';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _language = AppSettingsController.instance.language;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Map<String, String> get t => AppStrings.translations[_language]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bg2,
              AppColors.bg,
              Color(0xFF040A06),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Animated Logo
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: AppColors.gradient1,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '🌿',
                              style: TextStyle(fontSize: 50),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  Text(
                    t['appName']!,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    t['tagline']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Language Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLangButton('en', '🇬🇧 English'),
                      const SizedBox(width: 12),
                      _buildLangButton('ta', '🇮🇳 தமிழ்'),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Glass Card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: AppColors.gradientGlass,
                      border: Border.all(
                        color: AppColors.cardGlass.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.card.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),

                              const SizedBox(height: 6),

                              const Text(
                                'Sign in to your farm dashboard',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Email Field
                              _buildTextField(
                                icon: '✉️',
                                hint: t['email']!,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 16),

                              // Password Field
                              _buildTextField(
                                icon: '🔒',
                                hint: t['password']!,
                                obscure: true,
                                controller: _passwordController,
                              ),

                              const SizedBox(height: 16),

                              // Forgot Password
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Sign In Button
                              GestureDetector(
                                onTap: () async {
                                  final email = _emailController.text.trim();
                                  final password = _passwordController.text;

                                  if (email.isEmpty || password.isEmpty) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Enter email and password to sign in',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final authService = AuthService();
                                  String userIdentifier = email;

                                  try {
                                    final user = await authService.signIn(
                                      email: email,
                                      password: password,
                                    );

                                    if (user == null) {
                                      throw 'Sign in failed. Please try again.';
                                    }

                                    userIdentifier = user.id;
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                    return;
                                  }

                                  // Save login state
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('isLoggedIn', true);
                                  await prefs.setString('language', _language);
                                  await prefs.setString(
                                    'activeUserIdentifier',
                                    userIdentifier,
                                  );

                                  if (!context.mounted) return;

                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) => HomeScreen(
                                        language: _language,
                                        userIdentifier: userIdentifier,
                                      ),
                                      transitionsBuilder: (_, anim, __, child) {
                                        return FadeTransition(
                                          opacity: anim,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.gradient1,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('🔐'),
                                      const SizedBox(width: 10),
                                      Text(
                                        t['login']!,
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

                              const SizedBox(height: 20),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: AppColors.textMuted
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      _language == 'ta' ? 'அல்லது' : 'or',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: AppColors.textMuted
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Biometric Button
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.cardGlass
                                        .withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('👆'),
                                    SizedBox(width: 10),
                                    Text(
                                      'Use Biometric',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Trust Indicators
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildTrustBadge('🔒 SSL'),
                                  const SizedBox(width: 16),
                                  _buildTrustBadge('☁️ Firebase'),
                                  const SizedBox(width: 16),
                                  _buildTrustBadge(_language == 'ta'
                                      ? '🛡️ பாதுகாப்பு'
                                      : '🛡️ Secured'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(String code, String label) {
    final isSelected = _language == code;
    return GestureDetector(
      onTap: () {
        setState(() => _language = code);
        AppSettingsController.instance.setLanguage(code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.cardGlass.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String icon,
    required String hint,
    bool obscure = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cardGlass.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscure,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
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
    );
  }

  Widget _buildTrustBadge(String label) {
    return const Text(
      '',
      style: TextStyle(
        fontSize: 10,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HOME SCREEN - Main Dashboard with Modern Design
// ═══════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final String language;
  final String userIdentifier;

  const HomeScreen({
    super.key,
    required this.language,
    this.userIdentifier = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const bool _useFirestoreDemo = true;

  int _currentIndex = 0;
  bool _pumpOn = false;
  Timer? _sensorTimer;
  Timer? _autoUpdateTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _realtimeSub;
  late AnimationController _pulseController;
  late String _currentLanguage;
  String _currentFarmerName = 'Farmer';
  String _currentFarmName = 'My Farm';
  String _activeUserIdentifier = '';
  String? _resolvedUserId;

  // Sensor data
  double _moisture = 34.0;
  double _temperature = 29.0;
  double _humidity = 68.0;
  double _rainChance = 22.0;

  // AI Prediction inputs
  String _cropType = 'Wheat';
  String _farmSize = '5.2';

  // Water usage data
  final List<Map<String, dynamic>> _dailyHistory = [
    {'date': 'Mon25', 'actual': 58, 'predicted': 70, 'diff': -12},
    {'date': 'Tue24', 'actual': 44, 'predicted': 52, 'diff': -8},
    {'date': 'Wed23', 'actual': 67, 'predicted': 67, 'diff': 0},
    {'date': 'Thu22', 'actual': 31, 'predicted': 59, 'diff': -28},
    {'date': 'Fri21', 'actual': 72, 'predicted': 77, 'diff': -5},
    {'date': 'Sat20', 'actual': 48, 'predicted': 58, 'diff': -10},
    {'date': 'Sun19', 'actual': 55, 'predicted': 62, 'diff': -7},
  ];

  // Settings data
  bool _autoIrrigation = true;
  bool _rainLock = true;
  double _soilThreshold = 40.0;
  double _rainThreshold = 60.0;
  double _emergencyLevel = 30.0;

  Map<String, String> get t => AppStrings.translations[_currentLanguage]!;

  @override
  void initState() {
    super.initState();
    _currentLanguage = AppSettingsController.instance.language.isNotEmpty
        ? AppSettingsController.instance.language
        : widget.language;
    _activeUserIdentifier = widget.userIdentifier.trim();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    if (_useFirestoreDemo) {
      _startAutoUpdate();
      _listenToRealtimeFirestore();
    } else {
      _loadUserContext();
      _sensorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _refreshSensorData();
      });
    }
  }

  void _startAutoUpdate() {
    _autoUpdateTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      final moisture = math.Random().nextInt(100);
      final temperature = math.Random().nextInt(40);
      final humidity = 35 + math.Random().nextInt(61);
      final rainChance = math.Random().nextInt(101);
      final motor = _pumpOn ? 'ON' : 'OFF';

      try {
        await _db.collection('irrigation_data').doc('sensor1').set({
          'moisture': moisture,
          'temperature': temperature,
          'humidity': humidity,
          'rainChance': rainChance,
          'motor': motor,
          'time': DateTime.now(),
        }, SetOptions(merge: true));
      } catch (_) {
        // Ignore transient write failures in demo mode.
      }
    });
  }

  void _listenToRealtimeFirestore() {
    _realtimeSub =
        _db.collection('irrigation_data').doc('sensor1').snapshots().listen(
      (snapshot) {
        final data = snapshot.data();
        if (data == null || !mounted) return;

        setState(() {
          _moisture = _toDouble(data['moisture'], _moisture);
          _temperature = _toDouble(data['temperature'], _temperature);
          _humidity = _toDouble(data['humidity'], _humidity);
          _rainChance = _toDouble(data['rainChance'], _rainChance);
          _pumpOn = (data['motor']?.toString().toUpperCase() ?? 'OFF') == 'ON';
        });
      },
    );
  }

  double _toDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return fallback;
  }

  Future<void> _loadUserContext() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIdentifier =
        prefs.getString('activeUserIdentifier')?.trim() ?? '';

    if (storedIdentifier.isNotEmpty) {
      _activeUserIdentifier = storedIdentifier;
      _currentFarmerName = storedIdentifier;
    }

    await _refreshSensorData(forceResolveUser: true);
  }

  Future<void> _refreshSensorData({bool forceResolveUser = false}) async {
    String? userId = _resolvedUserId;

    if (forceResolveUser || userId == null) {
      if (_activeUserIdentifier.isNotEmpty) {
        userId = await _firebaseService.resolveUserId(_activeUserIdentifier);
      }
      _resolvedUserId = userId;
    }

    if (userId == null) {
      _simulateSensorData();
      return;
    }

    final userProfile = await _firebaseService.getUserProfile(userId);
    final sensorData = await _firebaseService.getSensorData(userId);

    if (!mounted) return;

    setState(() {
      _moisture = sensorData.moistureLevel;
      _temperature = sensorData.temperature;
      _humidity = sensorData.humidity;
      _pumpOn = sensorData.pumpStatus;

      final profileName = userProfile?['name'];
      final profileFarm = userProfile?['farm'];
      if (profileName is String && profileName.trim().isNotEmpty) {
        _currentFarmerName = profileName.trim();
      } else if (_activeUserIdentifier.isNotEmpty) {
        _currentFarmerName = _activeUserIdentifier;
      }
      if (profileFarm is String && profileFarm.trim().isNotEmpty) {
        _currentFarmName = profileFarm.trim();
      }
    });
  }

  void _simulateSensorData() {
    if (!mounted) return;

    setState(() {
      _moisture =
          (_moisture + (math.Random().nextDouble() - 0.5) * 2.5).clamp(20, 90);
      _temperature = (_temperature + (math.Random().nextDouble() - 0.5) * 0.6)
          .clamp(18, 42);
      _humidity =
          (_humidity + (math.Random().nextDouble() - 0.5) * 1.5).clamp(30, 95);
      _rainChance =
          (_rainChance + (math.Random().nextDouble() - 0.5) * 4).clamp(0, 100);
    });
  }

  Future<void> _togglePump() async {
    final nextState = !_pumpOn;

    if (_useFirestoreDemo) {
      try {
        await _db.collection('irrigation_data').doc('sensor1').set({
          'motor': nextState ? 'ON' : 'OFF',
          'time': DateTime.now(),
        }, SetOptions(merge: true));
      } catch (_) {
        return;
      }

      if (!mounted) return;
      setState(() => _pumpOn = nextState);
      return;
    }

    if (_resolvedUserId != null) {
      final updated =
          await _firebaseService.updatePumpStatus(_resolvedUserId!, nextState);
      if (!updated) return;
    }

    if (!mounted) return;
    setState(() => _pumpOn = nextState);
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    _autoUpdateTimer?.cancel();
    _realtimeSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bg2,
              AppColors.bg,
            ],
          ),
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomePage(),
              _buildAIPage(),
              _buildWaterPage(),
              _buildSettingsPage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.cardGlass.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, '🏠', t['home']!),
          _buildNavItem(1, '🤖', t['ai']!),
          _buildNavItem(2, '💧', t['water']!),
          _buildNavItem(3, '⚙️', t['settings']!),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: isSelected ? 24 : 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HOME PAGE
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Sensor Cards
          _buildSensorGrid(),
          const SizedBox(height: 24),

          // Pump Control
          _buildPumpCard(),
          const SizedBox(height: 24),

          // AI Recommendation
          _buildAIRecommendationCard(),
          const SizedBox(height: 24),

          // Today's Usage
          _buildUsageCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.card,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.cardGlass.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t['goodMorning']} 👋',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentFarmerName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '📍 $_currentFarmName',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                      alpha: _pulseController.value),
                                  blurRadius: 8,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${t['live']} · ESP32',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.gradient1,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '👨‍🌾',
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid() {
    final sensors = [
      {
        'icon': '💧',
        'name': t['moisture']!,
        'value': _moisture.round(),
        'unit': '%',
        'color': AppColors.primary,
        'status': _moisture < 40 ? t['dry']! : t['optimal']!,
      },
      {
        'icon': '🌡️',
        'name': t['temperature']!,
        'value': _temperature.round(),
        'unit': '°C',
        'color': AppColors.orange,
        'status': _temperature > 32 ? t['hot']! : t['normal']!,
      },
      {
        'icon': '💨',
        'name': t['humidity']!,
        'value': _humidity.round(),
        'unit': '%',
        'color': AppColors.blue,
        'status': t['stable']!,
      },
      {
        'icon': '🌧️',
        'name': t['rain']!,
        'value': _rainChance.round(),
        'unit': '%',
        'color': AppColors.purple,
        'status': _rainChance > 60 ? t['rainLockStatus']! : t['clear']!,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        final sensor = sensors[index];
        return _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (sensor['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        sensor['icon'] as String,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (sensor['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sensor['status'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: sensor['color'] as Color,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${sensor['value']}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      fontFamily: 'Courier',
                      letterSpacing: -1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      sensor['unit'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                sensor['name'] as String,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPumpCard() {
    return _buildGlassCard(
      child: Row(
        children: [
          // Animated Orb
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pumpOn
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.red.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _pumpOn ? AppColors.primary : AppColors.red,
                    width: 2,
                  ),
                  boxShadow: _pumpOn
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                                alpha: 0.3 * _pulseController.value),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    _pumpOn ? '🔵' : '⭕',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t['pumpStatus']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _pumpOn ? t['running']! : t['idle']!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _pumpOn ? AppColors.primary : AppColors.red,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _pumpOn ? '3,200 RPM · 2.4 L/min' : '— RPM · 0 L/min',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _togglePump,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: _pumpOn ? null : AppColors.gradient1,
                color: _pumpOn ? AppColors.red.withValues(alpha: 0.15) : null,
                borderRadius: BorderRadius.circular(16),
                border: _pumpOn
                    ? Border.all(
                        color: AppColors.red.withValues(alpha: 0.4),
                      )
                    : null,
                boxShadow: !_pumpOn
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                _pumpOn ? '🔴 ${t['stopPump']}' : '🟢 ${t['startPump']}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _pumpOn ? AppColors.red : AppColors.bg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendationCard() {
    final shouldIrrigate = _moisture < 40 && _rainChance <= 60;
    final waterNeeded = shouldIrrigate ? (_moisture < 40 ? 65 : 28) : 0;
    final duration = (waterNeeded / 2.5).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryDark.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.accent.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['aiRecommendation']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const Text(
                      'Confidence: 94.2%',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Metrics
          Row(
            children: [
              _buildMetricChip('💧 ${waterNeeded}L', AppColors.primary),
              const SizedBox(width: 10),
              _buildMetricChip('⏱ ${duration}m', AppColors.blue),
              const SizedBox(width: 10),
              _buildMetricChip(
                shouldIrrigate && _rainChance <= 60
                    ? '🟢 ON'
                    : (_rainChance > 60 ? '🌧️ LOCK' : '🔴 OFF'),
                shouldIrrigate && _rainChance <= 60
                    ? AppColors.primary
                    : (_rainChance > 60 ? AppColors.yellow : AppColors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Decision
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shouldIrrigate ? '🚨' : (_rainChance > 60 ? '🌧️' : '✅'),
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    shouldIrrigate
                        ? 'Soil Dry — Moisture at ${_moisture.round()}% — irrigation needed.'
                        : (_rainChance > 60
                            ? 'Rain Lock Active — ${_rainChance.round()}% rain chance. Pump paused.'
                            : 'Optimal — Moisture at ${_moisture.round()}% — no irrigation needed.'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (shouldIrrigate && _rainChance <= 60) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient1,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() {
                            _pumpOn = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _currentLanguage == 'ta'
                                    ? '💧 பம்ப் தொடங்கப்பட்டது! நீர்ப்பாய்ச்சு செயலில்'
                                    : '💧 Pump started! Irrigation active',
                              ),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              '🚿 ${t['irrigateNow']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.bg,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.cardGlass.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                _currentLanguage == 'ta'
                                    ? '⏭️ இன்று தவிர்க்கவா?'
                                    : '⏭️ Skip Today?',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: Text(
                                _currentLanguage == 'ta'
                                    ? 'இன்றைய நீர்ப்பாசனத்தை தவிர்க்க விரும்புகிறீர்களா?'
                                    : 'Skip irrigation for today?',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    t['cancel']!,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _currentLanguage == 'ta'
                                              ? '⏭️ இன்றைய நீர்ப்பாசனம் தவிர்க்கப்பட்டது'
                                              : '⏭️ Irrigation skipped for today',
                                        ),
                                        backgroundColor: AppColors.yellow,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    _currentLanguage == 'ta' ? 'தவிர்' : 'Skip',
                                    style: const TextStyle(
                                      color: AppColors.red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              '⏭ ${t['skip']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          fontFamily: 'Courier',
        ),
      ),
    );
  }

  Widget _buildUsageCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 ${t['todayUsage']}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _buildUsageStat(
                  '42L', _currentLanguage == 'ta' ? 'இன்று' : 'Today'),
              const SizedBox(width: 12),
              _buildUsageStat('375L', t['weekly']!, color: AppColors.blue),
              const SizedBox(width: 12),
              _buildUsageStat(
                  '+23%', _currentLanguage == 'ta' ? 'திறன்' : 'Efficiency',
                  color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),

          // Mini Chart
          Text(
            '${t['weekly']} · AI vs Actual (L)',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final heights = [48.0, 62.0, 35.0, 71.0, 44.0, 28.0, 55.0];
              return Container(
                width: 32,
                height: heights[i],
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStat(String value, String label, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.cardGlass.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color ?? AppColors.text,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.cardGlass.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  // AI PAGE
  Widget _buildAIPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient1,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text('🤖', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['aiPrediction']!,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['mlOptimizer']!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Sensor Inputs Section
          Text(
            t['sensorInputs']!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Sensor Data Grid
          _buildGlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildAIInputField(
                        label: t['moistureLabel']!,
                        value: '${_moisture.toStringAsFixed(0)}%',
                        color: AppColors.primary,
                        isReadOnly: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAIInputField(
                        label: t['temp']!,
                        value: '${_temperature.toStringAsFixed(0)}°C',
                        color: AppColors.orange,
                        isReadOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAIInputField(
                        label: t['humid']!,
                        value: '${_humidity.toStringAsFixed(0)}%',
                        color: AppColors.blue,
                        isReadOnly: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAIInputField(
                        label: t['rainLabel']!,
                        value: '${_rainChance.toStringAsFixed(0)}%',
                        color: AppColors.purple,
                        isReadOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAIInputField(
                        label: t['cropType']!,
                        value: _cropType,
                        color: AppColors.yellow,
                        isReadOnly: false,
                        onChanged: (value) {
                          setState(() {
                            _cropType = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAIInputField(
                        label: t['farmSizeLabel']!,
                        value: _farmSize,
                        color: AppColors.accent,
                        isReadOnly: false,
                        isNumeric: true,
                        onChanged: (value) {
                          setState(() {
                            _farmSize = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Run Prediction Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.gradient1,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _runPrediction();
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🤖', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        t['runPrediction']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Results Section (placeholder)
          _buildGlassCard(
            child: Column(
              children: [
                Text(
                  '📊 ${t['predictionResults']!}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      t['runPredictionMsg']!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAIInputField({
    required String label,
    required String value,
    required Color color,
    bool isReadOnly = true,
    bool isNumeric = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: isReadOnly
              ? Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'Courier',
                  ),
                )
              : TextField(
                  controller: TextEditingController(text: value),
                  onChanged: onChanged,
                  keyboardType:
                      isNumeric ? TextInputType.number : TextInputType.text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
        ),
      ],
    );
  }

  void _runPrediction() {
    // Calculate water requirement based on inputs
    final moistureLevel = _moisture;
    final cropFactor = _cropType.toLowerCase() == 'wheat' ? 1.2 : 1.0;
    final farmSizeNum = double.tryParse(_farmSize) ?? 5.2;

    // Simulate AI prediction
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Text('🤖', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Text(
              'AI Prediction',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow(
              '💧 Water Needed',
              '${(farmSizeNum * cropFactor * (100 - moistureLevel) / 10).toStringAsFixed(1)} L',
              AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              '⏱ Duration',
              '${((farmSizeNum * cropFactor * (100 - moistureLevel) / 25)).toStringAsFixed(0)} min',
              AppColors.blue,
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              '🌡️ Optimal Time',
              _temperature > 30 ? 'Evening' : 'Morning',
              AppColors.orange,
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              '📊 Confidence',
              '94.2%',
              AppColors.primary,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: moistureLevel < 40
                    ? AppColors.red.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: moistureLevel < 40
                      ? AppColors.red.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                moistureLevel < 40
                    ? '⚠️ Immediate irrigation recommended'
                    : '✅ Current moisture levels are acceptable',
                style: TextStyle(
                  fontSize: 13,
                  color: moistureLevel < 40 ? AppColors.red : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t['close']!,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }

  // WATER PAGE
  Widget _buildWaterPage() {
    // Calculate totals
    final int weeklyTotal =
        _dailyHistory.fold(0, (total, day) => total + (day['actual'] as int));
    final int aiSaved =
        -_dailyHistory.fold(0, (total, day) => total + (day['diff'] as int));
    final double efficiency = ((aiSaved / weeklyTotal) * 100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '💧 ${t['waterUsage']}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t['trackHistory']!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: '💧',
                  value: '${weeklyTotal}L',
                  label: t['thisWeek']!,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: '♻️',
                  value: '${aiSaved}L',
                  label: t['aiSaved']!,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: '📈',
                  value: '+${efficiency.toStringAsFixed(0)}%',
                  label: t['efficiency']!,
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Usage Chart Section
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t['usageChart']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Row(
                  children: [
                    _buildLegendItem(t['aiPredicted']!, AppColors.primary),
                    const SizedBox(width: 16),
                    _buildLegendItem(t['actual']!, AppColors.blue),
                  ],
                ),
                const SizedBox(height: 24),
                // Bar Chart
                SizedBox(
                  height: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _dailyHistory.map((day) {
                      return _buildChartBar(
                        predicted: day['predicted'] as int,
                        actual: day['actual'] as int,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Daily History Section
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 20),
                ..._dailyHistory.map((day) => _buildHistoryItem(
                      date: day['date'] as String,
                      liters: day['actual'] as int,
                      diff: day['diff'] as int,
                      maxLiters: 80,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChartBar({
    required int predicted,
    required int actual,
  }) {
    const maxHeight = 150.0;
    final predictedHeight = (predicted / 80) * maxHeight;
    final actualHeight = (actual / 80) * maxHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Predicted bar (green)
        Container(
          width: 14,
          height: predictedHeight.clamp(10, maxHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 4),
        // Actual bar (blue)
        Container(
          width: 14,
          height: actualHeight.clamp(10, maxHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.blue,
                AppColors.blue.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required String date,
    required int liters,
    required int diff,
    required int maxLiters,
  }) {
    final progress = (liters / maxLiters).clamp(0.0, 1.0);
    final diffText = diff == 0 ? '0L' : '${diff}L';
    final diffColor = diff <= 0 ? AppColors.primary : AppColors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: 50,
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Progress bar
          Expanded(
            child: Stack(
              children: [
                // Background
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Progress
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Liters
          SizedBox(
            width: 45,
            child: Text(
              '${liters}L',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontFamily: 'Courier',
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          // Difference
          SizedBox(
            width: 40,
            child: Text(
              diffText,
              style: TextStyle(
                fontSize: 12,
                color: diffColor,
                fontWeight: FontWeight.w700,
                fontFamily: 'Courier',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // SETTINGS PAGE
  Widget _buildSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Text('⚙️', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure your system',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Profile Section
          _buildGlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient1,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('👨‍🌾', style: TextStyle(fontSize: 30)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentFarmerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '📍 $_currentFarmName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '🌾 $_cropType · $_farmSize acres',
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
                const SizedBox(height: 16),
                // Action Buttons Row
                Row(
                  children: [
                    // Edit Profile Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileEditScreen(
                                currentName: _currentFarmerName,
                                currentFarm: _currentFarmName,
                                currentCrop: _cropType,
                                currentFarmSize: _farmSize,
                                language: _currentLanguage,
                                onSave: (name, farm, crop, size) {
                                  setState(() {
                                    _currentFarmerName = name;
                                    _currentFarmName = farm;
                                    _cropType = crop;
                                    _farmSize = size;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('✏️', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                _currentLanguage == 'ta' ? 'திருத்து' : 'Edit Profile',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.bg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Manage Zones Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ZonesScreen(
                                language: _currentLanguage,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.blue.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🗺️', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                _currentLanguage == 'ta' ? 'பகுதிகள்' : 'Manage Zones',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Language Section
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🌐', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      t['language']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            _currentLanguage = 'en';
                          });
                              await AppSettingsController.instance
                                  .setLanguage('en');
                        },
                        child: _buildLanguageButton('en', 'English'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            _currentLanguage = 'ta';
                          });
                          await AppSettingsController.instance
                              .setLanguage('ta');
                        },
                        child: _buildLanguageButton('ta', 'தமிழ்'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // System Config Section
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔧', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      t['systemConfig']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildToggleItem(
                  t['darkMode'] ?? 'Dark Mode',
                  _currentLanguage == 'ta'
                      ? 'முழு பயன்பாட்டிற்கும் இரவு தோற்றம்'
                      : 'Use dark theme across the app',
                  AppSettingsController.instance.isDarkMode,
                  (value) {
                    AppSettingsController.instance.setDarkMode(value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                _buildToggleItem(
                  t['autoIrrigation']!,
                  t['autoIrrigationDesc']!,
                  _autoIrrigation,
                  (value) => setState(() => _autoIrrigation = value),
                ),
                const SizedBox(height: 16),
                _buildToggleItem(
                  t['rainLock']!,
                  t['rainLockDesc']!,
                  _rainLock,
                  (value) => setState(() => _rainLock = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Thresholds Section
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📊', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      t['thresholds']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSliderItem(
                  t['soilThreshold']!,
                  t['soilThresholdDesc']!,
                  _soilThreshold,
                  (value) => setState(() => _soilThreshold = value),
                ),
                const SizedBox(height: 20),
                _buildSliderItem(
                  t['rainThreshold']!,
                  t['rainThresholdDesc']!,
                  _rainThreshold,
                  (value) => setState(() => _rainThreshold = value),
                ),
                const SizedBox(height: 20),
                _buildSliderItem(
                  t['emergencyLevel']!,
                  t['emergencyLevelDesc']!,
                  _emergencyLevel,
                  (value) => setState(() => _emergencyLevel = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save Settings Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.gradient1,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t['settingsSaved']!),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💾', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        t['saveSettings']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Device Info Section
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📱', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      t['deviceInfo']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow('MCU', 'ESP32 @ 240MHz'),
                const SizedBox(height: 12),
                _buildInfoRow('Firebase', 'agrismart-prod'),
                const SizedBox(height: 12),
                _buildInfoRow('Weather API', 'OpenWeatherMap'),
                const SizedBox(height: 12),
                _buildInfoRow('AI Model', 'RandomForest v1.3'),
                const SizedBox(height: 12),
                _buildInfoRow('Firmware', 'v2.5.0'),
                const SizedBox(height: 12),
                _buildInfoRow('Version', '2.5.1 (Build 42)'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Test Firebase/Firestore Button (for debugging)
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.gradient1,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  try {
                    final firebaseService = FirebaseService();

                    // Store the API key
                    bool stored = await firebaseService
                        .storeWeatherApiKey(AppConfig.weatherApiKey);

                    // Retrieve the API key
                    String? retrievedKey =
                        await firebaseService.getWeatherApiKey();

                    // Get full config
                    Map<String, dynamic>? config =
                        await firebaseService.getWeatherApiConfig();

                    if (!mounted) return;

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text(
                          '🔥 Firebase Firestore Test',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Store Result: ${stored ? "✅ Success" : "❌ Failed"}',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Retrieved API Key:',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                retrievedKey ?? 'null',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Full Config:',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                config?.toString() ?? 'null',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Close',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text(
                          '❌ Error',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: Text(
                          'Error: $e',
                          style: const TextStyle(
                            color: AppColors.text,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Close',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Center(
                  child: Text(
                    '🔥 Test Firebase API Storage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sign Out Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.red.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Text(
                        '🚪 ${t['signOut']!}',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: Text(
                        t['signOutConfirm']!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            t['cancel']!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await AuthService().signOut();
                            } catch (_) {}

                            // Clear login state
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('isLoggedIn', false);
                            await prefs.remove('language');
                            await prefs.remove('activeUserIdentifier');

                            if (!mounted) return;
                            if (!context.mounted) return;

                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🚪', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        t['signOut']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String langCode, String label) {
    final isSelected = _currentLanguage == langCode;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.cardGlass.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildSliderItem(
    String title,
    String subtitle,
    double value,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            Text(
              '${value.toInt()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surface.withValues(alpha: 0.5),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }
}
