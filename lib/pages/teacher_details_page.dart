import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TeacherDetailsPage extends StatefulWidget {
  final String? teacherID;
  final String? name;
  final String? subject;
  final String? gender;
  final String? dob;
  final String? hireDate;
  final String? email;
  final String? phone;
  final num? salary;

  const TeacherDetailsPage({
    Key? key,
    this.teacherID,
    this.name,
    this.subject,
    this.gender,
    this.dob,
    this.hireDate,
    this.email,
    this.phone,
    this.salary,
  }) : super(key: key);

  @override
  _TeacherDetailsPageState createState() => _TeacherDetailsPageState();
}

class _TeacherDetailsPageState extends State<TeacherDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _teacherID;
  String? _name;
  String? _subject;
  String? _gender;
  String? _dob;
  String? _hireDate;
  String? _email;
  String? _phone;
  num? _salary;

  final TextEditingController _teacherIDController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _hireDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  List<DocumentSnapshot> _tasks = [];
  List<DocumentSnapshot> _completedTasks = [];
  bool _isCompletedTasksExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTeacherDetails(); // Fetch teacher details
    _fetchTasks();
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _teacherIDController.dispose();
    _nameController.dispose();
    _subjectController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _hireDateController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {});
  }

  Future<String?> _getDocIdByTeacherId(String teacherId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .where('teacherID', isEqualTo: teacherId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  Future<void> _fetchTeacherDetails() async {
    try {
      if (widget.teacherID == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher ID is null!')),
        );
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .where('teacherID', isEqualTo: widget.teacherID)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final teacherData = snapshot.docs.first.data();
        setState(() {
          _teacherID = teacherData['teacherID'];
          _name = teacherData['name'];
          _subject = teacherData['subject'];
          _gender = teacherData['gender'];
          _dob = teacherData['dob'];
          _hireDate = teacherData['hireDate'];
          _email = teacherData['email'];
          _phone = teacherData['phone'];
          _salary = teacherData['salary'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher not found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching teacher details: $e')),
      );
    }
  }

  Future<void> _fetchTasks() async {
    try {
      if (widget.teacherID == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher ID is null!')),
        );
        return;
      }
      final realDocId = await _getDocIdByTeacherId(widget.teacherID!);
      if (widget.teacherID == null || realDocId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No document found for this teacherId!')),
        );
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(realDocId)
          .collection('tasks')
          .orderBy('date')
          .get();

      setState(() {
        _tasks = snapshot.docs.where((doc) => doc['completed'] == null || doc['completed'] == false).toList();
        _completedTasks = snapshot.docs.where((doc) => doc['completed'] == true).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching tasks: $e')),
      );
    }
  }

  Future<void> _addTask(String taskName, String taskDate, String taskTime) async {
    try {
      final realDocId = widget.teacherID != null
          ? await _getDocIdByTeacherId(widget.teacherID!)
          : null;
      if (realDocId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No document found for this teacherId!')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(realDocId)
          .collection('tasks')
          .add({
        'name': taskName,
        'date': taskDate,
        'time': taskTime,
        'completed': false,
      });
      _fetchTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }
  }

  Future<void> _markTaskAsComplete(String taskId, int index) async {
    try {
      final realDocId = widget.teacherID != null ? await _getDocIdByTeacherId(widget.teacherID!) : null;
      if (realDocId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No document found for this teacherId!')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('teachers')
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
      final realDocId = widget.teacherID != null ? await _getDocIdByTeacherId(widget.teacherID!) : null;
      if (realDocId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No document found for this teacherId!')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('teachers')
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
                Navigator.pop(context);
                _addTask(
                  taskNameController.text,
                  "${selectedDate.toLocal()}".split(' ')[0],
                  selectedTime.format(context),
                );
              },
              child: const Text('Add'),
            ),
          ],
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
                  final realDocId = widget.teacherID != null
                      ? await _getDocIdByTeacherId(widget.teacherID!)
                      : null;
                  if (realDocId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No document found for this teacherId!')),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('teachers')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _name != null && _name!.isNotEmpty ? '${_name}\'s Details' : 'Teacher Details',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Text(
                _name != null && _name!.isNotEmpty ? _name![0].toUpperCase() : '',
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
                  heroTag: 'saveTeacher',
                  onPressed: _saveTeacherDetails,
                  child: const Icon(Icons.save),
                  tooltip: 'Save',
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: 'deleteTeacher',
                  backgroundColor: Colors.red,
                  onPressed: _confirmDeleteTeacher,
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
                        Text('Teacher ID: ${_teacherID ?? ''}'),
                        Text('Subject: ${_subject ?? ''}'),
                        Text('Gender: ${_gender ?? ''}'),
                        Text('Date of Birth: ${_dob ?? ''}'),
                        Text('Hire Date: ${_hireDate ?? ''}'),
                        Text('Email: ${_email ?? ''}'),
                        Text('Phone: ${_phone ?? ''}'),
                        Text('Salary: ${_salary ?? ''}'),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: _showEditTeacherDialog,
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
                        //const Text("Work", style: TextStyle(fontWeight: FontWeight.bold)),
                        //const Divider(thickness: 1),
                        const Text("To-Do List", style: TextStyle(fontWeight: FontWeight.bold)),
                        const Divider(thickness: 1),
                        _buildTodoList(),
                        const SizedBox(height: 16),
                        _buildCompletedTasksExpansionTile(),
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

  void _showEditTeacherDialog() {
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
                  _buildTextField(_teacherIDController, 'Teacher ID'),
                  const SizedBox(height: 8),
                  _buildTextField(_subjectController, 'Subject'),
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
                _saveTeacherDetails();
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
          controller.text = newValue!;
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
            controller.text = "${picked.toLocal()}".split(' ')[0];
          }
        },
      ),
    );
  }

  Future<void> _saveTeacherDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .where('teacherID', isEqualTo: widget.teacherID)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'name': _nameController.text,
          'subject': _subjectController.text,
          'gender': _genderController.text,
          'dob': _dobController.text,
          'hireDate': _hireDateController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'salary': num.tryParse(_salaryController.text) ?? 0,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher details updated successfully!')),
        );
        _fetchTeacherDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher not found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating teacher details: $e')),
      );
    }
  }

  Future<void> _confirmDeleteTeacher() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this teacher?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteTeacher();
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

  Future<void> _deleteTeacher() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .where('teacherID', isEqualTo: widget.teacherID)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher deleted successfully!')),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher not found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting teacher: $e')),
      );
    }
  }
}