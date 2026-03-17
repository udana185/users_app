import 'package:flutter/material.dart';
import 'package:users_app/Global/global.dart';
import 'package:users_app/splash_screen/splash_screen.dart';

class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({super.key});

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage> {
  String userName = "User";
  String userEmail = "";

  @override
  void initState() {
    super.initState();

    if (fAuth.currentUser != null) {
      final String displayName = fAuth.currentUser!.displayName ?? "";
      final String email = fAuth.currentUser!.email ?? "";

      userName = displayName.trim().isNotEmpty
          ? displayName
          : (email.isNotEmpty ? email.split("@")[0] : "User");

      userEmail = email;
    }
  }

  Future<void> logoutUser() async {
    await fAuth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (c) => const MySplashScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String avatarLetter =
    userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : "U";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(fontSize: 20,
            color: Colors.black,
              fontWeight: FontWeight.bold,),
        ),
        actions: [
          TextButton.icon(
            onPressed: logoutUser,
            icon: const Icon(Icons.logout, color: Colors.black),
            label: const Text(
              "Log out",
              style: TextStyle(color: Colors.black,
                fontWeight: FontWeight.bold,),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.orangeAccent,
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Hello, $userName 👋",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Welcome back",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(userName),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(userEmail.isNotEmpty ? userEmail : "No email"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}