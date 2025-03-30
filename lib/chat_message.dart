// lib/chat_message.dart

// Define the possible senders for a message
enum Sender { user, ai }

class ChatMessage {
  final String text;          // The content of the message
  final Sender sender;        // Who sent the message (User or AI)
  final DateTime timestamp;   // When the message was created/sent
  final bool isError;       // Flag to indicate if this message represents an error

  ChatMessage({
    required this.text,
    required this.sender,
    DateTime? timestamp,    // Timestamp is optional during creation
    this.isError = false,   // isError is optional, defaulting to false
  }) : timestamp = timestamp ?? DateTime.now(); // Assign current time if timestamp is null
}