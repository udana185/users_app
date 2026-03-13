import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:users_app/Authentication/login_screen.dart';
import 'package:users_app/splash_screen/splash_screen.dart';

import '../Global/global.dart';
import '../widgets/progress_dialog.dart';

class SignupScreenTwo extends StatefulWidget {
  const SignupScreenTwo({super.key});

  @override
  State<SignupScreenTwo> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreenTwo>
{


  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();


  validateForm(){
    if(nameTextEditingController.text.length < 3)
    {
      Fluttertoast.showToast(msg: "name must be at least 3 characters.");
    }
    else if(emailTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "email is required.");
    }
    else if(!emailTextEditingController.text.contains("@"))
    {
      Fluttertoast.showToast(msg: "email is not valid.");
    }
    else if(phoneTextEditingController.text.isEmpty)
    {
      Fluttertoast.showToast(msg: "phone number is required.");
    }
    else if(!RegExp(r'^0[0-9]+$').hasMatch(phoneTextEditingController.text))
    {
      Fluttertoast.showToast(msg: "Phone number must start with 0 and contain only numbers.");
    }
    else if(phoneTextEditingController.text.length < 10)
    {
      Fluttertoast.showToast(msg: "phone number must be 10 characters long.");
    }
    else if(passwordTextEditingController.text.isEmpty)
    {
      Fluttertoast.showToast(msg: "password is required.");
    }
    else if(passwordTextEditingController.text.length < 6)
    {
      Fluttertoast.showToast(msg: "password must be atleast 6 characters.");
    }
    else{
      saveUserInfoNow();
    }
  }

  saveUserInfoNow() async
  {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext c)
        {
          return ProgressDialog(message: "Processing,Please wait...",);
        }
    );


    final User? firebaseUser = (
        await fAuth.createUserWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim(),
        ).catchError((msg){
          Navigator.pop(context);
          Fluttertoast.showToast(msg: "Error: " + msg.toString());
        })
      ).user;

    if (firebaseUser != null)
    {
      Map userMap =
      {
        "id": firebaseUser.uid,
        "name": nameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim(),
      };

      DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("users");
      driversRef.child(firebaseUser.uid).set(userMap);

      currentFirebaseUser = firebaseUser;
      Fluttertoast.showToast(msg: "Account has been created.");
      Navigator.push(context, MaterialPageRoute(builder: (c)=> MySplashScreen()));
    }
    else
    {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Account has not been created.");
    }

  }


  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

              const SizedBox(height: 8,),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset("images/chill_ride_light.png"),
              ),

              //const SizedBox(height: 5,),



              /*const Text("Driver Registration",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),*/


              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                child: Container(
                  width: 450,
                  padding: EdgeInsets.all(30),

                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text("User Registration",
                          style: TextStyle(
                            fontSize: 24,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: 15,),

                      TextField(
                        controller: nameTextEditingController,
                        style: const TextStyle(
                            color: Colors.grey
                        ),
                        decoration: const InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(),
                          //hintText: "Name",
                          /*enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),*/
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      SizedBox(height: 10,),

                      TextField(
                        controller: emailTextEditingController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                            color: Colors.grey
                        ),
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                          /*hintText: "Email",
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),*/
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      SizedBox(height: 10,),

                      TextField(
                        controller: phoneTextEditingController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                            color: Colors.grey
                        ),
                        decoration: const InputDecoration(
                          labelText: "Phone",
                          border: OutlineInputBorder(),
                          /*hintText: "Phone",
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),*/
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      SizedBox(height: 10,),

                      TextField(
                        controller: passwordTextEditingController,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        style: const TextStyle(
                            color: Colors.grey
                        ),
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                          /*hintText: "Password",
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),*/
                          labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      SizedBox(height: 15,),

                      ElevatedButton(
                        onPressed: ()
                        {
                          validateForm();
                          Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
                        },
                        //style: ElevatedButton.styleFrom(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1A1A1A),
                        ),// button background

                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        child: Text(
                          "Already have an account? Login Here",
                          style: TextStyle(color: Colors.grey),
                        ),
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
                        },
                      ),
                    ],
                  ),
                ),
              ),

              /*ElevatedButton(
                onPressed: ()
                {
                  //todo
                },
                //style: ElevatedButton.styleFrom(),
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    //fontWeight: FontWeight.bold,
                  ),
                ),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}