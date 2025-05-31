import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/pages/student_details_page.dart'; // Import the student details page
import '/pages/staff_details_page.dart'; // Import StaffDetailsPage
import '/pages/teacher_details_page.dart'; // Import TeacherDetailsPage

class FinancePage extends StatefulWidget {
  const FinancePage({Key? key}) : super(key: key);

  @override
  _FinancePageState createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<QueryDocumentSnapshot> _students = [];
  List<QueryDocumentSnapshot> _staff = []; // List for staff/teachers
  List<QueryDocumentSnapshot> _teachers = []; // List for teachers
  List<QueryDocumentSnapshot> _terms = []; // List for terms
  List<QueryDocumentSnapshot> _uniforms = []; // List for uniforms
  List<QueryDocumentSnapshot> _activities = []; // List for activities
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _gradeFilter = 'All';
  String _balanceFilter = 'All';
  double _minBalance = 0.0;
  double _maxBalance = double.infinity;

  // Salary Tab Filtering
  String _roleFilter = 'All'; // Filter by 'All', 'Teacher', or 'Staff'

  // Expenses Tab
  List<QueryDocumentSnapshot> _expenses = [];
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _expenseSearchController = TextEditingController(); // Search controller for expenses
  String _expenseSearchQuery = ''; // Search query for expenses

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Updated length to 4 for Charges tab
    _fetchStudents();
    _fetchStaff(); // Fetch staff data
    _fetchTeachers(); // Fetch teacher data
    _fetchExpenses(); // Fetch expenses data
    _fetchTerms(); // Fetch terms data
    _fetchUniforms(); // Fetch uniforms data
    _fetchActivities(); // Fetch activities data
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('students').orderBy('name').get();
      setState(() {
        _students = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching students: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStaff() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('staff').orderBy('name').get();
      setState(() {
        _staff = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching staff: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTeachers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('teachers').orderBy('name').get();
      setState(() {
        _teachers = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching teachers: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchExpenses() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('expenses').orderBy('date').get();
      setState(() {
        _expenses = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching expenses: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTerms() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('terms').get();
      setState(() {
        _terms = querySnapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching Terms: $e')));
    }
  }

  Future<void> _fetchUniforms() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('uniforms').get();
      setState(() {
        _uniforms = querySnapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching Uniforms: $e')));
    }
  }

  Future<void> _fetchActivities() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('activities').get();
      setState(() {
        _activities = querySnapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching Activities: $e')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _purposeController.dispose();
    _typeController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _expenseSearchController.dispose(); // Dispose the expense search controller
    super.dispose();
  }

  String _formatCollectionName(String name) {
    if (name.isEmpty) return '';
    
    // Handle endings like "activities" -> "activity", "uniforms" -> "uniform"
    if (name.toLowerCase().endsWith('ies')) {
      name = name.substring(0, name.length - 3) + 'y';
    } else if (name.toLowerCase().endsWith('s')) {
      name = name.substring(0, name.length - 1);
    }

    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  Future<void> _showEditCollectionDialog(String collectionName, QueryDocumentSnapshot doc) async {
    final TextEditingController nameController = TextEditingController(text: doc['name'].toString());
    final TextEditingController amountController = TextEditingController(text: doc['amount'].toString());

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Edit ${_formatCollectionName(collectionName)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8 > 600
                ? 600
                : MediaQuery.of(context).size.width * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cost',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                try {
                  await FirebaseFirestore.instance
                      .collection(collectionName)
                      .doc(doc.id)
                      .update({
                    'name': nameController.text.trim(),
                    'amount': double.tryParse(amountController.text.trim()) ?? 0.0,
                  });
                  Navigator.pop(context);
                  _refreshCollection(collectionName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_formatCollectionName(collectionName)} updated successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating $collectionName: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCollectionItem(String collectionName, QueryDocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${doc['name']}?'),
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
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(doc.id)
            .delete();
        _refreshCollection(collectionName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_formatCollectionName(collectionName)} deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting $collectionName: $e')),
        );
      }
    }
  }

  void _refreshCollection(String collectionName) {
    if (collectionName == 'terms') {
      _fetchTerms();
    } else if (collectionName == 'uniforms') {
      _fetchUniforms();
    } else if (collectionName == 'activities') {
      _fetchActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Finance"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Fees"),
            Tab(text: "Salaries"),
            Tab(text: "Expenses"),
            Tab(text: "Charges"), // Index 3
          ],
        ),
      ),
      // Show floating action buttons only when Charges tab (index 3) is active.
      floatingActionButton: _tabController.index == 3
          ? _buildChargesFloatingActionButtons()
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeesTab(),
          _buildSalariesTab(),
          _buildExpensesTab(),
          _buildChargesTab(),
        ],
      ),
    );
  }

  // Create a method for the Charges FABs
  Widget _buildChargesFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'addTerm',
          onPressed: () => _showAddCollectionDialog('terms'),
          tooltip: 'Add Term',
          child: const Icon(Icons.book),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'addUniform',
          onPressed: () => _showAddCollectionDialog('uniforms'),
          tooltip: 'Add Uniform',
          child: const Icon(Icons.checkroom),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'addActivity',
          onPressed: () => _showAddCollectionDialog('activities'),
          tooltip: 'Add Activity',
          child: const Icon(Icons.directions_run),
        ),
      ],
    );
  }

  Future<void> _showAddCollectionDialog(String collectionName) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Add ${_formatCollectionName(collectionName)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8 > 600
                ? 600
                : MediaQuery.of(context).size.width * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cost',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                try {
                  await FirebaseFirestore.instance.collection(collectionName).add({
                    'name': nameController.text.trim(),
                    'amount': double.tryParse(amountController.text.trim()) ?? 0.0,
                  });
                  Navigator.pop(context);
                  _refreshCollection(collectionName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_formatCollectionName(collectionName)} added successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding $collectionName: $e')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_students.isEmpty) {
      return const Center(child: Text("No students found."));
    }

    // Filter students based on search query, grade, and balance
    List<QueryDocumentSnapshot> filteredStudents = _students.where((student) {
      final name = student['name'].toString().toLowerCase();
      final grade = student['grade'].toString();
      final fees = student['fees'] as Map<String, dynamic>? ?? {};
      final balance = (fees['balance'] as num?)?.toDouble() ?? 0.0;
      final admissionNumber = student['admissionNumber'].toString().toLowerCase();
      final dob = student['dob'].toString().toLowerCase();
      final gender = student['gender'].toString().toLowerCase();

      // Apply search query filter to all relevant fields
      final nameMatch = name.contains(_searchQuery.toLowerCase());
      final admissionNumberMatch = admissionNumber.contains(_searchQuery.toLowerCase());
      final dobMatch = dob.contains(_searchQuery.toLowerCase());
      final genderMatch = gender.contains(_searchQuery.toLowerCase());

      // Apply grade filter
      final gradeMatch = _gradeFilter == 'All' || grade == _gradeFilter;

      // Apply balance filter
      bool balanceMatch = true;
      if (_balanceFilter == 'Range') {
        balanceMatch = balance >= _minBalance && balance <= _maxBalance;
      } else if (_balanceFilter != 'All') {
        balanceMatch = true; // Modify this based on your specific balance filter logic
      }

      return (nameMatch || admissionNumberMatch || dobMatch || genderMatch) && gradeMatch && balanceMatch;
    }).toList();

    // Calculate total balance of filtered students
    double totalBalance = filteredStudents.fold(0.0, (sum, student) {
      final fees = student['fees'] as Map<String, dynamic>? ?? {};
      final balance = (fees['balance'] as num?)?.toDouble() ?? 0.0;
      return sum + balance;
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
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
                items: ['All', '6', '7', '8', '9', '10', '11', '12'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _gradeFilter = newValue!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _balanceFilter,
                decoration: InputDecoration(
                  labelText: 'Filter by Balance',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['All', 'Range'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _balanceFilter = newValue!;
                    if (_balanceFilter == 'Range') {
                      _showBalanceRangeDialog(context);
                    }
                  });
                },
              ),
              const SizedBox(height: 10),
              Text('Total Balance: ${totalBalance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)), // Display total balance
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Limit width on large screens
                    double maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 600;
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: ListView.builder(
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            // Access the 'fees' map
                            final fees = student['fees'] as Map<String, dynamic>? ?? {};

                            // Access 'totalFees' and 'balance' from the 'fees' map
                            final totalFees = fees['totalFees'] ?? 0.0;
                            final balance = fees['balance'] ?? 0.0;

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
                                      Text('Total Fees: ${totalFees.toStringAsFixed(2)}'),
                                      Text('Balance: ${balance.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StudentDetailsPage(
                                          //studentId: student.id, // If you can get the student ID, uncomment this
                                          name: student['name'],
                                          admissionNumber: student['admissionNumber'] ?? 'N/A',
                                          grade: student['grade'],
                                          gender: student['gender'],
                                          dob: student['dob'],
                                          registrationDate: student['registrationDate'],
                                          mother: student['mother'] as Map<String, dynamic>? ?? {},
                                          father: student['father'] as Map<String, dynamic>? ?? {},
                                          fees: student['fees'] as Map<String, dynamic>? ?? {}, // Pass the fees map
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
    );
  }

  Future<void> _showBalanceRangeDialog(BuildContext context) async {
    double minBalance = _minBalance;
    double maxBalance = _maxBalance;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Balance Range'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min Balance'),
                    initialValue: _minBalance == 0.0 ? '' : _minBalance.toString(),
                    onChanged: (value) {
                      minBalance = double.tryParse(value) ?? _minBalance;
                    },
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Balance'),
                    initialValue: _maxBalance == double.infinity ? '' : _maxBalance.toString(),
                    onChanged: (value) {
                      maxBalance = double.tryParse(value) ?? _maxBalance;
                    },
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Apply'),
              onPressed: () {
                setState(() {
                  _minBalance = minBalance;
                  _maxBalance = maxBalance;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSalariesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_staff.isEmpty && _teachers.isEmpty) {
      return const Center(child: Text("No staff or teachers found."));
    }

    // Combine staff and teachers into a single list
    List<QueryDocumentSnapshot> combinedList = [..._staff, ..._teachers];

    // Apply role filter
    List<QueryDocumentSnapshot> filteredList = combinedList.where((item) {
      if (_roleFilter == 'All') {
        return true; // Show all
      } else if (_roleFilter == 'Teacher') {
        return _teachers.contains(item); // Show only teachers
      } else if (_roleFilter == 'Staff') {
        return _staff.contains(item); // Show only staff
      }
      return false;
    }).where((item) {
      final name = item['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort the filtered list
    filteredList.sort((a, b) {
      final aName = a['name'].toString().toLowerCase();
      final bName = b['name'].toString().toLowerCase();
      return aName.compareTo(bName);
    });

    double totalSalaries = filteredList.fold(0.0, (sum, item) {
      // Safely convert salary to double, providing a default value of 0.0 if conversion fails
      final salary = num.tryParse(item['salary']?.toString() ?? '0')?.toDouble() ?? 0.0;
      return sum + salary;
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search staff and teachers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _roleFilter,
                decoration: InputDecoration(
                  labelText: 'Filter by Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['All', 'Teacher', 'Staff'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _roleFilter = newValue!;
                  });
                },
              ),
              const SizedBox(height: 10),
              Text('Total Salaries: ${totalSalaries.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 600;
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final salary = num.tryParse(item['salary']?.toString() ?? '0')?.toDouble() ?? 0.0;
                            Color avatarColor = Colors.green; // Default color for staff

                            // Check if the item is a teacher and set the avatar color to orange
                            if (_teachers.contains(item)) {
                              avatarColor = Colors.orange;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: CircleAvatar(
                                    backgroundColor: avatarColor,
                                    child: Text(
                                      item['name'][0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Salary: ${salary.toStringAsFixed(2)}'),
                                  onTap: () {
                                    if (_staff.contains(item)) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StaffDetailsPage(
                                            staffId: item['staffId'],
                                            name: item['name'],
                                            position: item['position'] ?? 'N/A',
                                            gender: item['gender'] ?? 'N/A',
                                            dob: item['dob'] ?? 'N/A',
                                            hireDate: item['hireDate'] ?? 'N/A',
                                            email: item['email'] ?? 'N/A',
                                            phone: item['phone'] ?? 'N/A',
                                            salary: item['salary'] ?? 0.0,
                                          ),
                                        ),
                                      );
                                    } else if (_teachers.contains(item)) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TeacherDetailsPage(
                                            teacherID: item['teacherID'],
                                            name: item['name'],
                                            subject: item['subject'],
                                            gender: item['gender'],
                                            dob: item['dob'],
                                            hireDate: item['hireDate'],
                                            email: item['email'],
                                            phone: item['phone'],
                                            salary: item['salary'],
                                          ),
                                        ),
                                      );
                                    }
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
    );
  }

  Widget _buildExpensesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_expenses.isEmpty) {
      return const Center(child: Text("No expenses found."));
    }

    // Filter expenses based on search query
    List<QueryDocumentSnapshot> filteredExpenses = _expenses.where((expense) {
      final purpose = expense['purpose'].toString().toLowerCase();
      final type = expense['type'].toString().toLowerCase();
      return purpose.contains(_expenseSearchQuery.toLowerCase()) || type.contains(_expenseSearchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                TextField(
                  controller: _expenseSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _expenseSearchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 600;
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: ListView.builder(
                            itemCount: filteredExpenses.length,
                            itemBuilder: (context, index) {
                              final expense = filteredExpenses[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    title: Text(expense['purpose'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Type: ${expense['type']}'),
                                        Text('Date: ${expense['date']}'),
                                        Text('Amount: ${expense['amount']}'),
                                      ],
                                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addExpense() async {
    try {
      await FirebaseFirestore.instance.collection('expenses').add({
        'purpose': _purposeController.text.trim(),
        'type': _typeController.text.trim(),
        'date': _dateController.text.trim(),
        'amount': _amountController.text.trim(),
      });
      _fetchExpenses(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding expense: $e')),
      );
    }
  }

  void _showAddExpenseDialog(BuildContext context) {
    _purposeController.clear();
    _typeController.clear();
    _dateController.clear();
    _amountController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Expense'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8 > 500 ? 500 : MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPurposeDropdown(_purposeController),
                  _buildTypeDropdown(_typeController), // Use the type dropdown
                  _buildDateField(_dateController, 'Date'),
                  _buildTextField(_amountController, 'Amount'),
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
                _addExpense();
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPurposeDropdown(TextEditingController controller) {
    const List<String> expensePurposes = [
      'Salaries',
      'Utilities (Electricity, Water, Gas)',
      'Rent',
      'Supplies (Stationery, Cleaning)',
      'Maintenance and Repairs',
      'Transportation',
      'Technology and Equipment',
      'Curriculum Development',
      'Training and Professional Development',
      'Marketing and Advertising',
      'Insurance',
      'Taxes',
      'Other'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: 'Purpose',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: expensePurposes.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          controller.text = newValue!;
        },
      ),
    );
  }

  Widget _buildTypeDropdown(TextEditingController controller) {
    const List<String> expenseTypes = [
      'Bank Transfer',
      'Mobile Money',
      'Card',
      'Cash'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: 'Type',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: expenseTypes.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          controller.text = newValue!;
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Widget _buildChargesTab() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // Use a small app bar area to hold the nested TabBar
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            //color: Theme.of(context).primaryColor,
            child: const TabBar(
              //labelColor: Colors.white,
              tabs: [
                Tab(text: 'Terms'),
                Tab(text: 'Uniforms'),
                Tab(text: 'Activities'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildTermList(),
            _buildUniformList(),
            _buildActivityList(),
          ],
        ),
        // Display your addTerm, addUniform, addActivity FABs here
        floatingActionButton: _buildChargesFloatingActionButtons(),
      ),
    );
  }

  Widget _buildTermList() {
    if (_terms.isEmpty) {
      return const Center(child: Text('No Terms found'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 600;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView.builder(
              itemCount: _terms.length,
              itemBuilder: (context, index) {
                final doc = _terms[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    leading: const Icon(Icons.library_books, color: Colors.blue),
                    title: Text(
                      doc['name'] ?? 'Unnamed',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Cost: ${doc['amount'] ?? 0}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.purple),
                          onPressed: () => _showEditCollectionDialog('terms', doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCollectionItem('terms', doc),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildUniformList() {
    if (_uniforms.isEmpty) {
      return const Center(child: Text('No Uniforms found'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 600;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView.builder(
              itemCount: _uniforms.length,
              itemBuilder: (context, index) {
                final doc = _uniforms[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    leading: const Icon(Icons.checkroom, color: Colors.green),
                    title: Text(
                      doc['name'] ?? 'Unnamed',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Cost: ${doc['amount'] ?? 0}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.purple),
                          onPressed: () => _showEditCollectionDialog('uniforms', doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCollectionItem('uniforms', doc),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityList() {
    if (_activities.isEmpty) {
      return const Center(child: Text('No Activities found'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 600;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView.builder(
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final doc = _activities[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    leading: const Icon(Icons.run_circle_outlined, color: Colors.orange),
                    title: Text(
                      doc['name'] ?? 'Unnamed',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Cost: ${doc['amount'] ?? 0}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.purple),
                          onPressed: () => _showEditCollectionDialog('activities', doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCollectionItem('activities', doc),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
