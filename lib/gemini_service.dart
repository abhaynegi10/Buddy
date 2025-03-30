// gemini_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'dart:math';

// Import the secrets file
import 'secrets.dart'; // Make sure this path is correct

class GeminiService {
  // Shared base URL remains the same
  final String _baseGenerateContentUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  // --- API Key is now fetched from secrets.dart ---
  // Note: The hardcoded key line has been REMOVED.

  // --- Example method (can be removed if not used) ---
  // This demonstrates accessing the key but isn't used by analyzeImage/generateText below
  void testAccessApiKey() {
    // Access the key safely via the SecretKeys class
    String apiKey = SecretKeys.geminiApiKey;
    print('Attempting to use API Key (should not print actual key in production)');
    // Avoid printing the key itself in real applications
    // print('Using API Key: $apiKey');
  }


  // Method for Image Analysis (Updated to use SecretKeys)
  Future<String> analyzeImage(File image, int desiredWordCount) async {
    // --- Get the API Key from SecretKeys ---
    const String apiKey = SecretKeys.geminiApiKey;

    // --- Add a check for the placeholder value (important!) ---
    // Replace 'YOUR_GEMINI_API_KEY_HERE' with the actual placeholder
    // string you use in your `secrets.dart.example` file.
    if (apiKey == 'YOUR_GEMINI_API_KEY_HERE' || apiKey.isEmpty) {
       throw Exception(
          "Gemini API Key not configured in lib/secrets.dart. "
          "Please copy lib/secrets.dart.example to lib/secrets.dart "
          "and add your real API key."
        );
    }

    final effectiveWordCount = max(10, desiredWordCount); // Ensure minimum word count

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg'; // Fallback MIME type

      // --- Use the apiKey variable fetched from SecretKeys ---
      final uri = Uri.parse('$_baseGenerateContentUrl?key=$apiKey');

      final String promptText =
          'Please describe this image in approximately $effectiveWordCount words.';
      // Estimate max tokens needed - adjust multiplier as needed
      final int maxTokens = (effectiveWordCount * 1.8).ceil();

      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': promptText},
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Image}
              }
            ]
          }
        ],
        'generationConfig': {"maxOutputTokens": maxTokens},
        // Consider adding safetySettings here too if needed for image analysis
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Safe navigation for response text
        return data['candidates']?[0]?['content']?['parts']?[0]?['text']
                ?.toString() ??
            "Sorry, I couldn't generate a description for the image.";
      } else {
        // Improved error reporting
        String errorBody = response.body;
        try {
           final errorJson = jsonDecode(response.body);
           errorBody = errorJson['error']?['message'] ?? response.body;
        } catch(_) {/* Keep original body if JSON parsing fails */}
        print("Gemini API Error (Image Analysis - Status ${response.statusCode}): $errorBody");
        throw Exception(
            "Failed image analysis. Status: ${response.statusCode}. Error: $errorBody");
      }
    } catch (e) {
      print("Error during image analysis network call or processing: $e");
      // Re-throw the exception or handle it more specifically
      throw Exception("An error occurred during image analysis: ${e.toString()}");
    }
  }


  // --- Method for Text Generation (Updated to use SecretKeys) ---
  Future<String> generateText(String prompt) async {
    // --- Get the API Key from SecretKeys ---
    const String apiKey = SecretKeys.geminiApiKey;

    // --- Add a check for the placeholder value (important!) ---
     if (apiKey == 'YOUR_GEMINI_API_KEY_HERE' || apiKey.isEmpty) {
       throw Exception(
          "Gemini API Key not configured in lib/secrets.dart. "
          "Please copy lib/secrets.dart.example to lib/secrets.dart "
          "and add your real API key."
        );
    }

    try {
       // --- Use the apiKey variable fetched from SecretKeys ---
      final uri = Uri.parse('$_baseGenerateContentUrl?key=$apiKey');

      // Construct request body ONLY with text
      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}, // Only the user's text prompt
            ]
          }
        ],
        'generationConfig': {
          "maxOutputTokens": 800, // Increased tokens for potentially longer chat
          "temperature": 0.7,
          // "topP": 0.9, // Uncomment/adjust if needed
          // "topK": 40,  // Uncomment/adjust if needed
        },
        'safetySettings': [ // Keep or adjust safety settings as required
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
          {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
          {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        ]
      });

      print("Sending text request to Gemini..."); // Avoid logging prompt in production if sensitive
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // print("Gemini Text Response Body: ${response.body}"); // Debugging only

        // Parse the text response
        String? text = data['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString();

        // Handle potential blocking or empty response gracefully
        if (text != null && text.isNotEmpty) {
          return text;
        } else if (data['promptFeedback']?['blockReason'] != null) {
          print("Gemini Response blocked due to: ${data['promptFeedback']['blockReason']}");
          return "My response was blocked due to safety settings (${data['promptFeedback']['blockReason']}). Please try phrasing your request differently.";
        } else if (data['candidates']?[0]?['finishReason'] != null && data['candidates'][0]['finishReason'] != 'STOP') {
           print("Gemini response finish reason: ${data['candidates'][0]['finishReason']}");
           return "The response might be incomplete. (Reason: ${data['candidates'][0]['finishReason']})";
        } else {
           print("Gemini returned an empty text response.");
           return "Sorry, I received an empty response. Could you try asking in a different way?";
        }
      } else {
        // Improved error reporting for text generation
        String errorBody = response.body;
        try {
           final errorJson = jsonDecode(response.body);
           errorBody = errorJson['error']?['message'] ?? response.body;
        } catch(_) {/* Keep original body */}
        print("Gemini API Error (Text Generation - Status ${response.statusCode}): $errorBody");
        throw Exception(
            "Failed text generation. Status: ${response.statusCode}. Error: $errorBody");
      }
    } catch (e) {
      print("Error during text generation network call or processing: $e");
      throw Exception("Failed to contact the AI assistant. Please check your connection or try again later.");
    }
  }
}