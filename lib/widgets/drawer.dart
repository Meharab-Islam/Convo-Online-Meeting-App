import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:flutter/material.dart';
import '../screens/profile_screen.dart'; // make sure this exists

class AboutAppDrawer extends StatelessWidget {
  const AboutAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ColorfulSafeArea(
        color: Colors.black87,
        child: Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Icon & Name
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundImage:AssetImage("assets/logo.png")// app icon or logo
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Convo App",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // App Description
              const Text(
                "Convo is a modern, real-time video calling app that lets you stay connected with friends, family, and colleagues anywhere in the world. Experience high-quality video and crystal-clear audio in seamless one-to-one and group calls. Designed for simplicity and speed, Convo keeps you close to the people who matter most, making every conversation feel personal and engaging.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Profile Button
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.person, color: Colors.white,),
                  label: const Text(
                    "Go to Profile",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(),

              // Developer Name
              Center(
                child: Column(
                  children: const [
                    Divider(color: Colors.white38),
                    SizedBox(height: 8),
                    Text(
                      "Developed by Meharab Islam",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
