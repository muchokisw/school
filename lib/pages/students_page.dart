import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert'; // For utf8
import 'package:flutter/foundation.dart' show kIsWeb; // For platform check
//import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
//import 'package:printing/printing.dart';
import '/pages/student_details_page.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _admissionNumberController = TextEditingController();
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
  final TextEditingController _searchController = TextEditingController();

  // Search query state
  String _searchQuery = '';

  // Grade filter state
  String _gradeFilter = 'All'; // Default value

  // Pagination variables
  List<DocumentSnapshot> _students = []; // List to store fetched students

  // Show dialog for adding/editing a student
  void _showStudentDialog({
    String? id,
    String? name,
    String? admissionNumber, // Add admission number
    String? grade,
    String? gender,
    String? dob,
    String? registrationDate,
    Map<String, dynamic>? mother,
    Map<String, dynamic>? father,
  }) {
    // Pre-fill text fields if editing an existing student
    _nameController.text = name ?? '';
    _admissionNumberController.text = admissionNumber ?? ''; // Pre-fill admission number
    _gradeController.text = grade ?? '';
    _genderController.text = gender ?? '';
    _dobController.text = dob ?? '';
    _registrationDateController.text = registrationDate ?? '';
    _motherNameController.text = mother?['name'] ?? '';
    _motherPhoneController.text = mother?['phone'] ?? '';
    _motherEmailController.text = mother?['email'] ?? '';
    _fatherNameController.text = father?['name'] ?? '';
    _fatherPhoneController.text = father?['phone'] ?? '';
    _fatherEmailController.text = father?['email'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate dialog width
              double dialogWidth = MediaQuery.of(context).size.width * 0.9; // 90% of screen width
              if (dialogWidth > 500) dialogWidth = 500; // Limit max width to 500px

              return Container(
                width: dialogWidth,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dialog title
                      Text(id == null ? 'Add Student' : 'Edit Student', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),

                      // Student details fields
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

                      // Mother's details section
                      const Text("Mother's Details", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildTextField(_motherNameController, 'Mother\'s Name'),
                      const SizedBox(height: 8),
                      _buildTextField(_motherPhoneController, 'Mother\'s Phone'),
                      const SizedBox(height: 8),
                      _buildTextField(_motherEmailController, 'Mother\'s Email'),
                      const Divider(height: 20, thickness: 1),

                      // Father's details section
                      const Text("Father's Details", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildTextField(_fatherNameController, 'Father\'s Name'),
                      const SizedBox(height: 8),
                      _buildTextField(_fatherPhoneController, 'Father\'s Phone'),
                      const SizedBox(height: 8),
                      _buildTextField(_fatherEmailController, 'Father\'s Email'),
                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (id == null) {
                                _addStudent(); // Add new student
                              } else {
                                _updateStudent(id); // Update existing student
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            child: Text(id == null ? 'Add' : 'Update'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Add a new student to Firestore
  Future<void> _addStudent() async {
    await _firestore.collection('students').add({
      'name': _nameController.text.trim(),
      'admissionNumber': _admissionNumberController.text.trim(), // Add admission number
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
    });
    _fetchAllStudents(); // Refresh the list after adding a student
  }

  // Update an existing student in Firestore
  Future<void> _updateStudent(String id) async {
    await _firestore.collection('students').doc(id).update({
      'name': _nameController.text.trim(),
      'admissionNumber': _admissionNumberController.text.trim(), // Update admission number
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
    });
    _fetchAllStudents(); // Refresh the list after updating a student
  }

  // Delete a student from Firestore
  Future<void> _deleteStudent(String id) async {
    await _firestore.collection('students').doc(id).delete();
    _fetchAllStudents(); // Refresh the list after deleting a student
  }

  // Confirm deletion dialog
  void _confirmDeleteStudent(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this student?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteStudent(id);
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Show student details dialog
  void _showStudentDetailsDialog(String name, String grade, String gender, String dob, String registrationDate, Map<String, dynamic> mother, Map<String, dynamic> father) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate dialog width
              double dialogWidth = MediaQuery.of(context).size.width * 0.9; // 90% of screen width
              if (dialogWidth > 500) dialogWidth = 500; // Limit max width to 500px

              return Container(
                width: dialogWidth,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student name and grade
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Grade: $grade'),
                      Text('Gender: $gender'),
                      Text('Date of Birth: $dob'),
                      Text('Registration Date: $registrationDate'),
                      const Divider(height: 20),

                      // Mother's details
                      const Text("Mother's Details", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Name: ${mother['name'] ?? 'N/A'}'),
                      Text('Phone: ${mother['phone'] ?? 'N/A'}'),
                      Text('Email: ${mother['email'] ?? 'N/A'}'),
                      const Divider(height: 20),

                      // Father's details
                      const Text("Father's Details", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Name: ${father['name'] ?? 'N/A'}'),
                      Text('Phone: ${father['phone'] ?? 'N/A'}'),
                      Text('Email: ${father['email'] ?? 'N/A'}'),
                      const SizedBox(height: 16),

                      // Export buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _exportStudentDetailsToCSV(name, grade, gender, dob, registrationDate, mother, father),
                            icon: const Icon(Icons.download),
                            label: const Text(''),
                          ),
                          TextButton.icon(
                            onPressed: () => _exportStudentDetailsToPDF(name, grade, gender, dob, registrationDate, mother, father),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text(''),
                          ),
                          TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        ],
                      ),

                      // Close button
                      
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Helper method to build a text field
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

  // Fetch students with pagination
  Future<void> _fetchAllStudents() async {
    Query<Map<String, dynamic>> query = _firestore.collection('students').orderBy('name');

    // Apply grade filter
    if (_gradeFilter != 'All') {
      query = query.where('grade', isEqualTo: _gradeFilter);
    }

    final snapshot = await query.get();
    setState(() {
      _students.clear();
      _students.addAll(snapshot.docs);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAllStudents(); // Fetch all students
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students List'), // Or any of the titles suggested above
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportStudentListToCSV,
            tooltip: 'Export to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportStudentListToPDF,
            tooltip: 'Export to PDF',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20), // Add space between AppBar and search bar
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                      _fetchAllStudents(); // Fetch all students when search query changes
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _gradeFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter by Grade',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ['All', 'PP1', 'PP2', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _gradeFilter = newValue!;
                      _fetchAllStudents(); // Refresh the list when grade filter changes
                    });
                  },
                ),

                // Student list
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Limit width on large screens
                      double maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 600;
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: ListView.builder(
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              var student = _students[index];
                              var name = student['name'].toString().toLowerCase();
                              var grade = student['grade'].toString().toLowerCase();
                              var gender = student['gender'].toString().toLowerCase();
                              var admissionNumber = student['admissionNumber'].toString().toLowerCase();

                              if (_searchQuery.isNotEmpty &&
                                  !name.contains(_searchQuery) &&
                                  !grade.contains(_searchQuery) &&
                                  !gender.contains(_searchQuery) &&
                                  !admissionNumber.contains(_searchQuery)) {
                                return const SizedBox.shrink(); // Hide non-matching items
                              }

                              var mother = student['mother'] as Map<String, dynamic>? ?? {};
                              var father = student['father'] as Map<String, dynamic>? ?? {};

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Text(
                                        student['name'][0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Admission Number: ${student['admissionNumber'] ?? 'N/A'}'), // Handle missing admission number
                                        Text('Grade: ${student['grade']}'),
                                      ],
                                    ),
                                    onTap: () {
                                      _showStudentDetailsPage(
                                        student.id,
                                        student['name'],
                                        student['admissionNumber'] ?? 'N/A', // Handle missing admission number
                                        student['grade'],
                                        student['gender'],
                                        student['dob'],
                                        student['registrationDate'],
                                        student['mother'] as Map<String, dynamic>? ?? {},
                                        student['father'] as Map<String, dynamic>? ?? {},
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Floating action button to add a new student
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
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

  Future<void> _exportStudentListToCSV() async {
    List<List<String>> data = [
      ['Name', 'Grade', 'Gender', 'Date of Birth', 'Registration Date', 'Mother\'s Name', 'Mother\'s Phone', 'Mother\'s Email', 'Father\'s Name', 'Father\'s Phone', 'Father\'s Email']
    ];

    for (var student in _students) {
      var mother = student['mother'] as Map<String, dynamic>? ?? {};
      var father = student['father'] as Map<String, dynamic>? ?? {};
      data.add([
        student['name'] ?? 'N/A',
        student['grade'] ?? 'N/A',
        student['gender'] ?? 'N/A',
        student['dob'] ?? 'N/A',
        student['registrationDate'] ?? 'N/A',
        mother['name'] ?? 'N/A',
        mother['phone'] ?? 'N/A',
        mother['email'] ?? 'N/A',
        father['name'] ?? 'N/A',
        father['phone'] ?? 'N/A',
        father['email'] ?? 'N/A',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(data);

    if (kIsWeb) {
      // For web platform
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "students.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/students.csv';
      final file = File(path);
      await file.writeAsString(csvData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
    }
  }

  Future<void> _exportStudentListToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ['Name', 'Grade', 'Gender', 'Date of Birth', 'Registration Date'],
            data: _students.map((student) {
              var mother = student['mother'] as Map<String, dynamic>? ?? {};
              var father = student['father'] as Map<String, dynamic>? ?? {};
              return [
                student['name'] ?? 'N/A',
                student['grade'] ?? 'N/A',
                student['gender'] ?? 'N/A',
                student['dob'] ?? 'N/A',
                student['registrationDate'] ?? 'N/A',
                //mother['name'] ?? 'N/A',
                //mother['phone'] ?? 'N/A',
                //mother['email'] ?? 'N/A',
                //father['name'] ?? 'N/A',
                //father['phone'] ?? 'N/A',
                //father['email'] ?? 'N/A',
              ];
            }).toList(),
          );
        },
      ),
    );

    if (kIsWeb) {
      // For web platform
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "students.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/students.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF exported to $path')));
    }
  }

  Future<void> _exportStudentDetailsToCSV(String name, String grade, String gender, String dob, String registrationDate, Map<String, dynamic> mother, Map<String, dynamic> father) async {
    List<List<String>> data = [
      ['Field', 'Value'],
      ['Name', name],
      ['Grade', grade],
      ['Gender', gender],
      ['Date of Birth', dob],
      ['Registration Date', registrationDate],
      ['Mother\'s Name', mother['name'] ?? 'N/A'],
      ['Mother\'s Phone', mother['phone'] ?? 'N/A'],
      ['Mother\'s Email', mother['email'] ?? 'N/A'],
      ['Father\'s Name', father['name'] ?? 'N/A'],
      ['Father\'s Phone', father['phone'] ?? 'N/A'],
      ['Father\'s Email', father['email'] ?? 'N/A'],
    ];

    String csvData = const ListToCsvConverter().convert(data);

    if (kIsWeb) {
      // For web platform
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "student_details.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/student_details.csv';
      final file = File(path);
      await file.writeAsString(csvData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
    }
  }

  Future<void> _exportStudentDetailsToPDF(String name, String grade, String gender, String dob, String registrationDate, Map<String, dynamic> mother, Map<String, dynamic> father) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Student Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Name: $name', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Grade: $grade', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Gender: $gender', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Date of Birth: $dob', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Registration Date: $registrationDate', style: pw.TextStyle(fontSize: 16)),
              pw.Divider(height: 20),
              pw.Text('Mother\'s Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Name: ${mother['name'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Phone: ${mother['phone'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Email: ${mother['email'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
              pw.Divider(height: 20),
              pw.Text('Father\'s Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Name: ${father['name'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Phone: ${father['phone'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Email: ${father['email'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 16)),
            ],
          );
        },
      ),
    );

    if (kIsWeb) {
      // For web platform
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "student_details.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/student_details.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF exported to $path')));
    }
  }

  void _showStudentDetailsPage(
    String? id,
    String? name,
    String? admissionNumber, // Add admission number
    String? grade,
    String? gender,
    String? dob,
    String? registrationDate,
    Map<String, dynamic>? mother,
    Map<String, dynamic>? father,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailsPage(
          id: id,
          name: name,
          admissionNumber: admissionNumber, // Pass admission number
          grade: grade,
          gender: gender,
          dob: dob,
          registrationDate: registrationDate,
          mother: mother,
          father: father,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _admissionNumberController.dispose(); // Dispose of admission number controller
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
    _searchController.dispose();
    super.dispose();
  }
}