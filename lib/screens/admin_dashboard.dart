import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/sign_in_page.dart';
import '../auth/sign_up_page.dart';
import '/pages/students_page.dart';
import '/pages/teachers_page.dart';
import '/pages/staff_page.dart';
import '/pages/academics_page.dart';
import '/pages/finance_page.dart';
import '/pages/procurement_page.dart';
import '/pages/settings_page.dart';

class Conversation {
  final String otherUserEmail;
  final String otherUserName;

  Conversation({required this.otherUserEmail, required this.otherUserName});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation && other.otherUserEmail == otherUserEmail;
  }

  @override
  int get hashCode => otherUserEmail.hashCode;
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  String _userEmail = '';
  String _userName = '';
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _userEmail = user.email ?? '';
      _fetchUserName(user.uid);
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _messageFocusNode.dispose();
    super.dispose();
  }

  // Fetch name from Firestore
  Future<void> _fetchUserName(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data['name'] != null) {
        setState(() => _userName = data['name']);
      }
    }
  }

  Widget _buildDashboard(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          int crossAxisCount = 2;
          double cardWidth = constraints.maxWidth / crossAxisCount - 32;

          double maxWidth = cardWidth * crossAxisCount + 64;
          if (maxWidth > 600) {
            maxWidth = 600;
          }

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                padding: const EdgeInsets.all(16.0),
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: cardWidth / (cardWidth * 0.8),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  _buildDashboardCard(
                    context,
                    "Students",
                    Icons.school,
                    Colors.blue,
                    () => _navigateTo(const StudentsPage()),
                  ),
                  _buildDashboardCard(
                    context,
                    "Teachers",
                    Icons.person,
                    Colors.orange,
                    () => _navigateTo(const TeachersPage()),
                  ),
                  _buildDashboardCard(
                    context,
                    "Staff",
                    Icons.group,
                    Colors.green,
                    () => _navigateTo(const StaffPage()),
                  ),
                  _buildDashboardCard(
                    context,
                    "Finance",
                    Icons.attach_money,
                    Colors.purple,
                    () => _navigateTo(const FinancePage()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  void _navigateTo(Widget page) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}


  Widget _buildMessages(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double searchBarWidth = constraints.maxWidth * 0.8;
                  if (searchBarWidth > 600) searchBarWidth = 600;

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
            Expanded(child: _buildConversationList()),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _startNewConversationDialog,
            child: const Icon(Icons.add),
            tooltip: 'Start Chat',
          ),
        ),
      ],
    );
  }

  Widget _buildConversationList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double computedWidth = constraints.maxWidth * 0.8;
        if (computedWidth > 600) computedWidth = 600;

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
                final filteredList = convList.where((conv) {
                  final nameLC = conv.otherUserName.toLowerCase();
                  final emailLC = conv.otherUserEmail.toLowerCase();
                  return nameLC.contains(_searchQuery) || emailLC.contains(_searchQuery);
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text('No conversations found.'));
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: computedWidth),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    _userEmail.isEmpty) {
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

  void _showConversationDialog(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) {
        final newMsgController = TextEditingController();
        double dialogWidth = MediaQuery.of(context).size.width * 0.8;
        if (dialogWidth > 600) dialogWidth = 600;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          .orderBy('timestamp', descending: false)
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
                          return (sEmail == _userEmail &&
                                  rEmail == conversation.otherUserEmail) ||
                              (sEmail == conversation.otherUserEmail &&
                                  rEmail == _userEmail);
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
                  focusNode: _messageFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                final msg = newMsgController.text.trim();
                if (msg.isEmpty) return;
                await _firestore.collection('messages').add({
                  'senderEmail': _userEmail,
                  'senderName': _userName,
                  'recipientEmail': conversation.otherUserEmail,
                  'recipientName': conversation.otherUserName,
                  'text': msg,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                newMsgController.clear();
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    ).then((_) {
      // Request focus after the dialog is closed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageFocusNode.requestFocus();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _tabs = [
      _buildDashboard(context),
      _buildMessages(context),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Management Dashboard',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      /*drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightBlue),
              child: Text("Menu", style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            _buildDrawerItem(Icons.dashboard, "Dashboard",
                () => _navigateTo(const AdminDashboard())),
            _buildDrawerItem(Icons.school, "Students",
                () => _navigateTo(const StudentsPage())),
            _buildDrawerItem(Icons.person, "Teachers",
                () => _navigateTo(const TeachersPage())),
            _buildDrawerItem(Icons.group, "Staff",
                () => _navigateTo(const StaffPage())),
            _buildDrawerItem(Icons.book, "Academics",
                () => _navigateTo(const AcademicsPage())),
            _buildDrawerItem(Icons.attach_money, "Finance",
                () => _navigateTo(const FinancePage())),
            _buildDrawerItem(Icons.shopping_cart, "Procurement",
                () => _navigateTo(const ProcurementPage())),
            _buildDrawerItem(Icons.settings, "Settings",
                () => _navigateTo(const SettingsPage())),
            const Divider(),
            _buildDrawerItem(Icons.logout, "Logout", _confirmLogout),
          ],
        ),
      ),*/
      body: _tabs[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'addUserFab',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                    );
                  },
                  tooltip: 'Add User',
                  child: const Icon(Icons.person_add),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'logoutFab',
                  onPressed: _confirmLogout,
                  tooltip: 'Logout',
                  child: const Icon(Icons.logout),
                ),
              ],
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
        ],
        onTap: (int index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 60, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: _logout,
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
      (route) => false,
    );
  }
}