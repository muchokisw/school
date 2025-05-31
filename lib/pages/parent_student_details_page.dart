import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import intl package
import '../auth/sign_in_page.dart';

class Conversation {
  final String otherUserEmail;
  final String otherUserName;

  Conversation({
    required this.otherUserEmail,
    required this.otherUserName,
  });

  // Make conversations with the same "otherUserEmail" appear as duplicates
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Conversation &&
        other.otherUserEmail == otherUserEmail;
  }

  @override
  int get hashCode => otherUserEmail.hashCode;
}

class ParentStudentDetailsPage extends StatefulWidget {
  final String? id;
  final String? name;
  final String? admissionNumber;
  final String? grade;
  final String? gender;
  final String? dob;
  final String? registrationDate;
  final Map<String, dynamic>? mother;
  final Map<String, dynamic>? father;
  final Map<String, dynamic>? fees;

  const ParentStudentDetailsPage({
    Key? key,
    this.id,
    this.name,
    this.admissionNumber,
    this.grade,
    this.gender,
    this.dob,
    this.registrationDate,
    this.mother,
    this.father,
    this.fees,
  }) : super(key: key);

  @override
  _ParentStudentDetailsPageState createState() => _ParentStudentDetailsPageState();
}

class _ParentStudentDetailsPageState extends State<ParentStudentDetailsPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  int _selectedIndex = 0; // Track selected tab

  // Store the user's email/name
  String? _userEmail;
  String? _userName;

  // Controllers for sending a new message
  final TextEditingController _recipientEmailController = TextEditingController();
  final TextEditingController _messageTextController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _admissionNumberController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _registrationDateController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _motherPhoneController = TextEditingController();
  final TextEditingController _motherEmailController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _fatherPhoneController = TextEditingController();
  final TextEditingController _fatherEmailController = TextEditingController();
  final TextEditingController _schoolFeesController = TextEditingController();
  final TextEditingController _uniformFeesController = TextEditingController();
  final TextEditingController _activityFeesController = TextEditingController();
  final TextEditingController _paidFeesController = TextEditingController();

  final Map<String, List<String>> _gradeSubjects = {
    'PP1': [
      'Language Activities', 'Mathematical Activities', 'Psychomotor and Creative Activities',
      'Religious Education Activities', 'Hygiene and Nutrition Activities'
    ],
    'PP2': [
      'Language Activities', 'Mathematical Activities', 'Psychomotor and Creative Activities',
      'Religious Education Activities', 'Hygiene and Nutrition Activities'
    ],
    '1': [
      'Literacy', 'Mathematics', 'Environmental Activities', 'Religious Education Activities',
      'Movement and Creative Activities', 'Hygiene and Nutrition Activities'
    ],
    '2': [
      'Literacy', 'Mathematics', 'Environmental Activities', 'Religious Education Activities',
      'Movement and Creative Activities', 'Hygiene and Nutrition Activities'
    ],
    '3': [
      'English', 'Kiswahili', 'Mathematics', 'Science and Technology', 'Social Studies',
      'Religious Education', 'Creative Arts', 'Physical and Health Education'
    ],
    '4': [
      'English', 'Kiswahili', 'Mathematics', 'Science and Technology', 'Social Studies',
      'Religious Education', 'Creative Arts', 'Physical and Health Education', 'Agriculture', 'ICT'
    ],
    '5': [
      'English', 'Kiswahili', 'Mathematics', 'Science and Technology', 'Social Studies',
      'Religious Education', 'Creative Arts', 'Physical and Health Education', 'Agriculture', 'ICT'
    ],
    '6': [
      'English', 'Kiswahili', 'Mathematics', 'Science and Technology', 'Social Studies',
      'Religious Education', 'Creative Arts', 'Physical and Health Education', 'Agriculture', 'ICT'
    ],
  };

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Set length to 4
    _tabController.addListener(() {
      setState(() {});
    });

    // Get current user’s email
    _userEmail = FirebaseAuth.instance.currentUser?.email;

    // Fetch user’s name from Firestore “users” collection
    _fetchUserName();

    _nameController.text = widget.name ?? '';
    _admissionNumberController.text = widget.admissionNumber ?? '';
    _gradeController.text = widget.grade ?? '';
    _selectedGender = widget.gender;
    _dobController.text = widget.dob ?? '';
    _registrationDateController.text = widget.registrationDate ?? '';
    _motherNameController.text = widget.mother?['name'] ?? '';
    _motherPhoneController.text = widget.mother?['phone'] ?? '';
    _motherEmailController.text = widget.mother?['email'] ?? '';
    _fatherNameController.text = widget.father?['name'] ?? '';
    _fatherPhoneController.text = widget.father?['phone'] ?? '';
    _fatherEmailController.text = widget.father?['email'] ?? '';
    _schoolFeesController.text = widget.fees?['schoolFees']?.toString() ?? '';
    _uniformFeesController.text = widget.fees?['uniformFees']?.toString() ?? '';
    _activityFeesController.text = widget.fees?['activityFees']?.toString() ?? '';
    _paidFeesController.text = widget.fees?['paidFees']?.toString() ?? '';

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _fetchUserName() async {
    if (_userEmail == null) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: _userEmail)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _userName = snapshot.docs.first.data()['name'] as String?;
        });
      }
    } catch (e) {
      // Handle error accordingly
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recipientEmailController.dispose();
    _messageTextController.dispose();
    _nameController.dispose();
    _admissionNumberController.dispose();
    _gradeController.dispose();
    _dobController.dispose();
    _registrationDateController.dispose();
    _motherNameController.dispose();
    _motherPhoneController.dispose();
    _motherEmailController.dispose();
    _fatherNameController.dispose();
    _fatherPhoneController.dispose();
    _fatherEmailController.dispose();
    _schoolFeesController.dispose();
    _uniformFeesController.dispose();
    _activityFeesController.dispose();
    _paidFeesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.name != null && widget.name!.isNotEmpty ? '${widget.name}\'s Details' : 'Student Details',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.blue, // Customize the background color
              child: Text(
                widget.name != null && widget.name!.isNotEmpty ? widget.name![0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white, // Customize the text color
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Fees'),
            Tab(text: 'Exams'),
            Tab(text: 'Messages'), // New tab for Messages
          ],
        ),
      ),
      floatingActionButton: _tabController.index != 3
          ? FloatingActionButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                );
              },
              child: const Icon(Icons.logout),
              tooltip: 'Log Out',
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildFeesTab(),
          _buildExamsTab(),
          _buildMessagesTab(), // Messages view
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildFeesTab(),
          _buildExamsTab(),
        ],
      );
    } else if (_selectedIndex == 1) {
      return _buildMessagesTab();
    } else {
      return const Center(child: Text('Unknown Tab'));
    }
  }

  Widget _buildProfileTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth * 0.8;
        if (maxWidth > 600) maxWidth = 600;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SingleChildScrollView(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Student's Details", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Name: ${_nameController.text}'),
                        Text('Admission Number: ${_admissionNumberController.text}'),
                        Text('Grade: ${_gradeController.text}'),
                        Text('Gender: ${_selectedGender ?? ''}'),
                        Text('Date of Birth: ${_dobController.text}'),
                        Text('Registration Date: ${_registrationDateController.text}'),
                        const Divider(height: 20, thickness: 1),
                        const Text("Mother's Details", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Name: ${_motherNameController.text}'),
                        Text('Phone: ${_motherPhoneController.text}'),
                        Text('Email: ${_motherEmailController.text}'),
                        const Divider(height: 20, thickness: 1),
                        const Text("Father's Details", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Name: ${_fatherNameController.text}'),
                        Text('Phone: ${_fatherPhoneController.text}'),
                        Text('Email: ${_fatherEmailController.text}'),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => _showEditStudentDialog(context),
                            child: const Text('Edit'),
                          ),
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
    );
  }

  Widget _buildFeesTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth * 0.8;
        if (maxWidth > 600) maxWidth = 600;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SingleChildScrollView(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Financial Details", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('School Fees: ${_schoolFeesController.text}'),
                        Text('Uniform Fees: ${_uniformFeesController.text}'),
                        Text('Activity Fees: ${_activityFeesController.text}'),
                        const Divider(height: 20, thickness: 1),
                        Text('Total Fees: ${_calculateTotalFees()}'),
                        const Divider(height: 20, thickness: 1),
                        Text('Paid Fees: ${_paidFeesController.text}'),
                        const Divider(height: 20, thickness: 1),
                        Text('Balance: ${_calculateBalance()}'),
                        const Divider(height: 20, thickness: 1),
                        const Text("Payments", style: TextStyle(fontWeight: FontWeight.bold)),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _fetchPaymentData(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            } else {
                              final paymentDataList = snapshot.data ?? [];

                              if (paymentDataList.isEmpty) {
                                return const Center(child: Text('No payments found.'));
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: paymentDataList.length,
                                itemBuilder: (context, index) {
                                  final paymentData = paymentDataList[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                    child: ListTile(
                                      title: Text(
                                        paymentData['purpose'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.normal),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Type: ${paymentData['type'] ?? ''}'),
                                          Text('Date: ${paymentData['date'] ?? ''}'),
                                          Text('Amount: ${paymentData['amount'] ?? ''}'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
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
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPaymentData() async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('admissionNumber', isEqualTo: widget.admissionNumber)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching payment data: $e');
      return [];
    }
  }

  Widget _buildExamsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth * 0.8;
        if (maxWidth > 600) maxWidth = 600;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SingleChildScrollView(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Exam Results", style: TextStyle(fontWeight: FontWeight.bold)),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _fetchExamData(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            } else {
                              final examDataList = snapshot.data ?? [];

                              if (examDataList.isEmpty) {
                                return const Center(child: Text('No exams found.'));
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: examDataList.length,
                                itemBuilder: (context, index) {
                                  final examData = examDataList[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                    child: ListTile(
                                      title: Text(
                                        '${examData['type']} Term ${examData['term']} ${examData['year']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      onTap: () => _showExamDetailsDialog(examData),
                                    ),
                                  );
                                },
                              );
                            }
                          },
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
    );
  }

  Future<List<Map<String, dynamic>>> _fetchExamData() async {
    try {
      final snapshot = await _firestore
          .collection('exams')
          .where('admissionNumber', isEqualTo: widget.admissionNumber)
          .where('grade', isEqualTo: widget.grade)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching exam data: $e');
      return [];
    }
  }

  void _showExamDetailsDialog(Map<String, dynamic> examData) {
    double dialogWidth = MediaQuery.of(context).size.width * 0.8;
    if (dialogWidth > 600) dialogWidth = 600;

    final studentGrade = widget.grade ?? '';
    final subjects = _gradeSubjects[studentGrade] ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Exam Details',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Basic exam info card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(
                        '${examData['type'] ?? ''} - Term: ${examData['term'] ?? ''} (${examData['year'] ?? ''})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (subjects.isNotEmpty)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Subjects & Scores:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 8),
                  // List each subject in a Card
                  for (var subject in subjects)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.book_outlined),
                        title: Text(subject),
                        subtitle: Text(
                          'Score: ${examData[subject.toLowerCase().replaceAll(' ', '')] ?? ''}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  double _calculateTotalFees() {
    double schoolFees = double.tryParse(_schoolFeesController.text) ?? 0.0;
    double uniformFees = double.tryParse(_uniformFeesController.text) ?? 0.0;
    double activityFees = double.tryParse(_activityFeesController.text) ?? 0.0;
    return schoolFees + uniformFees + activityFees;
  }

  double _calculateBalance() {
    double totalFees = _calculateTotalFees();
    double paidFees = double.tryParse(_paidFeesController.text) ?? 0.0;
    return totalFees - paidFees;
  }

  void _showEditStudentDialog(BuildContext context) {
    double dialogWidth = MediaQuery.of(context).size.width * 0.8;
    if (dialogWidth > 600) dialogWidth = 600;

    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: widget.name);
    _selectedGender = widget.gender; // Initialize _selectedGender with the current gender
    final dobController = TextEditingController(text: widget.dob);
    final motherNameController = TextEditingController(text: widget.mother?['name'] ?? '');
    final motherPhoneController = TextEditingController(text: widget.mother?['phone'] ?? '');
    final motherEmailController = TextEditingController(text: widget.mother?['email'] ?? '');
    final fatherNameController = TextEditingController(text: widget.father?['name'] ?? '');
    final fatherPhoneController = TextEditingController(text: widget.father?['phone'] ?? '');
    final fatherEmailController = TextEditingController(text: widget.father?['email'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10), // Add space here
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      value: _selectedGender,
                      items: <String>['Male', 'Female', 'Other']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a gender';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10), // Add space here
                    TextFormField(
                      controller: dobController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        hintText: 'YYYY-MM-DD',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                          setState(() {
                            dobController.text = formattedDate;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a date of birth';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Mother's Details",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: motherNameController,
                      decoration: InputDecoration(
                        labelText: 'Mother\'s Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Add space here
                    TextFormField(
                      controller: motherPhoneController,
                      decoration: InputDecoration(
                        labelText: 'Mother\'s Phone',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Add space here
                    TextFormField(
                      controller: motherEmailController,
                      decoration: InputDecoration(
                        labelText: 'Mother\'s Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Father's Details",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: fatherNameController,
                      decoration: InputDecoration(
                        labelText: 'Father\'s Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Add space here
                    TextFormField(
                      controller: fatherPhoneController,
                      decoration: InputDecoration(
                        labelText: 'Father\'s Phone',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Add space here
                    TextFormField(
                      controller: fatherEmailController,
                      decoration: InputDecoration(
                        labelText: 'Father\'s Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Update Firestore document
                  try {
                    await _firestore.collection('students').doc(widget.id).update({
                      'name': nameController.text,
                      'gender': _selectedGender,
                      'dob': dobController.text,
                      'mother.name': motherNameController.text,
                      'mother.phone': motherPhoneController.text,
                      'mother.email': motherEmailController.text,
                      'father.name': fatherNameController.text,
                      'father.phone': fatherPhoneController.text,
                      'father.email': fatherEmailController.text,
                    });

                    // Update the state of the widget
                    setState(() {
                      _nameController.text = nameController.text;
                      _selectedGender = _selectedGender;
                      _dobController.text = dobController.text;
                      _motherNameController.text = motherNameController.text;
                      _motherPhoneController.text = motherPhoneController.text;
                      _motherEmailController.text = motherEmailController.text;
                      _fatherNameController.text = fatherNameController.text;
                      _fatherPhoneController.text = fatherPhoneController.text;
                      _fatherEmailController.text = fatherEmailController.text;
                    });

                    Navigator.of(context).pop();
                  } catch (e) {
                    print("Error updating student details: $e");
                    // Show an error message to the user
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    return Stack(
      children: [
        Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use up to 80% of available width, but max at 700
                  double searchBarWidth = constraints.maxWidth * 0.8;
                  if (searchBarWidth > 700) searchBarWidth = 700;

                  return Center(
                    child: SizedBox(
                      width: searchBarWidth,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search conversations...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Conversation list
            Expanded(child: _buildConversationList()),
          ],
        ),

        // Floating action button to start a new conversation
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'chatFab',
            onPressed: _startNewConversationDialog,
            child: const Icon(Icons.add),
            tooltip:'Start Chat',
          ),
        ),

        // Floating action button to logout
        /*Positioned(
          bottom: 80, // Shift up to avoid overlapping the other FAB
          right: 16,
          child: FloatingActionButton(
            heroTag: 'logoutFab',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignInPage()),
              );
            },
            child: const Icon(Icons.logout),
          ),
        ),*/
      ],
    );
  }

  Widget _buildConversationList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth * 0.8; // Take 80% of available width
        if (maxWidth > 600) maxWidth = 600;           // Limit to 600

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('messages')
              .where('senderEmail', isEqualTo: _userEmail)
              .snapshots(),
          builder: (context, snapshotSender) {
            if (snapshotSender.hasError) {
              return Center(child: Text("Error: ${snapshotSender.error}"));
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('messages')
                  .where('recipientEmail', isEqualTo: _userEmail)
                  .snapshots(),
              builder: (context, snapshotRecipient) {
                if (snapshotRecipient.hasError) {
                  return Center(child: Text("Error: ${snapshotRecipient.error}"));
                }

                if (snapshotSender.connectionState == ConnectionState.waiting ||
                    snapshotRecipient.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final senderDocs = snapshotSender.data?.docs ?? [];
                final recipientDocs = snapshotRecipient.data?.docs ?? [];
                final allDocs = [...senderDocs, ...recipientDocs];

                final Set<Conversation> convSet = {};
                for (var doc in allDocs) {
                  final data = doc.data();
                  final senderEmail = data['senderEmail'] ?? '';
                  final senderName = data['senderName'] ?? '';
                  final recipientEmail = data['recipientEmail'] ?? '';
                  final recipientName = data['recipientName'] ?? '';

                  if (senderEmail.isEmpty || recipientEmail.isEmpty) continue;

                  if (senderEmail == _userEmail) {
                    convSet.add(
                      Conversation(
                        otherUserEmail: recipientEmail,
                        otherUserName: recipientName,
                      ),
                    );
                  } else if (recipientEmail == _userEmail) {
                    convSet.add(
                      Conversation(
                        otherUserEmail: senderEmail,
                        otherUserName: senderName,
                      ),
                    );
                  }
                }

                final convList = convSet.toList();
                final filteredList = convList.where((conversation) {
                  final nameLC = conversation.otherUserName.toLowerCase();
                  final emailLC = conversation.otherUserEmail.toLowerCase();
                  return nameLC.contains(_searchQuery) || emailLC.contains(_searchQuery);
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text('No conversations found.'));
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final conversation = filteredList[index];
                        final firstLetter = conversation.otherUserName.isNotEmpty
                            ? conversation.otherUserName[0].toUpperCase()
                            : '?';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                firstLetter,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              conversation.otherUserName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(conversation.otherUserEmail),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => _showConversationDialog(conversation),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showConversationDialog(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) {
        final newMsgController = TextEditingController();
        double dialogWidth = MediaQuery.of(context).size.width * 0.8;
        if (dialogWidth > 600) dialogWidth = 600;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Messages with ${conversation.otherUserName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore
                          .collection('messages')
                          .where('timestamp', isGreaterThan: DateTime(1900))
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final allMsgs = snapshot.data?.docs ?? [];
                        final relevantMsgs = allMsgs.where((doc) {
                          final data = doc.data();
                          final sEmail = data['senderEmail'] ?? '';
                          final rEmail = data['recipientEmail'] ?? '';
                          return (sEmail == _userEmail && rEmail == conversation.otherUserEmail) ||
                              (sEmail == conversation.otherUserEmail && rEmail == _userEmail);
                        }).toList();

                        if (relevantMsgs.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('No messages yet.'),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: relevantMsgs.length,
                          itemBuilder: (context, idx) {
                            final data = relevantMsgs[idx].data();
                            final sender = data['senderName'] ?? '';
                            final text = data['text'] ?? '';
                            final isMe = data['senderEmail'] == _userEmail;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue[100] : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('$sender: $text'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newMsgController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                final msg = newMsgController.text.trim();
                if (msg.isEmpty || _userEmail == null || _userName == null) return;

                await _firestore.collection('messages').add({
                  'senderEmail': _userEmail,
                  'senderName': _userName,
                  'recipientEmail': conversation.otherUserEmail,
                  'recipientName': conversation.otherUserName,
                  'text': msg,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                newMsgController.clear();
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _startNewConversationDialog() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final possibleRecipients = usersSnapshot.docs
        .where((doc) => (doc.data()['email'] != _userEmail))
        .map((doc) => {
              'email': doc.data()['email'],
              'name': doc.data()['name'],
            })
        .toList();

    String? selectedUserEmail;
    String? selectedUserName;
    final initialMsgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        double dialogWidth = MediaQuery.of(context).size.width * 0.8;
        if (dialogWidth > 600) dialogWidth = 600;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start New Conversation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField(
                    decoration: InputDecoration(
                      labelText: 'Recipient',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    hint: const Text('Select a user'),
                    items: possibleRecipients.map((user) {
                      return DropdownMenuItem(
                        value: user,
                        child: Text(user['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value is Map<String, dynamic>) {
                        selectedUserEmail = value['email'];
                        selectedUserName = value['name'];
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Please select a user' : null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: initialMsgCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      hintText: 'Write your initial message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final msg = initialMsgCtrl.text.trim();
                if (msg.isEmpty ||
                    selectedUserEmail == null ||
                    selectedUserName == null ||
                    _userEmail == null ||
                    _userName == null) {
                  return;
                }
                await _firestore.collection('messages').add({
                  'senderEmail': _userEmail,
                  'senderName': _userName,
                  'recipientEmail': selectedUserEmail,
                  'recipientName': selectedUserName,
                  'text': msg,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final recipientEmail = _recipientEmailController.text.trim();
    final messageText = _messageTextController.text.trim();

    if (_userEmail == null || _userName == null || recipientEmail.isEmpty || messageText.isEmpty) {
      return;
    }

    try {
      await _firestore.collection('messages').add({
        'email': recipientEmail,             // Recipient’s email
        'sender': _userName,                 // current user’s name
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageTextController.clear();
    } catch (e) {
      // Handle error accordingly
    }
  }
}