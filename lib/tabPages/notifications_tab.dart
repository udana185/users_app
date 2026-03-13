import 'package:flutter/material.dart';



class NotificationsTabPage extends StatefulWidget {
  const NotificationsTabPage({super.key});

  @override
  State<NotificationsTabPage> createState() => _RatingsTabPageState();
}

class _RatingsTabPageState extends State<NotificationsTabPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Notifications"
      ),
    );
  }
}
