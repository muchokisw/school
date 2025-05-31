import 'package:flutter/material.dart';
import 'auth/sign_in_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/admin_dashboard.dart';
import 'screens/user_dashboard.dart';
import 'second/super_admin_page.dart'; // Import the SuperAdminPage
import 'pages/parent_student_details_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
  /*FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  sslEnabled: true,
  host: 'firestore.googleapis.com', // or your custom host
  //logLevel: LogLevel.none,
);*/
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = auth.currentUser;

    if (user == null) {
      return const SignInPage();
    }

    DocumentSnapshot userDoc = await firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      String role = userDoc['role'];
      String email = user.email!; // Get the user's email

      if (role == 'sadmin') {
        return const SuperAdminPage(); // Route to SuperAdminPage
      } else if (role == 'admin') {
        return const AdminDashboard();
      } else if (role == 'parent') {
        // Query the students collection to find a matching email
        QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
            .collection('students')
            .where('mother.email', isEqualTo: email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Mother's email matched, retrieve student data
          Map<String, dynamic> studentData = querySnapshot.docs.first.data();
          return ParentStudentDetailsPage(
            id: querySnapshot.docs.first.id,
            name: studentData['name'],
            admissionNumber: studentData['admissionNumber'],
            grade: studentData['grade'],
            gender: studentData['gender'],
            dob: studentData['dob'],
            registrationDate: studentData['registrationDate'],
            mother: studentData['mother'],
            father: studentData['father'],
            fees: studentData['fees'],
          );
        } else {
          // No matching email found in the mother field, check the father field
          QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
              .collection('students')
              .where('father.email', isEqualTo: email)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // Father's email matched, retrieve student data
            Map<String, dynamic> studentData = querySnapshot.docs.first.data();
            return ParentStudentDetailsPage(
              id: querySnapshot.docs.first.id,
              name: studentData['name'],
              admissionNumber: studentData['admissionNumber'],
              grade: studentData['grade'],
              gender: studentData['gender'],
              dob: studentData['dob'],
              registrationDate: studentData['registrationDate'],
              mother: studentData['mother'],
              father: studentData['father'],
              fees: studentData['fees'],
            );
          } else {
            // No matching email found in either mother or father field
            // If no student is found, return to the sign-in page
            return const SignInPage();
          }
        }
      } else {
        return const UserDashboard();
      }
    } else {
      return const SignInPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
      ),
      home: FutureBuilder(
        future: _getInitialScreen(),
        builder: (context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data ?? const SignInPage();
        },
      ),
    );
  }
}
