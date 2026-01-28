import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';

class FileTransferApp extends StatelessWidget {
  const FileTransferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Transfer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
