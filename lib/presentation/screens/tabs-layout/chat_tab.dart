import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import the http package

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// --- ChatMessage Class (remains the same) ---
class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

// --- ChatScreen Widget ---
class ChatScreen extends StatefulWidget {
  static const route = '/chat';
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // To scroll list
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I'm your Gemini assistant. How can I assist you today?",
      isUser: false,
      time: DateTime(2025).toIso8601String(), // Initial time
    ),
  ];
  bool _isLoading = false; // To show a loading indicator

  // --- IMPORTANT: Replace with your actual API Key ---
  // --- For production, use secure methods like environment variables ---
  final String _apiKey = "AIzaSyCCjHe3xKl1u6f9WOIOsfeuOtHlqsueotY";
  final String _model = "gemini-1.5-flash-latest"; // Or another suitable model

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose(); // Dispose scroll controller
    super.dispose();
  }

  // Helper function to scroll to the bottom
  void _scrollToBottom() {
    // Use WidgetsBinding.instance.addPostFrameCallback for scrolling after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // 1. Add user message immediately
    setState(() {
      _messages.add(
        ChatMessage(
          text: messageText,
          isUser: true,
          time: TimeOfDay.now().format(context),
        ),
      );
      _isLoading = true; // Start loading
    });

    _messageController.clear();
    _scrollToBottom(); // Scroll after adding user message

    // 2. Get response from Gemini API
    try {
      final response = await _getGeminiResponse(messageText);
      // 3. Add Gemini response
      setState(() {
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            time: TimeOfDay.now().format(context),
          ),
        );
      });
    } catch (e) {
      // 4. Handle errors (e.g., show an error message)
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry, I couldn't get a response. Error: $e",
            isUser: false,
            time: TimeOfDay.now().format(context),
          ),
        );
      });
      print("Error fetching Gemini response: $e"); // Log error
    } finally {
      // 5. Stop loading and scroll
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom(); // Scroll after adding bot message or error
    }
  }

  // --- Function to call Gemini API ---
  Future<String> _getGeminiResponse(String userMessage) async {
    if (_apiKey == "YOUR_GEMINI_API_KEY") {
      return "Please replace 'YOUR_GEMINI_API_KEY' with your actual API key in the code.";
    }

    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey");

    final headers = {'Content-Type': 'application/json'};

    // --- Basic Request Body ---
    // For more conversational context, you might want to send previous messages too.
    // See Gemini API documentation for structuring conversational history.
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": userMessage}
          ]
        }
      ],
      // Optional: Add safety settings if needed
      // "safetySettings": [
      //   {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
      //   {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
      //   {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
      //   {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"}
      // ],
      // Optional: Add generation config if needed
      // "generationConfig": {
      //   "temperature": 0.9,
      //   "topK": 1,
      //   "topP": 1,
      //   "maxOutputTokens": 2048,
      // }
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // --- Safely extract the text ---
        // Structure: responseBody['candidates'][0]['content']['parts'][0]['text']
        final candidates = responseBody['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map?;
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null) {
                return text.trim();
              }
            }
          }
        }
        // Handle cases where the expected structure is missing or block reasons
        if (responseBody['promptFeedback']?['blockReason'] != null) {
          return "Blocked: ${responseBody['promptFeedback']['blockReason']}";
        }
        return "Sorry, I received an unexpected response format.";

      } else {
        // Handle API errors
        print("API Error: ${response.statusCode}");
        print("API Response: ${response.body}");
        return "Sorry, there was an error communicating with the AI (${response.statusCode}).";
      }
    } catch (e) {
      // Handle network or other errors
      print("Network/Request Error: $e");
      throw Exception("Failed to connect to the AI service."); // Rethrow or return error string
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Gemini Assistant", // Updated title
          style: AppTextStyles.headline2.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Assign scroll controller
              padding: const EdgeInsets.all(16),
              // reverse: false, // Keep false if you want oldest messages at top
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          // Optional: Show a typing indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Gemini is thinking...",
                    style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // --- _buildMessageBubble (remains largely the same) ---
  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
        message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Bot Avatar
          if (!message.isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Icon( // Using a different icon for Gemini potentially
                  Icons.auto_awesome, // Example: Use a "sparkle" icon for AI
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          // Message Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : Colors.grey[800], // Bot message color
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 0),
                  bottomRight: Radius.circular(message.isUser ? 0 : 20),
                ),
                boxShadow: [ // Subtle shadow for depth
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: AppTextStyles.bodyText.copyWith( // Use defined style
                      color: message.isUser ? Colors.white : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5), // Slightly more space
                  Text(
                    message.time,
                    style: AppTextStyles.bodyText.copyWith( // Use defined style
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[400],
                      fontSize: 10, // Keep explicit size for time
                    ),
                  ),
                ],
              ),
            ),
          ),
          // User Avatar
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: Colors.grey[700],
                child: const Icon(
                  Icons.person_outline, // Outline icon
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- _buildMessageInput (remains largely the same) ---
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 12), // Adjust padding
      decoration: BoxDecoration(
          color: Colors.grey[900],
          boxShadow: [ // Add shadow to input area too
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            )
          ]
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: AppTextStyles.bodyText.copyWith(color: Colors.white), // Use text style
              textInputAction: TextInputAction.send, // Add send action to keyboard
              onSubmitted: (_) => _isLoading ? null : _sendMessage(), // Allow sending via keyboard
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: AppTextStyles.bodyText.copyWith(color: Colors.grey[500]), // Use text style
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Use IconButton for better semantics and splash effect
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading ? null : _sendMessage, // Disable button when loading
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.all(12), // Adjust padding if needed
              shape: const CircleBorder(), // Ensure it's circular
            ),
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }
}