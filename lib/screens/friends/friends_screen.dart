import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/friend_service.dart';
import '../../widgets/initials_avatar.dart';

class FriendsScreen extends StatelessWidget {
  final String meUid;
  const FriendsScreen({super.key, required this.meUid});

  @override
  Widget build(BuildContext context) {
    final users = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 4,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: users.doc(meUid).snapshots(),
        builder: (context, meSnap) {
          if (!meSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final me = meSnap.data!.data()!;
          final incoming = List<String>.from(me['incomingRequests'] ?? []);
          final friends = List<String>.from(me['friends'] ?? []);

          // If no incoming requests and no friends
          if (incoming.isEmpty && friends.isEmpty) {
            return const Center(
              child: Text(
                "You have no friends yet",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (incoming.isNotEmpty) ...[
                const Text(
                  'Incoming Requests',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blueAccent),
                ),
                const SizedBox(height: 12),
                ...incoming.map(
                  (uid) => _UserTile(uid: uid, meUid: meUid, incoming: true),
                ),
                const SizedBox(height: 24),
              ],
              if (friends.isNotEmpty) ...[
                const Text(
                  'Friends',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blueAccent),
                ),
                const SizedBox(height: 12),
                ...friends.map(
                  (uid) => _UserTile(uid: uid, meUid: meUid),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String uid;
  final String meUid;
  final bool incoming;
  const _UserTile({
    required this.uid,
    required this.meUid,
    this.incoming = false,
  });

  @override
  Widget build(BuildContext context) {
    final users = FirebaseFirestore.instance.collection('users');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: users.doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final u = snap.data!.data()!;
        final initials =
            ((u['firstName'] ?? '') as String).characters.firstOrNull
                ?.toUpperCase() ??
            '?${((u['lastName'] ?? '') as String).characters.firstOrNull
                    !.toUpperCase()}';

        return Card(
          color: const Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: InitialsAvatar(initials: initials),
            title: Text(
              '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              u['email'] ?? '',
              style: const TextStyle(color: Colors.black),
            ),
            trailing: incoming
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => FriendService().acceptRequest(
                          meUid: meUid,
                          fromUid: uid,
                        ),
                        icon: const Icon(Icons.check, color: Colors.greenAccent),
                      ),
                      IconButton(
                        onPressed: () => FriendService().declineRequest(
                          meUid: meUid,
                          fromUid: uid,
                        ),
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                      ),
                    ],
                  )
                : IconButton(
                    onPressed: () => FriendService().removeFriend(
                      meUid: meUid,
                      friendUid: uid,
                    ),
                    icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                  ),
          ),
        );
      },
    );
  }
}
