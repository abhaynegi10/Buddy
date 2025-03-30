// main_screen.dart
import 'package:flutter/material.dart';
import 'package:txt_to_img/gemini_chat_page.dart';
import 'package:txt_to_img/homepage.dart'; // Your image analysis page

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Start with the Chat page (index 0)

  // List of the pages to navigate between
  static const List<Widget> _widgetOptions = <Widget>[
    GeminiChatPage(), // Chat Page is first
    Homepage(),       // Image Analysis Page is second
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Optional AppBar for the whole app structure if needed
      // appBar: AppBar(
      //   title: Text(_selectedIndex == 0 ? 'Chat Assistant' : 'Image Buddy'),
      //   elevation: 2,
      // ),
      body: Container(
        // --- Creative Background ---
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface, // Slightly lighter dark
              colorScheme.surface, // Base dark background
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // --- Animated Page Transition ---
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350), // Animation speed
          transitionBuilder: (Widget child, Animation<double> animation) {
            // Example: Fade Transition
            return FadeTransition(opacity: animation, child: child);
            // Example: Slide Transition
            // final offsetAnimation = Tween<Offset>(
            //   begin: const Offset(0.5, 0.0), // Slide from right
            //   end: Offset.zero,
            // ).animate(animation);
            // return SlideTransition(position: offsetAnimation, child: child);
          },
          child: _widgetOptions.elementAt(_selectedIndex),
          // Key ensures AnimatedSwitcher recognizes the change
          key: ValueKey<int>(_selectedIndex),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image_search_outlined),
            activeIcon: Icon(Icons.image_search),
            label: 'Image Analysis',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // --- Style the Bottom Nav Bar ---
        backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.8), // Darker surface
        selectedItemColor: colorScheme.primary,         // Color for selected icon/label
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.7), // Color for unselected
        type: BottomNavigationBarType.fixed, // Or .shifting for more animation
        elevation: 5.0, // Add some shadow
      ),
    );
  }
}