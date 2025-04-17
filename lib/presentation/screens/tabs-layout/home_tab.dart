import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemNavigator.pop
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

// Assuming these imports are correct relative to your project structure
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../screens/camera_view.dart'; // Import your camera screen
import 'chat_tab.dart'; // Import your chat screen

// --- Model for Weather Data (Clean Code) ---
class WeatherInfo {
  final String city;
  final String description;
  final double temperature;

  WeatherInfo({
    required this.city,
    required this.description,
    required this.temperature,
  });

  @override
  String toString() {
    return '$city: $description, ${temperature.toStringAsFixed(0)}°C';
  }
}

// --- HomeTab Widget ---
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with WidgetsBindingObserver {
  // --- State Variables ---
  String _currentDateString = "";
  String _dayNightState = "Day";
  String _detectedCurrency = "\$0.00"; // Mock data, replace if needed
  List<String> _detectedObjects = ["No objects detected"]; // Use List<String>
  String _currentWeatherString = "Weather data unavailable";
  String _lastWords = "Press the mic button to start speaking...";
  String _lastError = "";
  String _currentStatus = stt.SpeechToText.notListeningStatus;
  double _confidence = 0.0;
  Timer? _restartTimer; // Timer for restarting listener

  // --- Services ---
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;

  // --- Configuration ---
  // IMPORTANT: Replace with your actual API key. Use secure storage in production.
  final String _openWeatherApiKey = "9598463d66d34d01a8851915251402";
  final List<String> _weatherCities = ["Alexandria", "Cairo"];
  final Duration _listenPauseDuration = const Duration(seconds: 2);
  final Duration _restartDelay = const Duration(milliseconds: 500); // Short delay before restart

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeServices();
    _updateDateTime();
    _updateDayNightState(); // Initial day/night check
    _fetchInitialWeather(); // Fetch weather on init
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restartTimer?.cancel();
    _speechToText.cancel(); // Ensure speech is cancelled
    _flutterTts.stop(); // Stop TTS
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Optional: Stop/Restart listening when app goes to background/foreground
    switch (state) {
      case AppLifecycleState.resumed:
        _startListening(); // Restart listening when app resumes
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden: // Handle newer hidden state
        _stopListening(); // Stop listening when app is not active
        break;
    }
  }

  // --- Initialization ---
  Future<void> _initializeServices() async {
    await _initializeTts();
    await _initializeSpeechToText();
  }

  Future<void> _initializeTts() async {
    // Basic TTS setup (add more config as needed)
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _initializeSpeechToText() async {
    try {
      bool available = await _speechToText.initialize(
        onError: _speechErrorListener,
        onStatus: _speechStatusListener,
        // debugLog: true, // Enable for debugging STT issues
      );
      if (available) {
        print("Speech recognition initialized successfully.");
        _startListening(); // Start listening once initialized
      } else {
        setState(() => _lastError = "Speech recognition not available.");
        _speak("Sorry, I cannot access speech recognition on this device.");
      }
    } catch (e) {
      setState(() => _lastError = "Error initializing speech: $e");
      print("Error initializing speech: $e");
    }
  }

  // --- Speech Recognition Logic ---
  void _speechErrorListener(SpeechRecognitionError error) {
    setState(() {
      _lastError = "Error: ${error.errorMsg} - Permanent: ${error.permanent}";
      _currentStatus = stt.SpeechToText.notListeningStatus; // Ensure status reflects error
    });
    print("Speech Error: $_lastError");
    // Schedule a restart even on error, unless it's permanent
    if (!error.permanent) {
      _scheduleRestart();
    } else {
      _speak("There seems to be a permanent issue with speech recognition.");
    }
  }

  void _speechStatusListener(String status) {
    setState(() => _currentStatus = status);
    print("Speech Status: $status");
    // If listening stops for any reason (completed, timeout, etc.), schedule restart
    if (status == stt.SpeechToText.notListeningStatus || status == stt.SpeechToText.doneStatus) {
      _scheduleRestart();
    }
  }

  void _speechResultListener(SpeechRecognitionResult result) {
    if (result.finalResult) { // Process only final results
      setState(() {
        _lastWords = result.recognizedWords;
        _confidence = result.hasConfidenceRating && result.confidence > 0
            ? result.confidence
            : 0.0; // Use confidence if available
      });
      print("Recognized: $_lastWords (Confidence: $_confidence)");
      _performActionCommand(_lastWords);
      // Restart is handled by the status listener when 'done' state is reached
    }
  }

  Future<void> _startListening() async {
    // Don't start if already listening or initializing
    if (_speechToText.isListening || _currentStatus == stt.SpeechToText.listeningStatus) {
      print("Already listening.");
      return;
    }
    // Cancel any pending restart
    _restartTimer?.cancel();

    try {
      // Ensure initialized before listening
      if (!_speechToText.isAvailable) {
        print("Speech recognition not available, attempting re-initialization...");
        await _initializeSpeechToText(); // Try to re-initialize
        if (!_speechToText.isAvailable) {
          setState(() => _lastError = "Speech recognition failed to initialize.");
          return; // Exit if still not available
        }
      }

      print("Starting to listen...");
      setState(() => _lastError = ""); // Clear previous errors
      await _speechToText.listen(
        onResult: _speechResultListener,
        listenFor: const Duration(minutes: 1), // Listen longer
        pauseFor: _listenPauseDuration, // Pause duration between utterances
        localeId: "en_US", // Specify locale if needed
        cancelOnError: false, // Keep listening even if one error occurs
        partialResults: false, // We only process final results
        listenMode: stt.ListenMode.confirmation, // Confirmation mode might be suitable
      );
      setState(() {}); // Update UI to reflect listening state potentially missed by status listener initially
    } catch (e) {
      setState(() => _lastError = "Error starting listener: $e");
      print("Error starting listener: $e");
      _scheduleRestart(); // Schedule restart if starting fails
    }
  }

  Future<void> _stopListening() async {
    _restartTimer?.cancel(); // Cancel any pending restart
    try {
      if (_speechToText.isListening) {
        print("Stopping listening...");
        await _speechToText.stop();
        setState(() {}); // Update UI
      }
    } catch (e) {
      setState(() => _lastError = "Error stopping listener: $e");
      print("Error stopping listener: $e");
    }
  }

  void _scheduleRestart() {
    _restartTimer?.cancel(); // Cancel previous timer if any
    _restartTimer = Timer(_restartDelay, () {
      print("Attempting to restart listener...");
      _startListening();
    });
  }

  // --- Action Commands ---
  void _performActionCommand(String command) {
    String lowerCaseCommand = command.toLowerCase();
    print("Performing action for: $lowerCaseCommand");

    if (lowerCaseCommand.contains("capture image") || lowerCaseCommand.contains("open camera")) {
      _speak("Opening camera for object detection.");
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const ObjectDetectionScreen(), // Ensure this screen exists
      ));
    } else if (lowerCaseCommand.contains("what is") && lowerCaseCommand.contains("time")) {
      _handleTimeRequest();
    } else if (lowerCaseCommand.contains("what is") && lowerCaseCommand.contains("weather")) {
      _handleWeatherRequest();
    } else if (lowerCaseCommand.contains("what is") && lowerCaseCommand.contains("today")) {
      _handleTodayRequest();
    } else if (lowerCaseCommand.contains("exit app") || lowerCaseCommand.contains("close app")) {
      _handleExitRequest();
    } else if (lowerCaseCommand.contains("open chat")) {
      _handleOpenChatRequest();
    }
    // Add more commands here
    // else {
    //   _speak("Sorry, I didn't understand the command: $command");
    // }
  }

  void _handleTimeRequest() {
    final now = DateTime.now();
    final timeString = DateFormat('hh:mm a').format(now);
    _updateDateTime(); // Update the full date display
    _updateDayNightState(); // Also update day/night
    _speak("The current time is $timeString");
  }

  void _handleWeatherRequest() async {
    _speak("Fetching weather information for ${_weatherCities.join(' and ')}...");
    setState(() {
      _currentWeatherString = "Fetching weather..."; // Update UI
    });
    try {
      List<Future<WeatherInfo?>> weatherFutures = _weatherCities
          .map((city) => _fetchWeatherForCity(city))
          .toList();

      List<WeatherInfo?> weatherResults = await Future.wait(weatherFutures);
      List<String> weatherSummaries = [];
      String uiWeatherString = "Weather data unavailable";

      for (int i = 0; i < weatherResults.length; i++) {
        final info = weatherResults[i];
        if (info != null) {
          weatherSummaries.add(info.toString());
          // Update UI with the first available city's weather
          if (uiWeatherString == "Weather data unavailable") {
            uiWeatherString = info.toString();
          }
        } else {
          weatherSummaries.add("${_weatherCities[i]}: Could not fetch weather");
        }
      }

      setState(() {
        _currentWeatherString = uiWeatherString; // Update UI card
      });
      _speak(weatherSummaries.join('. ')); // Read all summaries

    } catch (e) {
      print("Error handling weather request: $e");
      setState(() {
        _currentWeatherString = "Error fetching weather";
      });
      _speak("Sorry, I couldn't fetch the weather information.");
    }
  }

  void _handleTodayRequest() {
    final now = DateTime.now();
    final dayString = DateFormat('EEEE').format(now); // EEEE gives full day name
    _speak("Today is $dayString");
  }

  void _handleExitRequest() {
    _speak("Closing the application. Goodbye!");
    Future.delayed(const Duration(milliseconds: 500), () {
      SystemNavigator.pop(); // Close the app
    });
  }

  void _handleOpenChatRequest() {
    _speak("Opening the chat assistant.");
    Navigator.pushNamed(context, ChatScreen.route); // Use named route
  }

  // --- Data Fetching & Updates ---
  void _updateDateTime() {
    setState(() {
      _currentDateString =
          DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now());
    });
  }

  void _updateDayNightState() {
    final hour = DateTime.now().hour;
    // Simple Day/Night logic (adjust thresholds as needed)
    // 6 AM (inclusive) to 7 PM (exclusive) is considered day
    bool isDayTime = hour >= 6 && hour < 19;
    setState(() {
      _dayNightState = isDayTime ? "Day" : "Night";
    });
  }

  Future<void> _fetchInitialWeather() async {
    // Fetch weather for the first city initially for the UI card
    if (_weatherCities.isNotEmpty) {
      try {
        final weather = await _fetchWeatherForCity(_weatherCities.first);
        if (weather != null && mounted) {
          setState(() {
            _currentWeatherString = weather.toString();
          });
        }
      } catch (e) {
        print("Error fetching initial weather: $e");
        if (mounted) {
          setState(() {
            _currentWeatherString = "Weather data unavailable";
          });
        }
      }
    }
  }


  Future<WeatherInfo?> _fetchWeatherForCity(String city) async {
    if (_openWeatherApiKey == "YOUR_OPENWEATHERMAP_API_KEY") {
      print("OpenWeatherMap API Key not set!");
      // Optionally speak an error or just return null
      // _speak("Weather API Key is missing.");
      return null;
    }

    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$_openWeatherApiKey&units=metric');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherInfo(
          city: data['name'],
          description: data['weather'][0]['description'] ?? 'Unknown',
          temperature: (data['main']['temp'] as num?)?.toDouble() ?? 0.0,
        );
      } else {
        print(
            'Error fetching weather for $city: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Network error fetching weather for $city: $e');
      return null;
    }
  }

  // --- Text-to-Speech ---
  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      try {
        await _flutterTts.speak(text);
      } catch (e) {
        print("Error speaking: $e");
      }
    }
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    bool isCurrentlyListening = _currentStatus == stt.SpeechToText.listeningStatus;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[850], // Dark background
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "Smart Vision",
                style: AppTextStyles.headline1.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Voice Input Container
              _buildVoiceInputCard(isCurrentlyListening),
              if (_lastError.isNotEmpty) // Show errors if any
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _lastError,
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              // Grid of Info Cards
              _buildInfoGrid(),
              const SizedBox(height: 16),

              // Detected Objects Card
              _buildDetectedObjectsCard(),
              const SizedBox(height: 16),

              // Mic Button (Centred)
              Center(child: _buildMicButton(isCurrentlyListening)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceInputCard(bool isCurrentlyListening) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentlyListening ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Voice Input",
                style: AppTextStyles.headline2
                    .copyWith(fontSize: 14, color: Colors.grey[400]),
              ),
              _buildListeningIndicator(isCurrentlyListening),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _lastWords,
            style: AppTextStyles.bodyText
                .copyWith(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 12),
          if (isCurrentlyListening || _confidence > 0) ...[
            LinearProgressIndicator(
              value: _confidence,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              "Confidence: ${(_confidence * 100).toStringAsFixed(1)}%",
              style: AppTextStyles.bodyText
                  .copyWith(fontSize: 12, color: Colors.grey[400]),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildListeningIndicator(bool isCurrentlyListening) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentlyListening ? AppColors.primary : Colors.grey[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCurrentlyListening ? Icons.mic : Icons.mic_off,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isCurrentlyListening ? "LISTENING" : "IDLE",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3, // Adjusted aspect ratio slightly
      children: [
        _buildInfoCard(
            "Date & Time", _currentDateString, Icons.calendar_today),
        _buildInfoCard("Day/Night", _dayNightState,
            _dayNightState == "Day" ? Icons.wb_sunny : Icons.nights_stay),
        _buildInfoCard("Currency", _detectedCurrency, Icons.attach_money),
        _buildInfoCard("Weather", _currentWeatherString, Icons.cloud_queue), // Different Icon
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align content
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.headline2
                      .copyWith(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
            // Flexible helps text wrap gracefully if needed
            Flexible(
              child: Text(
                value,
                style: AppTextStyles.bodyText.copyWith(
                  fontSize: 16, // Slightly smaller for grid
                  fontWeight: FontWeight.w600, // Semi-bold
                  color: Colors.white,
                ),
                maxLines: 3, // Limit lines
                overflow: TextOverflow.ellipsis, // Handle overflow
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectedObjectsCard() {
    return Card(
      elevation: 4,
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.category_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      "Detected Objects",
                      style: AppTextStyles.headline2
                          .copyWith(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
                // Using TextButton for clearer action
                TextButton.icon(
                  icon: Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.primary),
                  label: Text("Open Camera", style: TextStyle(color: AppColors.primary)),
                  onPressed: () {
                    _speak("Opening camera."); // Feedback before navigation
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ObjectDetectionScreen()));
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                )
              ],
            ),
            const SizedBox(height: 12),
            if (_detectedObjects.isEmpty || _detectedObjects.first == "No objects detected")
              Text("No objects detected yet.", style: TextStyle(color: Colors.grey[500]))
            else
              Wrap( // Use Wrap for multiple chips
                spacing: 8,
                runSpacing: 4,
                children: _detectedObjects.map((object) {
                  return Chip(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    label: Text(object, style: TextStyle(color: AppColors.primary)),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Smaller tap target
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton(bool isCurrentlyListening) {
    return GestureDetector(
      onTap: isCurrentlyListening ? _stopListening : _startListening,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isCurrentlyListening ? AppColors.primary.withOpacity(0.8) : Colors.grey[700],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isCurrentlyListening ? AppColors.primary : Colors.black).withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isCurrentlyListening ? Icons.mic : Icons.mic_none,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }
}