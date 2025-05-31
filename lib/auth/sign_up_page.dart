import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import '../screens/user_dashboard.dart';
import '../screens/admin_dashboard.dart';
import 'sign_in_page.dart';
import '../second/super_admin_page.dart'; // Import SuperAdminPage
import '../pages/parent_student_details_page.dart'; // Import ParentStudentDetailsPage


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController(); // Added name controller
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedRole = 'user'; // Default role
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    // This map drives what users see vs. what the app uses.
    final Map<String, String> roleLabels = {
      'user': 'Administration',
      'admin': 'Management',
      'parent': 'Parent',
    };

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
                            "Sign Up",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _nameController, // Added name text field
                            decoration: InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                              focusedBorder: const OutlineInputBorder(
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
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                              ),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                              ),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Select Role',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.lightBlue, width: 2),
                              ),
                            ),
                            // Build the dropdown items based on the map.
                            items: roleLabels.entries.map((entry) {
                              final internalValue = entry.key;   // e.g. "user"
                              final displayValue = entry.value;  // e.g. "Administration"
                              return DropdownMenuItem<String>(
                                value: internalValue,
                                child: Text(
                                  displayValue,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value ?? 'user'; // Fallback to 'user' if null
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _signUp,
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
                              'Sign Up',
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
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const SignInPage()),
                              );
                            },
                            child: const Text("Sign Back In"),
                          ),
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

  Future<void> _signUp() async {
    String name = _nameController.text.trim(); // Get name from controller
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) { // Check if name is empty
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    try {
      User? user = await _authService.signUp(email, password);
      if (user != null) {
        // Store user data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': name, // Store name in Firestore
          'email': email,
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Redirect based on role
        if (_selectedRole.toLowerCase() == 'sadmin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SuperAdminPage()),
          );
        } else if (_selectedRole.toLowerCase() == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (_selectedRole.toLowerCase() == 'parent') {
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
              // Delete the newly created user
              await user.delete();
            }
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserDashboard()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Sign-Up failed. Try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); // Dispose the name controller
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
