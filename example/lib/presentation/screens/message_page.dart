import 'package:flutter/material.dart';
 
class MessagePage extends StatelessWidget {
  const MessagePage({super.key});
 
  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)!.settings.arguments;
 
    return Scaffold(
      appBar: AppBar(title: Text("Message Page")),
      body: Center(child: Text(data.toString())),
    );
  }
}