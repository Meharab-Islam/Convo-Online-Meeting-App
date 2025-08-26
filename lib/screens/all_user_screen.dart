import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/friend_service.dart';
import '../../widgets/initials_avatar.dart';

class AllUsersScreen extends StatefulWidget {
  final String meUid;
  const AllUsersScreen({super.key, required this.meUid});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  final Map<String, bool> _loadingMap = {};
  String _searchQuery = "";
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("All Users"),
  
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _searchQuery = ""; // clear query when closing search
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Expandable search bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearching ? 60 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _isSearching
                ? TextField(
                    decoration: InputDecoration(
                      hintText: "Search users...",
                      hintStyle: TextStyle(color: Colors.blueGrey[200]),
                      prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  )
                : null,
          ),

          // Users list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: usersRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final allUsers = snapshot.data!.docs
                    .where((doc) {
                      final data = doc.data();
                      final fullName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".toLowerCase();
                      final email = (data['email'] ?? '').toLowerCase();
                      return doc.id != widget.meUid &&
                          (_searchQuery.isEmpty || fullName.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase()));
                    })
                    .toList();

                if (allUsers.isEmpty) {
                  return const Center(
                    child: Text(
                      "No users found",
                      style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: allUsers.length,
                  itemBuilder: (context, index) {
                    final userDoc = allUsers[index];
                    final userData = userDoc.data();
                    final userId = userDoc.id;
                    final firstName = userData['firstName'] ?? '';
                    final lastName = userData['lastName'] ?? '';
                    final initials =
                        "${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}";

                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: usersRef.doc(widget.meUid).get(),
                      builder: (context, meSnap) {
                        if (!meSnap.hasData) return const SizedBox.shrink();

                        final meData = meSnap.data!.data()!;
                        final friends = List<String>.from(meData['friends'] ?? []);
                        final outgoing = List<String>.from(meData['outgoingRequests'] ?? []);

                        final isFriend = friends.contains(userId);
                        final requestSent = outgoing.contains(userId);
                        final isLoading = _loadingMap[userId] ?? false;

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shadowColor: Colors.blueAccent.withOpacity(0.3),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            leading: InitialsAvatar(
                              initials: initials.toUpperCase(),
                              radius: 28,
                           
                            ),
                            title: Text(
                              "$firstName $lastName",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            subtitle: Text(
                              userData['email'] ?? '',
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                            trailing: Builder(
  builder: (context) {
    if (isFriend) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          "Friend",
          style: TextStyle(color: Colors.black),
        ),
      );
    } else if (isLoading) {
      return const SizedBox(
        width: 100,
        height: 36,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      );
    } else if (requestSent) {
      return SizedBox(
        width: 100,
        child: ElevatedButton(
          onPressed: () async {
            setState(() => _loadingMap[userId] = true);
            await FriendService().cancelRequest(
                meUid: widget.meUid, friendUid: userId);
            setState(() => _loadingMap[userId] = false);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: 100,
        child: ElevatedButton(
          onPressed: () async {
            setState(() => _loadingMap[userId] = true);
            await FriendService().sendRequest(
                fromUid: widget.meUid, toUid: userId);
            setState(() => _loadingMap[userId] = false);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Add Friend",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  },
),

                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
