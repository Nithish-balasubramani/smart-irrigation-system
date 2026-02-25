# Smart Irrigation System - Flutter App

A complete IoT-based Smart Irrigation System built with Flutter that allows users to monitor soil moisture, temperature, humidity, and control water pumps remotely through Firebase Realtime Database.

## Features

### 🔐 Authentication
- Email/Password login and signup
- Form validation
- Secure Firebase Authentication

### 📊 Dashboard
- Real-time soil moisture level display
- Temperature and humidity monitoring
- Water pump status indicator
- Water usage statistics
- Status alerts and warnings

### 🎮 Irrigation Control
- Manual pump ON/OFF control
- Automatic irrigation mode (threshold-based)
- Real-time pump status updates
- System status overview

### ⚙️ Settings
- Adjustable moisture threshold (10-80%)
- Crop type selection
- Irrigation duration configuration
- Alert preferences (low moisture, rain prediction)
- User profile management

### 🔔 Alerts & Notifications
- Low moisture alerts
- Rain prediction notifications
- System error alerts
- Pump status notifications

## Project Structure

```
lib/
├── main.dart                          # App entry point and navigation
├── models/
│   ├── sensor_data.dart              # Sensor data model
│   ├── user_model.dart               # User authentication model
│   └── irrigation_settings.dart      # Settings configuration model
├── services/
│   ├── firebase_service.dart         # Firebase Realtime Database operations
│   ├── auth_service.dart             # Authentication service
│   └── notification_service.dart     # Local notifications
├── providers/
│   ├── auth_provider.dart            # Authentication state management
│   ├── sensor_data_provider.dart     # Sensor data state management
│   └── settings_provider.dart        # Settings state management
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart         # Login page
│   │   └── signup_screen.dart        # Registration page
│   ├── dashboard_screen.dart         # Main dashboard
│   ├── control_screen.dart           # Irrigation control panel
│   └── settings_screen.dart          # Settings and preferences
└── widgets/
    ├── custom_button.dart            # Reusable button widget
    ├── sensor_card.dart              # Sensor data display cards
    └── pump_control_widget.dart      # Pump control interface
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Firebase account
- Android Studio / VS Code with Flutter extensions

### Installation Steps

1. **Clone or create the project**
   ```bash
   flutter create smart_irrigation_system
   cd smart_irrigation_system
   ```

2. **Copy all the code files** into the respective directories as shown in the project structure above.

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Firebase Setup**

   a. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   
   b. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```
   
   c. Configure Firebase for your Flutter app:
   ```bash
   flutterfire configure
   ```
   
   d. Enable Authentication:
   - Go to Firebase Console → Authentication
   - Enable Email/Password authentication
   
   e. Setup Realtime Database:
   - Go to Firebase Console → Realtime Database
   - Create database in test mode (or configure security rules)
   
   **Database Structure:**
   ```json
   {
     "users": {
       "userId": {
         "sensorData": {
           "moistureLevel": 45.0,
           "temperature": 28.5,
           "humidity": 65.0,
           "pumpStatus": false,
           "waterUsage": 125.5,
           "timestamp": "2026-02-23T10:30:00Z",
           "status": "normal"
         },
         "settings": {
           "moistureThreshold": 30.0,
           "cropType": "Rice",
           "autoMode": true,
           "irrigationDuration": 15,
           "rainPredictionAlert": true,
           "lowMoistureAlert": true
         },
         "waterUsageHistory": {
           "entry1": {
             "amount": 50.0,
             "timestamp": "2026-02-23T08:00:00Z"
           }
         }
       }
     }
   }
   ```

5. **Configure Android Notifications** (for Local Notifications)
   
   Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <manifest>
     <application>
       <!-- Add this inside <application> tag -->
       <meta-data
         android:name="com.google.firebase.messaging.default_notification_icon"
         android:resource="@mipmap/ic_launcher" />
     </application>
   </manifest>
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## Usage

### Testing Without IoT Hardware

For testing purposes without physical sensors, you can:

1. Manually update Firebase Realtime Database values
2. Use the Firebase Console to simulate sensor data changes
3. The app will automatically reflect the changes in real-time

### Testing with IoT Hardware

1. **Hardware Requirements:**
   - ESP32/ESP8266 or Arduino with WiFi
   - Soil moisture sensor
   - DHT11/DHT22 temperature & humidity sensor
   - Relay module for pump control

2. **Connect sensors to Firebase:**
   - Program your microcontroller to read sensor data
   - Update Firebase Realtime Database with sensor readings
   - Listen for pump control commands from Firebase

3. **Sample Arduino/ESP32 code structure:**
   ```cpp
   // Read sensors
   float moisture = readMoistureSensor();
   float temperature = dht.readTemperature();
   float humidity = dht.readHumidity();
   
   // Update Firebase
   Firebase.setFloat("users/userId/sensorData/moistureLevel", moisture);
   Firebase.setFloat("users/userId/sensorData/temperature", temperature);
   Firebase.setFloat("users/userId/sensorData/humidity", humidity);
   
   // Listen for pump commands
   bool pumpStatus = Firebase.getBool("users/userId/sensorData/pumpStatus");
   digitalWrite(PUMP_PIN, pumpStatus ? HIGH : LOW);
   ```

## State Management

This app uses **Provider** package for state management with three main providers:

- **AuthProvider**: Manages user authentication state
- **SensorDataProvider**: Handles real-time sensor data and pump control
- **SettingsProvider**: Manages irrigation settings and preferences

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| provider | ^6.1.1 | State management |
| firebase_core | ^2.24.2 | Firebase initialization |
| firebase_auth | ^4.15.3 | User authentication |
| firebase_database | ^10.4.0 | Realtime database |
| flutter_local_notifications | ^16.3.0 | Local push notifications |

## Features Explanation

### Automatic Irrigation Mode
When enabled, the system automatically:
1. Monitors soil moisture level
2. Compares with set threshold
3. Triggers pump when moisture falls below threshold
4. Runs pump for configured duration
5. Sends notifications

### Manual Irrigation Mode
Users can:
- Manually turn pump ON/OFF
- Override automatic mode
- Monitor real-time pump status

### Alert System
- **Low Moisture Alert**: Triggered when moisture < threshold
- **Rain Prediction**: Notifies about expected rain (requires weather API integration)
- **System Error**: Alerts on sensor communication failures

## Customization

### Adding More Sensors
1. Update `sensor_data.dart` model with new fields
2. Modify `firebase_service.dart` to fetch new data
3. Update UI in `dashboard_screen.dart`

### Changing Theme
Modify the theme in `main.dart`:
```dart
theme: ThemeData(
  primarySwatch: Colors.green, // Change primary color
  // Add more theme customizations
)
```

### Adding Weather API
Integrate weather services (OpenWeatherMap, WeatherAPI) in a new service file for rain prediction.

## Troubleshooting

### Firebase Connection Issues
- Verify Firebase configuration
- Check internet connectivity
- Ensure Firebase services are enabled

### Notification Not Working
- Check notification permissions
- Verify notification service initialization
- Test on physical device (not emulator)

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

## Future Enhancements

- [ ] Weather API integration for rain prediction
- [ ] Historical data charts and analytics
- [ ] Multi-zone irrigation support
- [ ] Schedule-based irrigation
- [ ] Push notifications (FCM)
- [ ] Dark mode support
- [ ] Multiple language support

## License

This project is open-source and available for educational and commercial use.

## Support

For issues and questions:
- Check Firebase documentation
- Verify sensor connections
- Review app logs for errors

---

**Built with ❤️ using Flutter**
