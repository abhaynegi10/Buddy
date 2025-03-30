// homepage.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:txt_to_img/gemini_service.dart';
import 'dart:io';
// Removed: import 'package:txt_to_img/gemini_chat_page.dart'; // No longer navigating from here

class Homepage extends StatefulWidget {
  // No longer needs to be const if you remove const from _widgetOptions in main_screen
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  File? _image;
  String? _description;
  bool _isLoading = false;
  final _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _wordCountController = TextEditingController();
  int _desiredWordCount = 50;

  @override
  void initState() {
    super.initState();
    _wordCountController.text = _desiredWordCount.toString();
  }

  @override
  void dispose() {
    _wordCountController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Use theme's error color for consistency, or keep it explicit
        // backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;
    // Reset state
    setState(() {
      _image = null;
      _description = null;
      _isLoading = false; // Ensure loading is false before picking
    });

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxHeight: 1024,
        maxWidth: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _image = File(pickedFile.path);
        });
        await _analyzeImage(); // Analyze immediately
      } else {
        print("Image picking cancelled.");
      }
    } catch (e) {
      print("Error picking image: $e");
      _showErrorSnackBar("Failed to pick image: ${e.toString()}");
    } finally {
        // Ensure loading indicator is off if something went wrong *during* picking
        if (mounted && _isLoading) {
             setState(() => _isLoading = false);
        }
    }
  }

 Future<void> _analyzeImage() async {
    if (_image == null || !mounted) return;

    // --- Parse word count ---
    final currentText = _wordCountController.text.trim();
    int wordCount = _desiredWordCount; // Use current state as fallback
    if (currentText.isNotEmpty) {
      final parsedCount = int.tryParse(currentText);
      if (parsedCount != null && parsedCount > 0) {
        wordCount = parsedCount;
        // Update state if parse successful and different
        if (_desiredWordCount != wordCount) {
            // No need to call setState just for this internal variable change
             _desiredWordCount = wordCount;
        }
      } else {
        print("Invalid word count input: '$currentText'. Using previous: $_desiredWordCount");
        _showErrorSnackBar("Invalid word count. Using $_desiredWordCount words.");
        _wordCountController.text = _desiredWordCount.toString(); // Reset field
      }
    } else {
      print("Word count input empty. Using previous: $_desiredWordCount");
      _wordCountController.text = _desiredWordCount.toString(); // Reset field
    }
     // --- End Parse word count ---


    setState(() {
      _isLoading = true;
      _description = null;
    });

    try {
      final description = await _geminiService.analyzeImage(_image!, wordCount);
      if (!mounted) return;
      setState(() {
        _description = description;
        // isLoading = false; // Keep loading true until display? No, set false here.
      });
    } catch (e) {
      print("Error analyzing image: $e");
      if (!mounted) return;
      _showErrorSnackBar("Analysis failed: ${e.toString()}");
    } finally {
      // Ensure loading is always turned off, even on error
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

    // Use SafeArea to avoid overlap with status bar/notches
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Image Display Area ---
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12.0),
                  // Slightly different background for contrast
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                   boxShadow: [ // Add a subtle shadow
                     BoxShadow(
                       color: Colors.black.withOpacity(0.2),
                       blurRadius: 4,
                       offset: const Offset(0, 2),
                     )
                   ]
                ),
                child: Center(child: _buildImageDisplay(colorScheme)),
              ),
            ),

            const SizedBox(height: 16.0),

            // --- Description Area ---
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                   border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                   borderRadius: BorderRadius.circular(12.0),
                   color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    boxShadow: [ // Add a subtle shadow
                     BoxShadow(
                       color: Colors.black.withOpacity(0.2),
                       blurRadius: 4,
                       offset: const Offset(0, 2),
                     )
                   ]
                ),
                child: _buildDescriptionDisplay(theme),
              ),
            ),

            const SizedBox(height: 16.0),

            // --- Word Count Input ---
// homepage.dart
// ... inside the build method ...

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _wordCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                    // SHORTER LABEL:
                    labelText: 'Word Count',
                    // Keep hint text for guidance
                    hintText: 'Approx. 50',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.refresh, color: colorScheme.secondary),
                      tooltip: 'Reset to default (50)',
                      onPressed: () {
                        setState(() {
                          _desiredWordCount = 50;
                          _wordCountController.text = _desiredWordCount.toString();
                        });
                        FocusScope.of(context).unfocus();
                      },
                    )),
                onSubmitted: (_) {
                  if (_image != null && !_isLoading) {
                    _analyzeImage();
                  }
                },
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
// ... rest of the code ...

            const SizedBox(height: 16.0),

            // --- Action Buttons ---
            _buildActionButtons(theme), // Pass theme for potential styling

            const SizedBox(height: 10.0), // Reduce bottom padding slightly
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildImageDisplay(ColorScheme colorScheme) {
    // ... (Keep existing code, it should work fine with dark theme)
     if (_image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11.0), // Match container radius - 1
        child: Image(
          image: FileImage(_image!),
          fit: BoxFit.contain, // Contain keeps aspect ratio
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null &&
                        loadingProgress.expectedTotalBytes! > 0
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                 strokeWidth: 3.0,
                 valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary), // Use theme color
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined, color: colorScheme.error, size: 40),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Error loading image file',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Placeholder - make it look nicer
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_search_outlined,
              size: 60,
              color: colorScheme.secondary.withOpacity(0.7), // Use secondary color
            ),
            const SizedBox(height: 12),
            Text(
              'Select an image using the buttons below',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDescriptionDisplay(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    if (_isLoading) {
      // Use a potentially nicer loading indicator if flutter_spinkit is added
      // return Center(child: SpinKitFadingCircle(color: colorScheme.primary));
      return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary)));
    } else if (_description != null) {
      return SingleChildScrollView(
        child: Text(
          _description!,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface, // Ensure text is readable
            height: 1.4, // Improve line spacing
          ),
        ),
      );
    } else if (_image != null && !_isLoading) {
        // Changed this message slightly
      return Center(
          child: Text(
        'Ready for analysis.\n(Tap buttons again to change image)',
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ));
    } else {
      // Placeholder - make it look nicer
      return Center(
        child: Text(
          'Image description will appear here.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.8), fontSize: 15),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  Widget _buildActionButtons(ThemeData theme) {
    // Buttons now use the global theme styling from main.dart
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt_outlined), // Use outlined icon
          label: const Text("Take Photo"),
          onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
          // Style can be overridden here if needed:
          // style: ElevatedButton.styleFrom(...)
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.photo_library_outlined), // Use outlined icon
          label: const Text("Choose Photo"),
          onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }
}