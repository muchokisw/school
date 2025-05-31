import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'sign_up_page.dart';
import '../screens/user_dashboard.dart';
import '../screens/admin_dashboard.dart';
import '../second/super_admin_page.dart'; // Import SuperAdminPage
import '../pages/parent_student_details_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth > 600 ? 400 : double.infinity,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Sign In",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                              ),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _signIn,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                              backgroundColor: Colors.lightBlue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          const SizedBox(height: 16),
                          /*TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUpPage()),
                              );
                            },
                            child: const Text("Don't have an account? Sign Up"),
                          ),*/
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _signIn() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please enter email and password';
      });
      return;
    }

    try {
      User? user = await _authService.signIn(email, password);
      if (user != null) {
        // Retrieve user role from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          String role = userDoc['role'];

          // Navigate based on role
          if (role == 'sadmin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SuperAdminPage()), // Navigate to SuperAdminPage
            );
          } else if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
            );
          } else if (role == 'parent') {
            // Query the students collection to find a matching email
            QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
                .collection('students')
                .where('mother.email', isEqualTo: email)
                .limit(1)
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              // Mother's email matched, retrieve student data
              Map<String, dynamic> studentData = querySnapshot.docs.first.data();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ParentStudentDetailsPage(
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
                  ),
                ),
              );
            } else {
              // No matching email found in the mother field, check the father field
              QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
                  .collection('students')
                  .where('father.email', isEqualTo: email)
                  .limit(1)
                  .get();

              if (querySnapshot.docs.isNotEmpty) {
                // Father's email matched, retrieve student data
                Map<String, dynamic> studentData = querySnapshot.docs.first.data();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ParentStudentDetailsPage(
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
                    ),
                  ),
                );
              } else {
                // No matching email found in either mother or father field
                setState(() {
                  _errorMessage = 'No student found with this email address.';
                });
              }
            }
          }
           else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserDashboard()),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'User role not found. Contact support.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Sign-In failed. Check credentials.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }
}
