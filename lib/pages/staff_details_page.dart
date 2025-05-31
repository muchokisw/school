import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StaffDetailsPage extends StatefulWidget {
  final String staffId;
  final String name;
  final String position;
  final String gender;
  final String dob;
  final String hireDate;
  final String email;
  final String phone;
  final num salary; // Change salary to num

  const StaffDetailsPage({
    Key? key,
    required this.staffId,
    required this.name,
    required this.position,
    required this.gender,
    required this.dob,
    required this.hireDate,
    required this.email,
    required this.phone,
    required this.salary,
  }) : super(key: key);

  @override
  _StaffDetailsPageState createState() => _StaffDetailsPageState();
}

class _StaffDetailsPageState extends State<StaffDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _staffID;
  String? _name;
  String? _position;
  String? _gender;
  String? _dob;
  String? _hireDate;
  String? _email;
  String? _phone;
  num? _salary; // Change salary to num

  final TextEditingController _staffIDController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _hireDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  // To-Do List
  List<DocumentSnapshot> _tasks = [];
  List<DocumentSnapshot> _completedTasks = [];
  bool _isCompletedTasksExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchStaffDetails();
    _fetchTasks();
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _fetchStaffDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('staff')
          .where('staffId', isEqualTo: widget.staffId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final staffData = snapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          _staffID = staffData['staffId'] ?? 'N/A';
          _name = staffData['name'] ?? 'N/A';
          _position = staffData['position'] ?? 'N/A';
          _gender = staffData['gender'] ?? 'N/A';
          _dob = staffData['dob'] ?? 'N/A';
          _hireDate = staffData['hireDate'] ?? 'N/A';
          _email = staffData['email'] ?? 'N/A';
          _phone = staffData['phone'] ?? 'N/A';
          _salary = staffData['salary'] ?? 0; // Change salary to num

          _staffIDController.text = _staffID ?? '';
          _nameController.text = _name ?? '';
          _positionController.text = _position ?? '';
          _genderController.text = _gender ?? '';
          _dobController.text = _dob ?? '';
          _hireDateController.text = _hireDate ?? '';
          _emailController.text = _email ?? '';
          _phoneController.text = _phone ?? '';
          _salaryController.text = _salary?.toString() ?? ''; // Convert to string for the controller
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff not found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching staff details: $e')),
      );
    }
  }

  Future<String?> _getDocIdByStaffId(String staffId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('staff')
        .where('staffId', isEqualTo: staffId)
        .limit(1) // We only need one matching doc
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id; // Return the doc's auto-generated ID
    }
    return null; // Not found
  }

  Future<void> _fetchTasks() async {
    try {
      //print('Fetching tasks for staffId: ${widget.staffId}');
      final realDocId = await _getDocIdByStaffId(widget.staffId);
      if (realDocId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No document found for this staffId!')),
        );
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('staff')
          .doc(realDocId)
          .collection('tasks')
          .orderBy('date')
          .get();

      setState(() {
        _tasks = snapshot.docs.where((doc) => doc['completed'] == null || doc['completed'] == false).toList();
        _completedTasks = snapshot.docs.where((doc) => doc['completed'] == true).toList();
      });
      //print('Active tasks: ${_tasks.length}, Completed tasks: ${_completedTasks.length}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching tasks: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _staffIDController.dispose();
    _nameController.dispose();
    _positionController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _hireDateController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _saveStaffDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('staff')
          .where('staffId', isEqualTo: widget.staffId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'staffId': _staffIDController.text,
          'name': _nameController.text,
          'position': _positionController.text,
          'gender': _genderController.text,
          'dob': _dobController.text,
          'hireDate': _hireDateController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'salary': num.tryParse(_salaryController.text) ?? 0, // Parse back to num
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff details updated successfully!')),
        );
        _fetchStaffDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff not found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating staff details: $e')),
      );
    }
  }

  Future<void> _deleteStaff() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('staff')
          .where('staffId', isEqualTo: widget.staffId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff deleted successfully!')),
        );

        Navigator.pop(context); // Navigate back to the previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff not found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting staff: $e')),
      );
    }
  }

  void _confirmDeleteStaff() {
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
            ElevatedButton(
              onPressed: () {
                _deleteStaff();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.name != null && widget.name!.isNotEmpty ? '${widget.name}\'s Details' : 'Staff Details',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                widget.name != null && widget.name!.isNotEmpty ? widget.name![0].toUpperCase() : '',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Work'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildWorkTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'saveStaff',
                  onPressed: _showEditStaffDialog,
                  child: const Icon(Icons.save),
                  tooltip: 'Save',
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: 'deleteStaff',
                  backgroundColor: Colors.red,
                  onPressed: _confirmDeleteStaff,
                  child: const Icon(Icons.delete),
                  tooltip: 'Delete',
                ),
              ],
            )
          : FloatingActionButton(
              heroTag: 'addTask',
              onPressed: _showAddTaskDialog,
              child: const Icon(Icons.add),
              tooltip: 'Add Task',
            ),
    );
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
                        const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
                        const Divider(thickness: 1),
                        Text('Name: ${_name ?? ''}'),
                        Text('Staff ID: ${_staffID ?? ''}'),
                        Text('Position: ${_position ?? ''}'), // Added Position here
                        Text('Gender: ${_gender ?? ''}'),
                        Text('Date of Birth: ${_dob ?? ''}'),
                        Text('Hire Date: ${_hireDate ?? ''}'),
                        Text('Email: ${_email ?? ''}'),
                        Text('Phone: ${_phone ?? ''}'),
                        Text('Salary: ${_salary ?? ''}'),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: _showEditStaffDialog,
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

  Widget _buildWorkTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth * 0.8;
        if (maxWidth > 600) maxWidth = 600;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth), // Provide the constraints
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
                        //const Text("Work", style: TextStyle(fontWeight: FontWeight.bold)),
                        //const Divider(thickness: 1),
                        //Text('Position: ${_position ?? ''}'),
                        //const SizedBox(height: 16),
                        const Text("To-Do List", style: TextStyle(fontWeight: FontWeight.bold)),
                        const Divider(thickness: 1),
                        _buildTodoList(),
                        const SizedBox(height: 16),
                        _buildCompletedTasksExpansionTile(), // Use the ExpansionTile here
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

  void _showEditTaskDialog(DocumentSnapshot task) {
    final TextEditingController taskNameController = TextEditingController(text: task['name']);
    DateTime selectedDate = DateTime.tryParse(task['date']) ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(DateTime.now());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: SizedBox(
            width:
                MediaQuery.of(context).size.width < 600 ? MediaQuery.of(context).size.width * 0.8 : 600,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskNameController,
                      decoration: const InputDecoration(labelText: 'Task Name'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Date: '),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: Text("${selectedDate.toLocal()}".split(' ')[0]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Time: '),
                        TextButton(
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: Text(selectedTime.format(context)),
                        ),
                      ],
                    ),
                  ],
                );
              },
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
                  final realDocId = await _getDocIdByStaffId(widget.staffId);
                  if (realDocId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No document found for this staffId!')),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('staff')
                      .doc(realDocId)
                      .collection('tasks')
                      .doc(task.id)
                      .update({
                    'name': taskNameController.text,
                    'date': "${selectedDate.toLocal()}".split(' ')[0],
                    'time': selectedTime.format(context),
                  });
                  _fetchTasks();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating task: $e')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodoList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final bool isCompleted = task['completed'] == true;
        return ListTile(
          title: Text(task['name'] ?? ''),
          subtitle: Text('${task['date']} ${task['time']}'),
          leading: Checkbox(
            value: isCompleted,
            onChanged: (bool? value) {
              _markTaskAsComplete(task.id, index);
            },
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditTaskDialog(task),
          ),
        );
      },
    );
  }

  Future<void> _markTaskAsComplete(String taskId, int index) async {
    try {
      final realDocId = await _getDocIdByStaffId(widget.staffId);
      if (realDocId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No document found for this staffId!')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('staff')
          .doc(realDocId)
          .collection('tasks')
          .doc(taskId)
          .update({'completed': true});

      _fetchTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking task as complete: $e')),
      );
    }
  }

  Future<void> _markTaskAsIncomplete(String taskId) async {
    try {
      final realDocId = await _getDocIdByStaffId(widget.staffId);
      if (realDocId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No document found for this staffId!')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('staff')
          .doc(realDocId)
          .collection('tasks')
          .doc(taskId)
          .update({'completed': false});

      _fetchTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking task as incomplete: $e')),
      );
    }
  }

  Widget _buildCompletedTasksExpansionTile() {
    return ExpansionTile(
      title: const Text('Completed Tasks'),
      children: _completedTasks.map((task) {
        return ListTile(
          title: Text(task['name'] ?? ''),
          subtitle: Text('${task['date']} ${task['time']}'),
          trailing: IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => _markTaskAsIncomplete(task.id),
          ),
        );
      }).toList(),
    );
  }

  void _showAddTaskDialog() {
    final TextEditingController taskNameController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: SizedBox(
            width:
                MediaQuery.of(context).size.width < 600 ? MediaQuery.of(context).size.width * 0.8 : 600,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskNameController,
                      decoration: const InputDecoration(labelText: 'Task Name'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Date: '),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: Text("${selectedDate.toLocal()}".split(' ')[0]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Time: '),
                        TextButton(
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: Text(selectedTime.format(context)),
                        ),
                      ],
                    ),
                  ],
                );
              },
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
                  final realDocId = await _getDocIdByStaffId(widget.staffId);
                  if (realDocId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No document found for this staffId!')),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('staff')
                      .doc(realDocId)
                      .collection('tasks')
                      .add({
                    'name': taskNameController.text,
                    'date': "${selectedDate.toLocal()}".split(' ')[0],
                    'time': selectedTime.format(context),
                    'completed': false,
                  });
                  _fetchTasks();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding task: $e')),
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

  void _showEditStaffDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_nameController, 'Name'),
                  const SizedBox(height: 8),
                  _buildTextField(_staffIDController, 'Staff ID'),
                  const SizedBox(height: 8),
                  _buildTextField(_positionController, 'Position'),
                  const SizedBox(height: 8),
                  _buildGenderField(_genderController),
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
                _saveStaffDetails();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
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
        keyboardType: label == 'Salary' ? TextInputType.number : TextInputType.text, // Set keyboard type for salary
      ),
    );
  }

  Widget _buildGenderField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
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
            controller.text = newValue!;
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
    final DateTime? picked = await showDatePicker(
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
}