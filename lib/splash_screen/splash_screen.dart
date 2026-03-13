import 'dart:async';
import 'package:flutter/material.dart';
import 'package:users_app/Authentication/login_screen.dart';
import 'package:users_app/mainScreens/main_screen.dart';
import 'package:users_app/startScreen/start_screen.dart';

import '../Global/global.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen>
{
  startTimer()
  {
    Timer(const Duration(seconds: 1), () async
    {
      if (await fAuth.currentUser != null)
      {
        currentFirebaseUser = fAuth.currentUser;
        Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()),);
      }
      else {
        Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()),);
      }
    });
  }

@override
  void initState() {

    super.initState();

    startTimer();
  }


  @override
  Widget build(BuildContext context)
  {
    return Container(
      color: Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("images/chill_ride.png",width: 200,height: 200,),
             const SizedBox(height: 2,),
            /*const Text(
              "Chill_Ride",
              style: TextStyle(
                fontSize: 60,
                color: Colors.white,
                fontWeight: FontWeight.bold
              ),

            ),*/

          ],
        ),
      ),
    );
  }
}
