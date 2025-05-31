import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

class StudentDetailsPage extends StatefulWidget {
  final String? id;
  final String? name;
  final String? admissionNumber; // Add admission number
  final String? grade;
  final String? gender;
  final String? dob;
  final String? registrationDate;
  final Map<String, dynamic>? mother;
  final Map<String, dynamic>? father;
  final Map<String, dynamic>? fees; // Add the fees field

  const StudentDetailsPage({
    Key? key,
    this.id,
    this.name,
    this.admissionNumber, // Add admission number
    this.grade,
    this.gender,
    this.dob,
    this.registrationDate,
    this.mother,
    this.father,
    this.fees, // Add the fees field
  }) : super(key: key);

  @override
  _StudentDetailsPageState createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
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
  final TextEditingController _admissionNumberController = TextEditingController();
  final TextEditingController _examSearchController = TextEditingController();

  // Define subject lists for each grade level
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  
    // Force a rebuild when the tab index changes
    _tabController.addListener(() {
      setState(() {});
    });

    // Fetch student details from Firestore if an ID is provided
    if (widget.id != null) {
      _fetchStudentDetails();
    } else {
      // Initialize controllers with existing data if available
      _initializeControllers();
    }
  }

  Future<void> _fetchStudentDetails() async {
    DocumentSnapshot studentSnapshot = await _firestore.collection('students').doc(widget.id).get();
    Map<String, dynamic> studentData = studentSnapshot.data() as Map<String, dynamic>;

    double paidFees = await _calculatePaidFees();

    setState(() {
      _nameController.text = studentData['name'] ?? '';
      _admissionNumberController.text = studentData['admissionNumber'] ?? ''; // Fetch admission number
      _gradeController.text = studentData['grade'] ?? '';
      _genderController.text = studentData['gender'] ?? '';
      _dobController.text = studentData['dob'] ?? '';
      _registrationDateController.text = studentData['registrationDate'] ?? '';
      _motherNameController.text = studentData['mother']['name'] ?? '';
      _motherPhoneController.text = studentData['mother']['phone'] ?? '';
      _motherEmailController.text = studentData['mother']['email'] ?? '';
      _fatherNameController.text = studentData['father']['name'] ?? '';
      _fatherPhoneController.text = studentData['father']['phone'] ?? '';
      _fatherEmailController.text = studentData['father']['email'] ?? '';
      _schoolFeesController.text = studentData['fees']['schoolFees'].toString();
      _uniformFeesController.text = studentData['fees']['uniformFees'].toString();
      _activityFeesController.text = studentData['fees']['activityFees'].toString();
      _paidFeesController.text = paidFees.toString();
    });
  }

  void _initializeControllers() {
    if (widget.name != null) _nameController.text = widget.name!;
    if (widget.admissionNumber != null) _admissionNumberController.text = widget.admissionNumber!; // Initialize admission number
    if (widget.grade != null) _gradeController.text = widget.grade!;
    if (widget.gender != null) _genderController.text = widget.gender!;
    if (widget.dob != null) _dobController.text = widget.dob!;
    if (widget.registrationDate != null) _registrationDateController.text = widget.registrationDate!;
    if (widget.mother != null) {
      _motherNameController.text = widget.mother!['name'] ?? '';
      _motherPhoneController.text = widget.mother!['phone'] ?? '';
      _motherEmailController.text = widget.mother!['email'] ?? '';
    }
    if (widget.father != null) {
      _fatherNameController.text = widget.father!['name'] ?? '';
      _fatherPhoneController.text = widget.father!['phone'] ?? '';
      _fatherEmailController.text = widget.father!['email'] ?? '';
    }
    // Initialize fees controllers
    if (widget.fees != null) {
      _schoolFeesController.text = widget.fees!['schoolFees']?.toString() ?? '';
      _uniformFeesController.text = widget.fees!['uniformFees']?.toString() ?? '';
      _activityFeesController.text = widget.fees!['activityFees']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _gradeController.dispose();
    _genderController.dispose();
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
    _admissionNumberController.dispose();
    _examSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.name != null && widget.name!.isNotEmpty ? '${widget.name}\'s Details' : 'Student Details',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Fees'),
            Tab(text: 'Exams'), // Renamed Academics to Exams
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildFeesTab(),
          _buildExamsTab(), // Renamed Academics to Exams
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 0:
        // Profile tab
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'saveStudent',
              onPressed: _saveStudent,
              child: const Icon(Icons.save),
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              heroTag: 'deleteStudent',
              onPressed: _confirmDeleteStudent,
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete),
            ),
          ],
        );
      case 2:
        // Exams tab
        return FloatingActionButton(
          heroTag: 'addExamResultFAB',
          onPressed: _showAddExamDialog,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
          tooltip: 'Add Exam Result',
        );
      default:
        // Fees tab or any other tab
        return null;
    }
  }

  Future<void> _saveStudent() async {
    // Calculate the balance before saving
    double balance = await _calculateBalance();

    final studentData = {
      'name': _nameController.text.trim(),
      'admissionNumber': _admissionNumberController.text.trim(), // Save admission number
      'grade': _gradeController.text.trim(),
      'gender': _genderController.text.trim(),
      'dob': _dobController.text.trim(),
      'registrationDate': _registrationDateController.text.trim(),
      'mother': {
        'name': _motherNameController.text.trim(),
        'phone': _motherPhoneController.text.trim(),
        'email': _motherEmailController.text.trim(),
      },
      'father': {
        'name': _fatherNameController.text.trim(),
        'phone': _fatherPhoneController.text.trim(),
        'email': _fatherEmailController.text.trim(),
      },
      'fees': {
        'schoolFees': double.tryParse(_schoolFeesController.text.trim()) ?? 0.0,
        'uniformFees': double.tryParse(_uniformFeesController.text.trim()) ?? 0.0,
        'activityFees': double.tryParse(_activityFeesController.text.trim()) ?? 0.0,
        'totalFees': _calculateTotalFees(),
        'paidFees': await _calculatePaidFees(),
        'balance': balance,
      },
    };

    if (widget.id == null) {
      await _firestore.collection('students').add(studentData);
    } else {
      await _firestore.collection('students').doc(widget.id).update(studentData);
    }

    setState(() {}); // Refresh the UI with updated data
  }

  Widget _buildProfileTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth * 0.8; // Use 80% of the available width
        if (maxWidth > 600) maxWidth = 600; // Limit the max width to 600px

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0), // Increase vertical padding
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
                        Text('Admission Number: ${_admissionNumberController.text}'), // Display admission number
                        Text('Grade: ${_gradeController.text}'),
                        Text('Gender: ${_genderController.text}'),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _showEditDialog,
                              child: const Text('Edit'),
                            ),
                          ],
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
        double maxWidth = constraints.maxWidth * 0.8; // Use 80% of the available width
        if (maxWidth > 600) maxWidth = 600; // Limit the max width to 600px

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0), // Increase vertical padding
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
                        FutureBuilder<double>(
                          future: _calculateBalance(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              double balance = snapshot.data ?? 0.0;
                              return Text('Balance: $balance');
                            }
                          },
                        ),
                        const Divider(height: 20, thickness: 1),
                        const Text("Payments", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        FutureBuilder<QuerySnapshot>(
                          future: _firestore
                              .collection('payments')
                              .where('admissionNumber', isEqualTo: _admissionNumberController.text.trim()) // Use admission number
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Text('No payments found.');
                            } else {
                              List<QueryDocumentSnapshot> payments = snapshot.data!.docs;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: payments.length,
                                itemBuilder: (context, index) {
                                  Map<String, dynamic> paymentData = payments[index].data() as Map<String, dynamic>;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12), // Match the border radius of the main card
                                    ),
                                    elevation: 3, // Match the elevation of the main card
                                    child: ListTile(
                                      title: Text(
                                        paymentData['purpose'], // Display only the purpose (e.g., "Uniform Fees")
                                        style: const TextStyle(fontSize: 15), // Set font size to 15
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (paymentData.containsKey('term')) Text('Term: ${paymentData['term']}'), // Display term first
                                          Text('Date: ${paymentData['date']}'), // Display date second
                                          Text('Type: ${paymentData['type']}'), // Display type third
                                          Text('Amount: ${paymentData['amount']}'), // Display amount last
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FloatingActionButton(
                              heroTag: 'addFees', // Unique hero tag
                              onPressed: _showAddFeesDialog,
                              backgroundColor: Colors.green,
                              child: const Icon(Icons.attach_money), // Changed icon
                              tooltip: 'Add charges', // Rephrased tooltip
                            ),
                            FloatingActionButton(
                              heroTag: 'addPayment', // Unique hero tag
                              onPressed: _showAddPaymentDialog,
                              backgroundColor: Colors.blue,
                              child: const Icon(Icons.payment),
                              tooltip: 'Record payment',
                            ),
                          ],
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

  // New method to fetch exam data
  Future<List<Map<String, dynamic>>> _fetchExamData() async {
    try {
      final snapshot = await _firestore
          .collection('exams')
          .where('admissionNumber', isEqualTo: _admissionNumberController.text.trim())
          .where('grade', isEqualTo: _gradeController.text.trim()) // Filter by grade
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id; // Add document ID to the data
          return data;
        }).toList();
      } else {
        return []; // Return an empty list if no exam data is found
      }
    } catch (e) {
      print('Error fetching exam data: $e');
      return []; // Return an empty list in case of an error
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
                        const Text("Exam Results:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                physics: const NeverScrollableScrollPhysics(), // Disable scrolling of ListView
                                itemCount: examDataList.length,
                                itemBuilder: (context, index) {
                                  final examData = examDataList[index];
                                  final examId = examData['docId']; // Retrieve document ID
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
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _showEditExamDialog(examData), // Call edit dialog
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            tooltip: 'Delete this exam record',
                                            onPressed: () => _deleteExam(examId), // Call delete method
                                          ),
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

  void _showAddExamDialog() {
    final TextEditingController _typeController = TextEditingController();
    final TextEditingController _yearController = TextEditingController();
    final TextEditingController _termController = TextEditingController();
    final Map<String, TextEditingController> _subjectControllers = {};
    final studentGrade = _gradeController.text.trim();
    final subjects = _gradeSubjects[studentGrade] ?? [];

    for (var subject in subjects) {
      _subjectControllers[subject] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Exam Result'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width < 600
                ? MediaQuery.of(context).size.width * 0.8
                : 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_typeController, 'Exam Type (Opener, Mid, End)'),
                  _buildTextField(_yearController, 'Year'),
                  _buildTextField(_termController, 'Term'),
                  const SizedBox(height: 16),
                  const Text('Enter Subject Marks:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (var subject in subjects)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(subject),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _subjectControllers[subject]!,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Marks',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
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
              onPressed: () {
                // Retrieve subject values here
                Map<String, dynamic> subjectValues = {}; // Change to dynamic
                for (var subject in subjects) {
                  final subjectKey = subject.toLowerCase().replaceAll(' ', '');
                  subjectValues[subjectKey] = _subjectControllers[subject]!.text;
                }

                _addExamResult(
                  _typeController.text,
                  _yearController.text,
                  _termController.text,
                  subjectValues, // Pass subjectValues
                );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addExamResult(
      String type, String year, String term, Map<String, dynamic> subjectValues) async { // Change to dynamic
    final studentGrade = _gradeController.text.trim();
    Map<String, dynamic> examData = {
      'admissionNumber': _admissionNumberController.text.trim(),
      'grade': studentGrade,
      'type': type,
      'year': year,
      'term': term,
    };

    for (var subjectKey in subjectValues.keys) {
      final subjectValue = subjectValues[subjectKey];
      if (subjectValue != null && subjectValue.isNotEmpty) {
        examData[subjectKey] = subjectValue;
      }
    }

    try {
      await _firestore.collection('exams').add(examData);
      setState(() {}); // Refresh the UI
    } catch (e) {
      print('Error adding exam result: $e');
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8, // Increase the width of the dialog
            constraints: const BoxConstraints(maxWidth: 600), // Set the maximum width of the dialog
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_nameController, 'Student Name'),
                  const SizedBox(height: 8),
                  _buildTextField(_admissionNumberController, 'Admission Number'), // Add admission number field
                  const SizedBox(height: 8),
                  _buildGradeDropdown(),
                  const SizedBox(height: 8),
                  _buildGenderField(),
                  const SizedBox(height: 8),
                  _buildDateField(_dobController, 'Date of Birth'),
                  const SizedBox(height: 8),
                  _buildDateField(_registrationDateController, 'Registration Date'),
                  const Divider(height: 20, thickness: 1),
                  const Text("Mother's Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildTextField(_motherNameController, 'Mother\'s Name'),
                  const SizedBox(height: 8),
                  _buildTextField(_motherPhoneController, 'Mother\'s Phone'),
                  const SizedBox(height: 8),
                  _buildTextField(_motherEmailController, 'Mother\'s Email'),
                  const Divider(height: 20, thickness: 1),
                  const Text("Father's Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildTextField(_fatherNameController, 'Father\'s Name'),
                  const SizedBox(height: 8),
                  _buildTextField(_fatherPhoneController, 'Father\'s Phone'),
                  const SizedBox(height: 8),
                  _buildTextField(_fatherEmailController, 'Father\'s Email'),
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
              onPressed: () {
                _saveStudent();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGradeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: _gradeController.text.isEmpty ? null : _gradeController.text,
        decoration: InputDecoration(
          labelText: 'Grade',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: ['PP1', 'PP2', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _gradeController.text = newValue!;
          });
        },
      ),
    );
  }

  void _showEditFinancialDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8, // Increase the width of the dialog
            constraints: const BoxConstraints(maxWidth: 600), // Set the maximum width of the dialog
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Financial Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildTextField(_schoolFeesController, 'School Fees'),
                  const SizedBox(height: 8),
                  _buildTextField(_uniformFeesController, 'Uniform Fees'),
                  const SizedBox(height: 8),
                  _buildTextField(_activityFeesController, 'Activity Fees'),
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
              onPressed: () {
                _saveStudent();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteStudent() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this student?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteStudent();
                Navigator.pop(context);
              },
              //style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStudent() async {
    if (widget.id != null) {
      await _firestore.collection('students').doc(widget.id).delete();
      Navigator.pop(context);
    }
  }

  double _calculateTotalFees() {
    double schoolFees = double.tryParse(_schoolFeesController.text) ?? 0.0;
    double uniformFees = double.tryParse(_uniformFeesController.text) ?? 0.0;
    double activityFees = double.tryParse(_activityFeesController.text) ?? 0.0;
    return schoolFees + uniformFees + activityFees;
  }

  Future<double> _calculatePaidFees() async {
    double totalPaidFees = 0.0;

    QuerySnapshot paymentsSnapshot = await _firestore
        .collection('payments')
        .where('admissionNumber', isEqualTo: _admissionNumberController.text.trim()) // Use admission number
        .get();

    for (var doc in paymentsSnapshot.docs) {
      Map<String, dynamic> paymentData = doc.data() as Map<String, dynamic>;
      double paymentAmount = paymentData['amount'] is int
          ? paymentData['amount'].toDouble()
          : double.tryParse(paymentData['amount'].toString()) ?? 0.0;
      totalPaidFees += paymentAmount;
    }

    return totalPaidFees;
  }

  Future<double> _calculateBalance() async {
    double totalFees = _calculateTotalFees();
    double paidFees = await _calculatePaidFees();
    return totalFees - paidFees;
  }

  void _showAddFeesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8, // Increase the width of the dialog
            constraints: const BoxConstraints(maxWidth: 600), // Set the maximum width of the dialog
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Add Fees to be Paid", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildFirestoreDropdownField('Select Term', 'terms', 'name', 'amount', _addTermFee),
                  const SizedBox(height: 8),
                  _buildMultiSelectDropdownField('Select Uniforms', 'uniforms', 'name', 'amount', _addUniformFees),
                  const SizedBox(height: 8),
                  _buildMultiSelectDropdownField('Select Activities', 'activities', 'name', 'amount', _addActivityFees),
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
              onPressed: () {
                _saveStudent();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPaymentDialog() {
    final TextEditingController _paymentAmountController = TextEditingController();
    final TextEditingController _paymentDateController = TextEditingController();
    String _paymentType = 'Cash'; // Default payment type
    String _paymentPurpose = 'School Fees'; // Default payment purpose

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8, // Increase the width of the dialog
            constraints: const BoxConstraints(maxWidth: 600), // Set the maximum width of the dialog
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Add Fees that have been Paid", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildTextField(_paymentAmountController, 'Amount'),
                  const SizedBox(height: 8),
                  _buildDateField(_paymentDateController, 'Date'),
                  const SizedBox(height: 8),
                  _buildDropdownField('Payment Type', ['Cash', 'Card', 'Bank Transfer', 'Mobile Money'], (newValue) {
                    _paymentType = newValue!; // Add Mobile Money as a payment type
                  }),
                  const SizedBox(height: 8),
                  _buildDropdownField('Payment Purpose', ['School Fees', 'Activity Fees', 'Uniform Fees'], (newValue) {
                    _paymentPurpose = newValue!;
                  }),
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
              onPressed: () {
                _addPayment(_paymentAmountController.text, _paymentDateController.text, _paymentType, _paymentPurpose);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdownField(String label, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildFirestoreDropdownField(String label, String collection, String displayField, String valueField, Function(Map<String, dynamic>) onSelected) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection(collection).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        List<DropdownMenuItem<Map<String, dynamic>>> items = snapshot.data!.docs.map((doc) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: doc.data() as Map<String, dynamic>,
            child: Text(doc[displayField]),
          );
        }).toList();
        return DropdownButtonFormField<Map<String, dynamic>>(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: items,
          onChanged: (value) {
            if (value != null) onSelected(value);
          },
        );
      },
    );
  }

  Widget _buildMultiSelectDropdownField(String label, String collection, String displayField, String valueField, Function(List<Map<String, dynamic>>) onSelected) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection(collection).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        List<MultiSelectItem<Map<String, dynamic>>> items = snapshot.data!.docs.map((doc) {
          return MultiSelectItem<Map<String, dynamic>>(
            doc.data() as Map<String, dynamic>,
            doc[displayField],
          );
        }).toList();
        return Container(
          width: MediaQuery.of(context).size.width * 0.8, // Set the width of the container
          constraints: const BoxConstraints(maxWidth: 600), // Set the maximum width of the container
          child: MultiSelectDialogField(
            items: items,
            title: Text(label),
            selectedColor: Colors.blue,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.all(Radius.circular(8)),
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
            ),
            buttonIcon: Icon(
              Icons.arrow_drop_down,
              color: Colors.blue,
            ),
            buttonText: Text(
              "Select $label",
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: 16,
              ),
            ),
            onConfirm: (results) {
              onSelected(results.cast<Map<String, dynamic>>());
            },
          ),
        );
      },
    );
  }

  void _addTermFee(Map<String, dynamic> term) async {
    String termName = term['name']; // Assuming the term name is stored in the 'name' field

    // Check if the term already exists in the payments collection
    QuerySnapshot existingTermSnapshot = await _firestore
        .collection('payments')
        .where('admissionNumber', isEqualTo: _admissionNumberController.text.trim()) // Use admission number
        .where('purpose', isEqualTo: 'School Fees') // Match the purpose
        .where('term', isEqualTo: termName) // Match the term name
        .get();

    if (existingTermSnapshot.docs.isNotEmpty) {
      // Term already exists, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('School fees for the term "$termName" have already been added.')),
      );
      return; // Exit the method
    }

    // If the term doesn't exist, proceed to add it
    setState(() {
      double termAmount = term['amount'] is int
          ? term['amount'].toDouble()
          : double.tryParse(term['amount'].toString()) ?? 0.0;
      double currentSchoolFees = double.tryParse(_schoolFeesController.text) ?? 0.0;
      _schoolFeesController.text = (currentSchoolFees + termAmount).toString();
    });

    // Update Firestore
    try {
      await _firestore.collection('students').doc(widget.id).update({
        'fees.schoolFees': double.tryParse(_schoolFeesController.text) ?? 0.0,
      });

      // Add the term to the payments collection
      await _firestore.collection('payments').add({
        'admissionNumber': _admissionNumberController.text.trim(), // Use admission number
        'purpose': 'School Fees',
        'term': termName,
        'amount': term['amount'],
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating school fees: $e');
    }
  }

  void _addUniformFees(List<Map<String, dynamic>> uniforms) async {
    setState(() {
      double totalUniformFees = uniforms.fold(0.0, (sum, uniform) {
        double uniformAmount = uniform['amount'] is int
            ? uniform['amount'].toDouble()
            : double.tryParse(uniform['amount'].toString()) ?? 0.0;
        return sum + uniformAmount;
      });
      double currentUniformFees = double.tryParse(_uniformFeesController.text) ?? 0.0;
      _uniformFeesController.text = (currentUniformFees + totalUniformFees).toString();
    });

    // Update Firestore
    try {
      await _firestore.collection('students').doc(widget.id).update({
        'fees.uniformFees': double.tryParse(_uniformFeesController.text) ?? 0.0,
      });
    } catch (e) {
      print('Error updating uniform fees: $e');
    }
  }

  void _addActivityFees(List<Map<String, dynamic>> activities) async {
    setState(() {
      double totalActivityFees = activities.fold(0.0, (sum, activity) {
        double activityAmount = activity['amount'] is int
            ? activity['amount'].toDouble()
            : double.tryParse(activity['amount'].toString()) ?? 0.0;
        return sum + activityAmount;
      });
      double currentActivityFees = double.tryParse(_activityFeesController.text) ?? 0.0;
      _activityFeesController.text = (currentActivityFees + totalActivityFees).toString();
    });

    // Update Firestore
    try {
      await _firestore.collection('students').doc(widget.id).update({
        'fees.activityFees': double.tryParse(_activityFeesController.text) ?? 0.0,
      });
    } catch (e) {
      print('Error updating activity fees: $e');
    }
  }

  void _addPayment(String amount, String date, String type, String purpose) async {
    double paymentAmount = double.tryParse(amount) ?? 0.0;

    // Add the payment to the Firestore payments collection
    await _firestore.collection('payments').add({
      'admissionNumber': _admissionNumberController.text.trim(), // Use admission number
      'purpose': purpose,
      'amount': paymentAmount,
      'date': date,
      'type': type,
    });

    // Update the respective fee category in the financial details
    setState(() {
      if (purpose == 'School Fees') {
        double currentSchoolFees = double.tryParse(_schoolFeesController.text) ?? 0.0;
        _schoolFeesController.text = (currentSchoolFees - paymentAmount).toString();
        _firestore.collection('students').doc(widget.id).update({
          'fees.schoolFees': double.tryParse(_schoolFeesController.text) ?? 0.0,
        });
      } else if (purpose == 'Uniform Fees') {
        double currentUniformFees = double.tryParse(_uniformFeesController.text) ?? 0.0;
        _uniformFeesController.text = (currentUniformFees - paymentAmount).toString();
        _firestore.collection('students').doc(widget.id).update({
          'fees.uniformFees': double.tryParse(_uniformFeesController.text) ?? 0.0,
        });
      } else if (purpose == 'Activity Fees') {
        double currentActivityFees = double.tryParse(_activityFeesController.text) ?? 0.0;
        _activityFeesController.text = (currentActivityFees - paymentAmount).toString();
        _firestore.collection('students').doc(widget.id).update({
          'fees.activityFees': double.tryParse(_activityFeesController.text) ?? 0.0,
        });
      }
    });

    // Recalculate the total paid fees and update Firestore
    double paidFees = await _calculatePaidFees();
    setState(() {
      _paidFeesController.text = paidFees.toString();
      _firestore.collection('students').doc(widget.id).update({
        'fees.paidFees': paidFees,
      });
    });
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context, controller),
          ),
        ),
        readOnly: true,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: _genderController.text.isEmpty ? null : _genderController.text,
        decoration: InputDecoration(
          labelText: 'Gender',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: ['Male', 'Female', 'Other'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _genderController.text = newValue!;
          });
        },
      ),
    );
  }

  void _showExamDetailsDialog(Map<String, dynamic> examData) {
    double dialogWidth = MediaQuery.of(context).size.width * 0.8;
    if (dialogWidth > 600) dialogWidth = 600;

    // Use the student’s current grade to determine which subjects to display
    final studentGrade = _gradeController.text.trim();
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
                  // Exam summary
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
                  // Subject and score list
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

  // Add this new method to show the edit exam dialog
  void _showEditExamDialog(Map<String, dynamic> examData) {
    final TextEditingController _typeController = TextEditingController(text: examData['type'] ?? '');
    final TextEditingController _yearController = TextEditingController(text: examData['year'] ?? '');
    final TextEditingController _termController = TextEditingController(text: examData['term'] ?? '');
    final Map<String, TextEditingController> _subjectControllers = {};
    final studentGrade = _gradeController.text.trim();
    final subjects = _gradeSubjects[studentGrade] ?? [];

    for (var subject in subjects) {
      final subjectKey = subject.toLowerCase().replaceAll(' ', '');
      _subjectControllers[subject] = TextEditingController(text: examData[subjectKey]?.toString() ?? '');
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Exam Result'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width < 600 ? MediaQuery.of(context).size.width * 0.8 : 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_typeController, 'Exam Type (Opener, Mid, End)'),
                  _buildTextField(_yearController, 'Year'),
                  _buildTextField(_termController, 'Term'),
                  const SizedBox(height: 16),
                  const Text('Enter Subject Marks:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (var subject in subjects)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(subject),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _subjectControllers[subject]!,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Marks',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
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
              onPressed: () {
                // Retrieve subject values here
                Map<String, dynamic> subjectValues = {};
                for (var subject in subjects) {
                  final subjectKey = subject.toLowerCase().replaceAll(' ', '');
                  subjectValues[subjectKey] = _subjectControllers[subject]!.text;
                }

                _updateExamResult(
                  examData, // Pass the original examData
                  _typeController.text,
                  _yearController.text,
                  _termController.text,
                  subjectValues,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateExamResult(
    Map<String, dynamic> examData,
    String type,
    String year,
    String term,
    Map<String, dynamic> subjectValues,
  ) async {
    try {
      // Create a map with the updated values
      Map<String, dynamic> updatedData = {
        'type': type,
        'year': year,
        'term': term,
      };

      // Add the updated subject values
      for (var subjectKey in subjectValues.keys) {
        final subjectValue = subjectValues[subjectKey];
        if (subjectValue != null && subjectValue.isNotEmpty) {
          updatedData[subjectKey] = subjectValue;
        }
      }

      // Update the document in Firestore
      await _firestore.collection('exams').doc(examData['docId']).update(updatedData);

      setState(() {}); // Refresh the UI
    } catch (e) {
      print('Error updating exam result: $e');
    }
  }

  Future<void> _deleteExam(String examId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam Entry'),
        content: const Text('Are you sure you want to delete this exam record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('exams').doc(examId).delete();
        setState(() {}); // Refreshes the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting exam: $e')),
        );
      }
    }
  }
}