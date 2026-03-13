import 'package:users_app/Global/global.dart';
import 'package:flutter/material.dart';
import 'package:users_app/Authentication/login_screen.dart';
import 'package:users_app/splash_screen/splash_screen.dart';
import 'package:users_app/Global/global.dart';
import 'package:users_app/splash_screen/splash_screen.dart';


class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({super.key});

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}



class _ProfileTabPageState extends State<ProfileTabPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Profile",
          style: TextStyle(
            fontSize: 25,
          ),

        ),
        actions: [
          TextButton.icon(
            onPressed: () async
            {
              fAuth.signOut();
              Navigator.push(context, MaterialPageRoute(builder: (c)=> const MySplashScreen()));
            },
            icon: Icon(Icons.logout, color: Colors.black),
            label: Text(
              "Log out",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
