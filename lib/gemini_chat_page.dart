// lib/gemini_chat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // For post frame callback
import 'package:txt_to_img/chat_message.dart'; // Import the model
import 'package:txt_to_img/gemini_service.dart'; // Import the service

class GeminiChatPage extends StatefulWidget {
  const GeminiChatPage({super.key});

  @override
  State<GeminiChatPage> createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // To scroll list
  final GeminiService _geminiService = GeminiService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Optional: Add a default welcome message from the AI
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted && _messages.isEmpty) { // Add only if list is empty
          setState(() {
             _messages.add(ChatMessage(text: "Hello! How can I help you today?", sender: Sender.ai));
          });
       }
    });
  }


  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Function to scroll to the bottom of the list
  void _scrollToBottom() {
    // Needs to be scheduled after the frame is built
    SchedulerBinding.instance.addPostFrameCallback((_) {
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
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return; // Don't send empty or while loading

    final userMessage = ChatMessage(text: text, sender: Sender.user);

    setState(() {
      _messages.add(userMessage);
      _isLoading = true; // Start loading
    });
    _textController.clear(); // Clear input field
    _scrollToBottom(); // Scroll down after adding user message

    try {
      // Call the Gemini text generation service
      final aiResponse = await _geminiService.generateText(text);

      if (!mounted) return; // Check if widget is still alive

      // Add AI response
      final aiMessage = ChatMessage(text: aiResponse, sender: Sender.ai);
      setState(() {
        _messages.add(aiMessage);
        // isLoading = false; // Moved to finally block
      });
       _scrollToBottom(); // Scroll down after adding AI message

    } catch (e) {
       print("Error sending message: $e");
       if (!mounted) return;

       // Add an error message to the chat
       final errorMessage = ChatMessage(
             // Provide a user-friendly error message
             text: "Sorry, I encountered an error. Please try again. ($e)",
             sender: Sender.ai, // Display error as if from AI
             isError: true); // Add an error flag if needed for styling

      setState(() {
        _messages.add(errorMessage);
        // isLoading = false; // Moved to finally block
      });
      _scrollToBottom();
      // Optional: Show a SnackBar as well using the theme's snackbar style
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error contacting assistant: ${e.toString()}"),
        // backgroundColor: Theme.of(context).colorScheme.error, // Or use default SnackBar theme
      ));
    } finally {
       // Ensure loading is always turned off
       if (mounted) {
          setState(() {
             _isLoading = false;
          });
       }
    }
 }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use SafeArea to avoid status bar overlap now that AppBar is removed
    return SafeArea(
      child: Scaffold(
        // REMOVED the AppBar - it's handled by MainScreen or not needed
        // appBar: AppBar(
        //   title: const Text('Gemini Assistant'),
        //   backgroundColor: colorScheme.primaryContainer, // Use themed color
        // ),

        // Scaffold background color will be inherited from the theme's scaffoldBackgroundColor
        body: Column(
          children: [
            // --- Message List ---
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  // Pass the theme data for consistent styling
                  return _buildMessageBubble(message, theme);
                },
              ),
            ),

            // --- Loading Indicator (Thinking...) ---
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                child: Row( // Simple "typing" indicator
                  mainAxisAlignment: MainAxisAlignment.start, // Align left for AI
                  children: [
                    SizedBox(
                      width: 16, height: 16, // Small size
                      child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary), // Use theme color
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                       "Thinking...",
                       style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

            // --- Input Area ---
            Padding(
              // Add more bottom padding to avoid overlap with nav bar potentially
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 12.0),
              child: Container(
                 decoration: BoxDecoration(
                   // Use a color that fits the dark theme well
                   color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
                   borderRadius: BorderRadius.circular(25.0),
                   boxShadow: [ // Add subtle shadow for depth in dark theme
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      )
                   ]
                 ),
                padding: const EdgeInsets.symmetric(horizontal: 8.0), // Padding inside container
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end, // Align bottom for multi-line
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Ask Gemini...',
                          filled: false,
                          border: InputBorder.none, // Remove default border
                          contentPadding: const EdgeInsets.symmetric(
                             horizontal: 16.0, vertical: 12.0 // Adjusted padding
                          ),
                          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                        ),
                        style: TextStyle(color: colorScheme.onSurface), // Make sure input text is visible
                        onSubmitted: (_) => _sendMessage(), // Send on keyboard 'done'
                        enabled: !_isLoading, // Disable input while loading
                        minLines: 1, // Allow multi-line input
                        maxLines: 5,
                        textInputAction: TextInputAction.send, // Set keyboard action
                      ),
                    ),
                    // Loading indicator *inside* the input area (optional)
                    // if (_isLoading)
                    //    Padding(
                    //      padding: const EdgeInsets.all(12.0),
                    //      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    //    )
                    // else
                    Padding( // Ensure button aligns with multi-line text field
                      padding: const EdgeInsets.only(bottom: 4.0), // Adjust padding slightly
                      child: IconButton(
                          icon: Icon(Icons.send_rounded, color: colorScheme.primary), // Use rounded icon
                          tooltip: 'Send Message',
                          // Disable button while loading
                          onPressed: _isLoading ? null : _sendMessage,
                        ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build individual message bubbles
  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    bool isUser = message.sender == Sender.user;

    // Choose colors appropriate for the dark theme
    // primaryContainer might be too bright in dark theme, consider primary or surface variant
    final bubbleColor = isUser
        ? colorScheme.primary // More prominent color for user
        : colorScheme.surfaceContainerHighest.withOpacity(0.8); // Subtler dark grey for AI

    final textColor = isUser
        ? colorScheme.onPrimary // Text color contrasting with primary
        : colorScheme.onSurfaceVariant; // Text color contrasting with surfaceVariant

    // Differentiate error messages visually if needed
    final errorColor = colorScheme.error; // Theme's error color

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          // Max width prevents bubbles from spanning the whole screen
          maxWidth: MediaQuery.of(context).size.width * 0.78, // Slightly wider allowed
        ),
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          // Use error color for bubble background if message.isError is true
          color: message.isError ? errorColor.withOpacity(0.5) : bubbleColor,
          borderRadius: BorderRadius.only(
             topLeft: const Radius.circular(18.0),
             topRight: const Radius.circular(18.0),
             // Slightly different corner radii for a "tail" effect
             bottomLeft: isUser ? const Radius.circular(18.0) : const Radius.circular(4.0),
             bottomRight: isUser ? const Radius.circular(4.0) : const Radius.circular(18.0),
          ),
           boxShadow: [ // Softer shadow suitable for dark theme
             BoxShadow(
               color: Colors.black.withOpacity(0.3), // Slightly stronger shadow
               blurRadius: 4,
               offset: const Offset(1, 2), // Adjust offset slightly
             )
           ],
        ),
        child: SelectableText( // Allow copying text
          message.text,
          style: TextStyle(
             // Use appropriate contrast color, maybe make error text bolder or different color
             color: message.isError ? colorScheme.onError.withOpacity(0.9) : textColor,
             fontSize: 15, // Slightly larger text
             fontWeight: message.isError ? FontWeight.w500 : FontWeight.normal,
             height: 1.3, // Improve line spacing
          ),
        ),
      ),
    );
  }
}

// Ensure your chat_message.dart defines Sender and includes the isError field:


