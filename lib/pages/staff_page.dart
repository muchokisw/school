import 'package:auth/pages/staff_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert'; // For utf8
import 'package:flutter/foundation.dart' show kIsWeb; // For platform check
import 'package:pdf/pdf.dart'; // Corrected import
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  _StaffPageState createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for text fields
  final TextEditingController _staffIdController = TextEditingController(); // Staff ID
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _hireDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController(); // Salary
  final TextEditingController _searchController = TextEditingController();

  // List to store staff members
  List<DocumentSnapshot> _staff = [];

  // Search query
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAllStaff(); // Fetch all staff members
  }

  Future<void> _fetchAllStaff() async {
    final snapshot = await _firestore.collection('staff').orderBy('name').get();
    setState(() {
      _staff = snapshot.docs;
    });
  }

  Future<void> _exportStaffListToCSV() async {
    List<List<String>> data = [
      ['Staff ID', 'Name', 'Position', 'Gender', 'Date of Birth', 'Hire Date', 'Email', 'Phone', 'Salary'] // Staff ID
    ];

    for (var staff in _staff) {
      data.add([
        staff['staffId'] ?? 'N/A', // Staff ID
        staff['name'] ?? 'N/A',
        staff['position'] ?? 'N/A',
        staff['gender'] ?? 'N/A',
        staff['dob'] ?? 'N/A',
        staff['hireDate'] ?? 'N/A',
        staff['email'] ?? 'N/A',
        staff['phone'] ?? 'N/A',
        staff['salary'] ?? 'N/A', // Salary
      ]);
    }

    String csvData = const ListToCsvConverter().convert(data);

    if (kIsWeb) {
      // For web platform
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "staff.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/staff.csv';
      final file = File(path);
      await file.writeAsString(csvData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
    }
  }

  Future<void> _exportStaffListToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ['Staff ID', 'Name', 'Position', 'Gender', 'Date of Birth', 'Hire Date', 'Email', 'Phone', 'Salary'], // Staff ID
            data: _staff.map((staff) {
              return [
                staff['staffId'] ?? 'N/A', // Staff ID
                staff['name'] ?? 'N/A',
                staff['position'] ?? 'N/A',
                staff['gender'] ?? 'N/A',
                staff['dob'] ?? 'N/A',
                staff['hireDate'] ?? 'N/A',
                staff['email'] ?? 'N/A',
                staff['phone'] ?? 'N/A',
                staff['salary'] ?? 'N/A', // Salary
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
        ..setAttribute("download", "staff.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/staff.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF exported to $path')));
    }
  }

  Future<void> _exportStaffDetailsToCSV(String staffId, String name, String position, String gender, String dob, String hireDate, String email, String phone, String salary) async { // Staff ID
    List<List<String>> data = [
      ['Field', 'Value'],
      ['Staff ID', staffId], // Staff ID
      ['Name', name],
      ['Position', position],
      ['Gender', gender],
      ['Date of Birth', dob],
      ['Hire Date', hireDate],
      ['Email', email],
      ['Phone', phone],
      ['Salary', salary], // Salary
    ];

    String csvData = const ListToCsvConverter().convert(data);

    if (kIsWeb) {
      // For web platform
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "staff_details.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/staff_details.csv';
      final file = File(path);
      await file.writeAsString(csvData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
    }
  }

  Future<void> _exportStaffDetailsToPDF(String staffId, String name, String position, String gender, String dob, String hireDate, String email, String phone, String salary) async { // Staff ID
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Staff Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Staff ID: $staffId', style: pw.TextStyle(fontSize: 16)), // Staff ID
              pw.Text('Name: $name', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Position: $position', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Gender: $gender', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Date of Birth: $dob', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Hire Date: $hireDate', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Email: $email', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Phone: $phone', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Salary: $salary', style: pw.TextStyle(fontSize: 16)), // Salary
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
        ..setAttribute("download", "staff_details.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // For mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/staff_details.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF exported to $path')));
    }
  }

  // Add a new staff member to Firestore
  Future<void> _addStaff() async {
    await _firestore.collection('staff').add({
      'staffId': _staffIdController.text.trim(), // Staff ID
      'name': _nameController.text.trim(),
      'position': _positionController.text.trim(),
      'gender': _genderController.text.trim(),
      'dob': _dobController.text.trim(),
      'hireDate': _hireDateController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'salary': _salaryController.text.trim(), // Salary
    });
    _fetchAllStaff(); // Refresh the list after adding a staff member
  }

  // Update an existing staff member in Firestore
  Future<void> _updateStaff(String id) async {
    await _firestore.collection('staff').doc(id).update({
      'staffId': _staffIdController.text.trim(), // Staff ID
      'name': _nameController.text.trim(),
      'position': _positionController.text.trim(),
      'gender': _genderController.text.trim(),
      'dob': _dobController.text.trim(),
      'hireDate': _hireDateController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'salary': _salaryController.text.trim(), // Salary
    });
    _fetchAllStaff(); // Refresh the list after updating a staff member
  }

  // Delete a staff member from Firestore
  Future<void> _deleteStaff(String id) async {
    await _firestore.collection('staff').doc(id).delete();
    _fetchAllStaff(); // Refresh the list after deleting a staff member
  }

  void _confirmDeleteStaff(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this staff member?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteStaff(id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Show dialog for adding/editing a staff member
  void _showStaffDialog({String? id, String? staffId, String? name, String? position, String? gender, String? dob, String? hireDate, String? email, String? phone, String? salary}) { // Staff ID
    // Pre-fill text fields if editing an existing staff member
    _staffIdController.text = staffId ?? ''; // Staff ID
    _nameController.text = name ?? '';
    _positionController.text = position ?? '';
    _genderController.text = gender ?? '';
    _dobController.text = dob ?? '';
    _hireDateController.text = hireDate ?? '';
    _emailController.text = email ?? '';
    _phoneController.text = phone ?? '';
    _salaryController.text = salary ?? ''; // Salary

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
                      Text(id == null ? 'Add Staff' : 'Edit Staff',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),

                      // Staff details fields
                      _buildTextField(_staffIdController, 'Staff ID'), // Staff ID
                      const SizedBox(height: 8),
                      _buildTextField(_nameController, 'Staff Name'),
                      const SizedBox(height: 8),
                      _buildTextField(_positionController, 'Position'),
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
                      _buildTextField(_salaryController, 'Salary'), // Salary
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
                                _addStaff(); // Add new staff member
                              } else {
                                _updateStaff(id); // Update existing staff member
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

  // Show staff details dialog
  void _showStaffDetailsDialog(String staffId, String name, String position, String gender, String dob, String hireDate, String email, String phone, String salary) { // Staff ID
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
                      // Staff name and position
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), // Staff ID
                      Text('Staff ID: $staffId'), // Staff ID
                      Text('Position: $position'),
                      Text('Gender: $gender'),
                      Text('Date of Birth: $dob'),
                      Text('Hire Date: $hireDate'),
                      Text('Email: $email'),
                      Text('Phone: $phone'),
                      Text('Salary: $salary'), // Salary
                      const SizedBox(height: 16),

                      // Export buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _exportStaffDetailsToCSV(staffId, name, position, gender, dob, hireDate, email, phone, salary), // Staff ID
                            icon: const Icon(Icons.download),
                            label: const Text('CSV'),
                          ),
                          TextButton.icon(
                            onPressed: () => _exportStaffDetailsToPDF(staffId, name, position, gender, dob, hireDate, email, phone, salary), // Staff ID
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('PDF'),
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

  Widget _buildDateField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onTap: () async {
          FocusScope.of(context).requestFocus(FocusNode());
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
        },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff List'), // Or any other suitable title
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportStaffListToCSV,
            tooltip: 'Export to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportStaffListToPDF,
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
                    hintText: 'Search staff...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                      _fetchAllStaff(); // Fetch all staff when search query changes
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Staff list
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Limit width on large screens
                      double maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 600;
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: ListView.builder(
                            itemCount: _staff.length,
                            itemBuilder: (context, index) {
                              var staff = _staff[index];
                              var staffId = staff['staffId'].toString().toLowerCase(); // Staff ID
                              var name = staff['name'].toString().toLowerCase();
                              var position = staff['position'].toString().toLowerCase();
                              var gender = staff['gender'].toString().toLowerCase();
                              if (_searchQuery.isNotEmpty && !staffId.contains(_searchQuery) && !name.contains(_searchQuery) && !position.contains(_searchQuery) && !gender.contains(_searchQuery)) { // Staff ID
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
                                      backgroundColor: Colors.green,
                                      child: Text(
                                        staff['name'][0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(staff['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Staff ID: ${staff['staffId']}'), // Staff ID
                                        Text('Position: ${staff['position']}'),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StaffDetailsPage(
                                            staffId: staff['staffId'] ?? 'N/A',
                                            name: staff['name'] ?? 'N/A',
                                            position: staff['position'] ?? 'N/A',
                                            gender: staff['gender'] ?? 'N/A',
                                            dob: staff['dob'] ?? 'N/A',
                                            hireDate: staff['hireDate'] ?? 'N/A',
                                            email: staff['email'] ?? 'N/A',
                                            phone: staff['phone'] ?? 'N/A',
                                            salary: staff['salary'] ?? 'N/A',
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Floating action button to add a new staff member
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStaffDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
