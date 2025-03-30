// main.dart
import 'package:flutter/material.dart';
// Import the MainScreen which handles navigation
import 'package:txt_to_img/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Assistant', // Updated title
      debugShowCheckedModeBanner: false, // Hide debug banner

      // --- Dark Theme Configuration ---
      themeMode: ThemeMode.dark, // Enforce dark mode
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        // Define the color scheme for the dark theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, // Or your preferred dark theme seed color
          brightness: Brightness.dark,
          // Optional: Fine-tune specific dark theme colors
          // surface: Colors.grey[850], // Slightly lighter than background
          // background: Colors.grey[900], // Base dark background
          // primary: Colors.deepPurpleAccent[100], // Lighter purple for primary elements
          // secondary: Colors.tealAccent[100],     // Lighter teal for secondary elements
        ),
        useMaterial3: true, // Recommended for modern UI elements

        // --- Customize specific components for dark theme ---

        // Base scaffold background color
        scaffoldBackgroundColor: const Color(0xFF121212), // Common dark background

        // Style ElevatedButtons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Text color on button
            backgroundColor: Colors.deepPurpleAccent.withOpacity(0.8), // Button background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 3, // Add subtle elevation
          ),
        ),

        // Style InputFields (like the word count TextField)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800]?.withOpacity(0.6), // Semi-transparent dark fill
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none, // No border by default
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.deepPurpleAccent[100]!, width: 1.5), // Highlight border when focused
          ),
          labelStyle: TextStyle(color: Colors.grey[400]), // Label color
          hintStyle: TextStyle(color: Colors.grey[600]), // Hint text color
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), // Adjust padding
        ),

        // Style the main AppBar if MainScreen uses one (optional)
        appBarTheme: AppBarTheme(
           backgroundColor: Colors.grey[900]?.withOpacity(0.85), // Dark, slightly transparent AppBar
           foregroundColor: Colors.grey[200], // Text/icon color on AppBar
           elevation: 0, // Flat AppBar to blend with gradient background
           centerTitle: true,
           titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),

        // Style BottomNavigationBar (used in MainScreen)
         bottomNavigationBarTheme: BottomNavigationBarThemeData(
           backgroundColor: Colors.black.withOpacity(0.8), // Darker, translucent nav bar
           selectedItemColor: Colors.deepPurpleAccent[100], // Color for selected item
           unselectedItemColor: Colors.grey[600], // Color for unselected items
           elevation: 8, // Add elevation for separation
           type: BottomNavigationBarType.fixed, // Or .shifting
           selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
         ),

        // Style SnackBar for consistency
        snackBarTheme: SnackBarThemeData(
           backgroundColor: Colors.grey[850], // Dark background
           contentTextStyle: const TextStyle(color: Colors.white),
           actionTextColor: Colors.deepPurpleAccent[100], // Action text color
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
           elevation: 6,
         ),

         // Style Progress Indicator
         progressIndicatorTheme: ProgressIndicatorThemeData(
            color: Colors.deepPurpleAccent[100], // Use a lighter accent color
            // linearTrackColor: Colors.grey[700],
         ),

      ),
      // --- End Dark Theme Configuration ---

      // Use MainScreen as the entry point, which handles the Bottom Navigation
      home: const MainScreen(),
    );
  }
}