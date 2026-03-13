import 'package:flutter/material.dart';



class ActivityTabPage extends StatefulWidget {
  const ActivityTabPage({super.key});

  @override
  State<ActivityTabPage> createState() => _EarningsTabPageState();
}

class _EarningsTabPageState extends State<ActivityTabPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
          "Activity"
      ),
    );
  }
}
