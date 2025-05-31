import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/sign_in_page.dart';
import '/pages/students_page.dart';
import '/pages/academics_page.dart';
import '/pages/settings_page.dart';

// Simple conversation model (same approach as in AdminDashboard)
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

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _userName = '';
  String _userEmail = '';
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['name'] ?? '';
          _userEmail = user.email ?? '';
        });
      }
    }
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Administration Dashboard"),
        centerTitle: true,
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
      body: _getBody(_selectedIndex),
      floatingActionButton: _selectedIndex == 0 // Conditionally show FAB
          ? FloatingActionButton(
        heroTag: 'logoutFab',
        onPressed: _confirmLogout,
        tooltip: 'Logout',
        child: const Icon(Icons.logout),
      )
      :null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildMessages(); // Use _buildMessages here
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1; // Set crossAxisCount to 1
        double cardWidth = constraints.maxWidth / crossAxisCount - 32;

        double maxWidth = cardWidth * crossAxisCount + 64;
        if (maxWidth > 600) {
          maxWidth = 600;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Center(
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                padding: const EdgeInsets.all(16.0),
                childAspectRatio: cardWidth / (cardWidth * 0.5), // Adjust childAspectRatio
                children: [
                  _buildDashboardCard(
                    context,
                    "Students",
                    Icons.school,
                    Colors.blue,
                    () => _navigateTo(const StudentsPage()),
                  ),
                  // Add more cards here as needed
                  
                ],
              ),
            ),
          ),
        );
        
      },
    );
  }

  Widget _buildMessages() {
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

                // Filter by search
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

  // Start new conversation dialog
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

  // Show conversation dialog
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
              onPressed: () => Navigator.pop(context),
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
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardCard(
      BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
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
              Icon(icon, size: 40, color: color), // Reduce icon size
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), // Reduce text size
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
      (route) => false,
    );
  }
}
