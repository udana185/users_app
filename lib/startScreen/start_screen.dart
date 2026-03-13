import 'package:flutter/material.dart';
import 'package:users_app/mainScreens/main_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(15), // padding for top/edges
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // left align
            children: [
              // Button at the top
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 12, // shadow depth
                  shadowColor: Colors.grey.withOpacity(1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // wrap content
                  children: [
                    // Image on the left
                    Image.asset(
                      'images/car_icon.png',
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(width: 10), // spacing between image & text
                    // Text on the right
                    Flexible(
                      child: const Text(
                        "Book A Ride",
                        //overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Optional: rest of the screen content
              const SizedBox(height: 20),
              // You can add your background image, info, or illustrations here
            ],
          ),
        ),
      ),
    );
  }
}