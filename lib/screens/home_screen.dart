import 'package:calling/controller/call_controller.dart';
import 'package:calling/screens/all_user_screen.dart';
import 'package:calling/screens/friends/friends_screen.dart';
import 'package:calling/screens/profile_screen.dart';
import 'package:calling/widgets/call_dialgue.dart';
import 'package:calling/widgets/drawer.dart';
import 'package:calling/widgets/friends_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final String userId;
  final CallController _callController = CallController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      _listenIncomingCalls();
    }
  }

  void _listenIncomingCalls() {
    _callController.listenIncomingOneToOneCalls(
      userId: userId,
      context: context,
      onIncoming: _showIncomingOneToOneDialog,
      onEnded: ({bool rejected = false}) {
        if (mounted) {
          CallDialogs.showCallEndedDialog(context, rejected: rejected);
        }
      },
    );

    _callController.listenIncomingGroupCalls(
      userId: userId,
      context: context,
      onIncoming: _showIncomingGroupDialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: AboutAppDrawer(),
      appBar: AppBar(
        title: const Text("Convo Home"),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
             Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FriendsScreen(meUid: userId)),
          );
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.people),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const ProfileScreen()),
          //     );
          //   },
          // ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigation Card
             
          

              // All Users Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.people_outline,
                    size: 22,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Show All Users",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    elevation: 3,
                    shadowColor: Colors.lightBlue,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllUsersScreen(meUid: userId),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Friends Section with Search Bar
              const Text(
                "Your Friends",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search friends by name or email...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Friends List Widget (with search)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FriendsListWidget(
                    userId: userId,
                    searchQuery: _searchQuery, // pass the search query here
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ Dialogs ------------------
  void _showIncomingOneToOneDialog(String callerUid, String roomId) {
    final peerName = callerUid;
    CallDialogs.showIncomingOneToOneDialog(
      context: context,
      callerUid: callerUid,
      roomId: roomId,
      peerName: peerName,
    );
  }
  void _showIncomingGroupDialog(String callerUid, String roomId) {
    CallDialogs.showIncomingGroupDialog(
      context: context,
      callerUid: callerUid,
      roomId: roomId,
      selfUid: userId,      // updated
      peerRoomIds: {},      // will be filled dynamically when call starts
      memberUids: [],       // will be filled dynamically when call starts
    );
  }

  // ------------------ Group Call Dialog ------------------
  Future<void> _openCreateGroupDialog(BuildContext ctx) async {
    await CallDialogs.showCreateGroupCallDialog(
      context: ctx,
      selfUid: userId,     // updated
    );
  }

}
