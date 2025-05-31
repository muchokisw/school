import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  final String schoolId;
  final String schoolName;

  const AdminPage({Key? key, required this.schoolId, required this.schoolName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - $schoolName'),
      ),
      body: Center(
        child: Text('Admin Page for School ID: $schoolId'),
      ),
    );
  }
}