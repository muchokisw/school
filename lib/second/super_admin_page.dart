import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import '/auth/sign_in_page.dart'; // Import SignInPage
import '/second/admin_page.dart'; // Import AdminPage
import '/auth/auth_service.dart'; // Import AuthService

//import 'school_model.dart';

class School {
  final String id;
  final String name;

  School({required this.id, required this.name});

  // Add a factory constructor to create a School object from a Firestore document.
  factory School.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return School(
      id: doc.id,
      name: data['name'] ?? '', // Provide a default value if 'name' is missing
    );
  }
}

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({Key? key}) : super(key: key);

  @override
  _SuperAdminPageState createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController(); // Add search controller
  List<School> _schools = [];
  List<School> _filteredSchools = []; // Add filtered schools list

  @override
  void initState() {
    super.initState();
    _fetchSchools();
  }

  Future<void> _fetchSchools() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('schools').get();
      setState(() {
        _schools = snapshot.docs.map((doc) => School.fromFirestore(doc)).toList();
        _filteredSchools = _schools; // Initialize filtered list with all schools
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching schools: $e')),
      );
    }
  }

  Future<void> _addSchool() async {
    final schoolName = _schoolNameController.text.trim();
    if (schoolName.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('schools').add({'name': schoolName});
        _schoolNameController.clear();
        _fetchSchools(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding school: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Optionally, navigate to the sign-in page after signing out.
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignInPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _editSchool(School school) async {
    final TextEditingController editController = TextEditingController(text: school.name);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit School Name'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: 'Enter new school name'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                final newName = editController.text.trim();
                if (newName.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance.collection('schools').doc(school.id).update({'name': newName});
                    _fetchSchools(); // Refresh the list
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating school: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSchool(School school) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete School'),
          content: Text('Are you sure you want to delete ${school.name}?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('schools').doc(school.id).delete();
                  _fetchSchools(); // Refresh the list
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting school: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _filterSchools(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSchools = _schools; // If search is empty, show all schools
      } else {
        _filteredSchools = _schools
            .where((school) => school.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _showAddSuperAdminDialog(BuildContext context) async {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final _authService = AuthService(); // Get instance of AuthService
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    String _errorMessage = '';

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to manage state within the dialog
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Super Admin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    TextField(
                      controller: confirmPasswordController,
                      decoration: const InputDecoration(labelText: 'Confirm Password'),
                      obscureText: true,
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Sign Up'),
                  onPressed: () async {
                    String email = emailController.text.trim();
                    String password = passwordController.text.trim();
                    String confirmPassword = confirmPasswordController.text.trim();

                    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
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
                          'email': email,
                          'role': 'sadmin',
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        Navigator.of(context).pop(); // Close the dialog
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
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        leading: IconButton( // Add logout button
          icon: const Icon(Icons.logout),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
      ),
      body: Center( // Wrap with Center
        child: ConstrainedBox( // Wrap with ConstrainedBox
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Add School Section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _schoolNameController,
                        decoration: const InputDecoration(labelText: 'School Name'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _addSchool,
                      child: const Text('Add School'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Schools',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filterSchools, // Call filter function on text change
                ),
                const SizedBox(height: 20),

                ElevatedButton( // Add Super Admin Button
                  onPressed: () {
                    _showAddSuperAdminDialog(context); // Show the dialog
                  },
                  child: const Text('Add Super Admin'),
                ),
                const SizedBox(height: 20),

                // List of Schools
                Expanded( // Add ConstrainedBox here
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView.builder(
                      itemCount: _filteredSchools.length, // Use filtered list
                      itemBuilder: (context, index) {
                        final school = _filteredSchools[index]; // Use filtered list
                        return Card(
                          child: ListTile(
                            title: Text(school.name),
                            subtitle: Text('ID: ${school.id}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _editSchool(school); // Call the edit function
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteSchool(school); // Call the delete function
                                  },
                                ),
                                const SizedBox(width: 8), // Add some space here
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminPage(schoolId: school.id, schoolName: school.name),
                                      ),
                                    );
                                  },
                                  child: const Text('Admin'),
                                ),
                                const SizedBox(width: 8), // Add some space here
                                ElevatedButton(
                                  onPressed: () {
                                    // TODO: Navigate to User Page for this school
                                  },
                                  child: const Text('User'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}