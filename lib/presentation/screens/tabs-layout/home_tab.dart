import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late stt.SpeechToText _speechToText;
  String lastWords = "Press the mic button to start speaking...";
  double _confidence = 0.0;
  bool _isListening = false;

  // Mock data for UI
  String currentDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());
  String dayNightState = "Day";
  String detectedCurrency = "\$0.00";
  String detectedObjects = "No objects detected";
  String currentWeather = "Sunny, 25°C";

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initializeSpeechToText();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _speechToText.cancel();
    super.dispose();
  }

  Future<void> _initializeSpeechToText() async {
    bool initialized = await _speechToText.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (error) => print('onError: $error'),
    );

    if (initialized) {
      _startListening();
    } else {
      print("Speech-to-Text initialization failed");
    }
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: Duration(seconds: 5),
        pauseFor: Duration(seconds: 2),
      );
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      await _speechToText.stop();
    }
  }

  void _onSpeechResult(result) {
    setState(() {
      lastWords = result.recognizedWords;
      _confidence = result.confidence;
    });

    _performActions(lastWords);
    _stopAndRestartListening();
  }

  void _performActions(String recognizedText) {
    if (recognizedText.toLowerCase().contains("time")) {
      setState(() {
        currentDate = DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now());
      });
    }

    if (recognizedText.toLowerCase().contains("weather")) {
      setState(() {
        currentWeather = "Cloudy, 22°C";
      });
    }

    if (recognizedText.toLowerCase().contains("day") || recognizedText.toLowerCase().contains("night")) {
      setState(() {
        dayNightState = recognizedText.toLowerCase().contains("day") ? "Day" : "Night";
      });
    }

    if (recognizedText.toLowerCase().contains("currency")) {
      setState(() {
        detectedCurrency = "\$10.00";
      });
    }

    if (recognizedText.toLowerCase().contains("object")) {
      setState(() {
        detectedObjects = "Chair, Table, Bottle";
      });
    }
  }

  void _stopAndRestartListening() async {
    await _stopListening();
    await Future.delayed(Duration(seconds: 2));
    _startListening();
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      color: Colors.grey[900], // Dark card background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.headline2.copyWith(
                    fontSize: 14,
                    color: Colors.grey[400], // Lighter text for dark background
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.bodyText.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text for better contrast
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[850], // Dark background
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title
              Text(
                "Smart Vision",
                style: AppTextStyles.headline1.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),

              // Full-width speech container
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900], // Dark container
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isListening ? AppColors.primary : Colors.transparent,
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
                          style: AppTextStyles.headline2.copyWith(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isListening ? AppColors.primary : Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isListening ? Icons.mic : Icons.mic_off,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _isListening ? "LISTENING" : "OFF",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      lastWords,
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _confidence,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Confidence: ${(_confidence * 100).toStringAsFixed(1)}%",
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Grid of info cards
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildInfoCard("Date & Time", currentDate, Icons.calendar_today),
                  _buildInfoCard("Day/Night", dayNightState, dayNightState == "Day" ? Icons.wb_sunny : Icons.nights_stay),
                  _buildInfoCard("Currency", detectedCurrency, Icons.attach_money),
                  _buildInfoCard("Weather", currentWeather, Icons.cloud),
                ],
              ),
              SizedBox(height: 16),

              // Detected Objects Card
              Card(
                elevation: 4,
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category, size: 20, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            "Detected Objects",
                            style: AppTextStyles.headline2.copyWith(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: detectedObjects.split(", ").map((object) {
                          return Chip(
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            label: Text(
                              object,
                              style: TextStyle(
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Mic Button
              Center(
                child: GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _isListening ? AppColors.primary : Colors.grey[800],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}