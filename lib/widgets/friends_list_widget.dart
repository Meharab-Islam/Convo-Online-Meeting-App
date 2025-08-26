import 'package:calling/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/call_invite_service.dart';

class FriendsListWidget extends StatelessWidget {
  final String userId;
  final String searchQuery;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  FriendsListWidget({super.key, required this.userId, this.searchQuery = ""});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final friends = List<String>.from(data['friends'] ?? []);

        if (friends.isEmpty) return const Center(child: Text("No friends yet"));

        // Filter friends by search query
        final filteredFriends = <String>[];
        for (var friendId in friends) {
          filteredFriends.add(friendId);
        }

        if (filteredFriends.isEmpty) return const Center(child: Text("No friends match your search"));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredFriends.length,
          itemBuilder: (context, index) {
            final friendId = filteredFriends[index];

            return FutureBuilder<DocumentSnapshot>(
              future: firestore.collection('users').doc(friendId).get(),
              builder: (context, friendSnapshot) {
                if (!friendSnapshot.hasData) return const SizedBox();

                final friendData = friendSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                final firstName = friendData['firstName'] ?? '';
                final lastName = friendData['lastName'] ?? '';
                final email = friendData['email'] ?? '';
                final initials =
                    "${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}";
                final fullName = "$firstName $lastName".trim();

                // Skip if search query does not match
                if (searchQuery.isNotEmpty &&
                    !fullName.toLowerCase().contains(searchQuery) &&
                    !email.toLowerCase().contains(searchQuery)) {
                  return const SizedBox.shrink();
                }

                return Card(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.blue.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.blue[700],
                      child: Text(
                        initials.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      fullName.isNotEmpty ? fullName : friendId,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      email.isNotEmpty ? email : "No email",
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.video_call, color: Colors.blue),
                      onPressed: () async {
                        final roomId = await CallInviteService().createOneToOneInvite(
                          callerUid: userId,
                          calleeUid: friendId,
                          video: true,
                        );
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              roomId: roomId,
                              isCaller: true,
                              peerName: fullName.isNotEmpty ? fullName : friendId,
                            ),
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
}
