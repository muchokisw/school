import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert'; // For utf8
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb; // For platform check
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '/pages/teacher_details_page.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  _TeachersPageState createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _hireDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  // Search query state
  String _searchQuery = '';

  // Pagination variables
  List<DocumentSnapshot> _teachers = []; // List to store fetched teachers

  @override
  void initState() {
    super.initState();
    _fetchAllTeachers(); // Fetch all teachers
  }

  // Fetch teachers with pagination
  Future<void> _fetchAllTeachers() async {
    final snapshot = await _firestore.collection('teachers').orderBy('name').get();
    setState(() {
      _teachers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['teacherID'] = data['teacherID'] ?? 'N/A'; // Ensure teacherID has a default value
        return doc;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers List'), // Or any other suitable title
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportTeacherListToCSV,
            tooltip: 'Export to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportTeacherListToPDF,
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
                    hintText: 'Search teachers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                      _fetchAllTeachers(); // Fetch all teachers when search query changes
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Teacher list
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Limit width on large screens
                      double maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 600;
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: ListView.builder(
                            itemCount: _teachers.length,
                            itemBuilder: (context, index) {
                              var teacher = _teachers[index];
                              var name = teacher['name'].toString().toLowerCase();
                              var subject = teacher['subject'].toString().toLowerCase();
                              var gender = teacher['gender'].toString().toLowerCase();
                              if (_searchQuery.isNotEmpty && !name.contains(_searchQuery) && !subject.contains(_searchQuery) && !gender.contains(_searchQuery)) {
                                return const SizedBox.shrink(); // Hide non-matching items
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6), // Spacing between cards
                                child: Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.orange,
                                      child: Text(
                                        teacher['name'][0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(teacher['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Teacher ID: ${teacher['teacherID'] ?? 'N/A'}'), // Display teacherID
                                        Text('Subject: ${teacher['subject']}'),
                                      ],
                                    ),
                                    onTap: () {
                                      _showTeacherDetailsPage(
                                        teacherID: teacher['teacherID'],
                                        name: teacher['name'],
                                        subject: teacher['subject'],
                                        gender: teacher['gender'],
                                        dob: teacher['dob'],
                                        hireDate: teacher['hireDate'],
                                        email: teacher['email'],
                                        phone: teacher['phone'],
                                        salary: teacher['salary'] ?? 'N/A',
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
      // Floating action button to add a new teacher
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTeacherDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Show teacher details dialog
  void _showTeacherDetailsDialog(
    String name,
    String subject,
    String gender,
    String dob,
    String hireDate,
    String email,
    String phone,
    String salary, // Add salary parameter
  ) {
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
                      // Teacher name and subject
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Subject: $subject'),
                      Text('Gender: $gender'),
                      Text('Date of Birth: $dob'),
                      Text('Hire Date: $hireDate'),
                      Text('Email: $email'),
                      Text('Phone: $phone'),
                      Text('Salary: $salary'), // Display salary
                      const SizedBox(height: 16),

                      // Export buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _exportTeacherDetailsToCSV(
                              name,
                              subject,
                              gender,
                              dob,
                              hireDate,
                              email,
                              phone,
                              salary, // Pass salary
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text('Export to CSV'),
                          ),
                          TextButton.icon(
                            onPressed: () => _exportTeacherDetailsToPDF(
                              name,
                              subject,
                              gender,
                              dob,
                              hireDate,
                              email,
                              phone,
                              salary, // Pass salary
                            ),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Export to PDF'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
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

  // Show dialog for adding/editing a teacher
  void _showTeacherDialog({
    String? teacherID,
    String? name,
    String? subject,
    String? gender,
    String? dob,
    String? hireDate,
    String? email,
    String? phone,
    String? salary,
  }) {
    final TextEditingController _teacherIDController = TextEditingController(text: teacherID ?? '');
    _nameController.text = name ?? '';
    _subjectController.text = subject ?? '';
    _genderController.text = gender ?? '';
    _dobController.text = dob ?? '';
    _hireDateController.text = hireDate ?? '';
    _emailController.text = email ?? '';
    _phoneController.text = phone ?? '';
    _salaryController.text = salary ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(teacherID == null ? 'Add Teacher' : 'Edit Teacher',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  _buildTextField(_teacherIDController, 'Teacher ID'), // Add Teacher ID field
                  const SizedBox(height: 8),
                  _buildTextField(_nameController, 'Teacher Name'),
                  const SizedBox(height: 8),
                  _buildTextField(_subjectController, 'Subject'),
                  const SizedBox(height: 8),
                  _buildGenderField(),
                  const SizedBox(height: 8),
                  _buildDateField(_dobController, 'Date of Birth'),
                  const SizedBox(height: 8),
                  _buildDateField(_hireDateController, 'Hire Date'),
                  const SizedBox(height: 8),
                  _buildTextField(_emailController, 'Email'),
                  const SizedBox(height: 8),
                  _buildTextField(_phoneController, 'Phone'),
                  const SizedBox(height: 8),
                  _buildTextField(_salaryController, 'Salary'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (teacherID == null) {
                            _addTeacher(_teacherIDController.text.trim());
                          } else {
                            _updateTeacher(_teacherIDController.text.trim());
                          }
                          Navigator.pop(context);
                        },
                        child: Text(teacherID == null ? 'Add' : 'Update'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Add a new teacher to Firestore
  Future<void> _addTeacher(String teacherID) async {
    await _firestore.collection('teachers').add({
      'teacherID': teacherID, // Use the provided teacherID
      'name': _nameController.text.trim(),
      'subject': _subjectController.text.trim(),
      'gender': _genderController.text.trim(),
      'dob': _dobController.text.trim(),
      'hireDate': _hireDateController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'salary': _salaryController.text.trim(),
    });
    _fetchAllTeachers(); // Refresh the list
  }

  // Update an existing teacher in Firestore
  Future<void> _updateTeacher(String teacherID) async {
    final snapshot = await _firestore
        .collection('teachers')
        .where('teacherID', isEqualTo: teacherID)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'name': _nameController.text.trim(),
        'subject': _subjectController.text.trim(),
        'gender': _genderController.text.trim(),
        'dob': _dobController.text.trim(),
        'hireDate': _hireDateController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'salary': _salaryController.text.trim(),
      });
      _fetchAllTeachers(); // Refresh the list
    }
  }

  // Delete a teacher from Firestore
  Future<void> _deleteTeacher(String id) async {
    await _firestore.collection('teachers').doc(id).delete();
    _fetchAllTeachers(); // Refresh the list after deleting a teacher
  }

  // Confirm deletion dialog
  void _confirmDeleteTeacher(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this teacher?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteTeacher(id);
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
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

  Future<void> _exportTeacherListToCSV() async {
    List<List<String>> data = [
      ['Name', 'Subject', 'Gender', 'Date of Birth', 'Hire Date', 'Email', 'Phone', 'Salary'] // Add salary field
    ];

    for (var teacher in _teachers) {
      data.add([
        teacher['name'] ?? 'N/A',
        teacher['subject'] ?? 'N/A',
        teacher['gender'] ?? 'N/A',
        teacher['dob'] ?? 'N/A',
        teacher['hireDate'] ?? 'N/A',
        teacher['email'] ?? 'N/A',
        teacher['phone'] ?? 'N/A',
        teacher['salary'] ?? 'N/A', // Add salary field
      ]);
    }

    String csvData = const ListToCsvConverter().convert(data);

    if (kIsWeb) {
      // For web platform
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "teachers.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/teachers.csv';
      final file = File(path);
      await file.writeAsString(csvData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
    }
  }

  Future<void> _exportTeacherListToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ['Name', 'Subject', 'Gender', 'Date of Birth', 'Hire Date', 'Email', 'Phone', 'Salary'], // Add salary field
            data: _teachers.map((teacher) {
              return [
                teacher['name'] ?? 'N/A',
                teacher['subject'] ?? 'N/A',
                teacher['gender'] ?? 'N/A',
                teacher['dob'] ?? 'N/A',
                teacher['hireDate'] ?? 'N/A',
                teacher['email'] ?? 'N/A',
                teacher['phone'] ?? 'N/A',
                teacher['salary'] ?? 'N/A', // Add salary field
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
        ..setAttribute("download", "teachers.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/teachers.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF exported to $path')));
    }
  }

  Future<void> _exportTeacherDetailsToCSV(String name, String subject, String gender, String dob, String hireDate, String email, String phone, String salary) async {
    List<List<String>> data = [
      ['Field', 'Value'],
      ['Name', name],
      ['Subject', subject],
      ['Gender', gender],
      ['Date of Birth', dob],
      ['Hire Date', hireDate],
      ['Email', email],
      ['Phone', phone],
      ['Salary', salary], // Add salary field
    ];

    String csvData = const ListToCsvConverter().convert(data);

    if (kIsWeb) {
      // For web platform
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "teacher_details.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/teacher_details.csv';
      final file = File(path);
      await file.writeAsString(csvData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
    }
  }

  Future<void> _exportTeacherDetailsToPDF(String name, String subject, String gender, String dob, String hireDate, String email, String phone, String salary) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Teacher Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Name: $name', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Subject: $subject', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Gender: $gender', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Date of Birth: $dob', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Hire Date: $hireDate', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Email: $email', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Phone: $phone', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Salary: $salary', style: pw.TextStyle(fontSize: 16)), // Add salary field
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
        ..setAttribute("download", "teacher_details.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/teacher_details.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF exported to $path')));
    }
  }

  void _showTeacherDetailsPage({
    required String teacherID,
    required String name,
    required String subject,
    required String gender,
    required String dob,
    required String hireDate,
    required String email,
    required String phone,
    required num salary,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherDetailsPage(
          teacherID: teacherID, // Pass teacherID
          name: name,
          subject: subject,
          gender: gender,
          dob: dob,
          hireDate: hireDate,
          email: email,
          phone: phone,
          salary: salary,
        ),
      ),
    );
  }
}
