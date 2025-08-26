import 'package:calling/call_screen.dart';
import 'package:flutter/material.dart';
import '../services/call_invite_service.dart';
import '../screens/calls/group_call_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CallDialogs {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Incoming one-to-one call dialog
  static void showIncomingOneToOneDialog({
    required BuildContext context,
    required String callerUid,
    required String roomId,
    required String peerName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Incoming Call"),
        content: Text("$callerUid is calling you"),
        actions: [
          TextButton(
            onPressed: () async {
              await CallInviteService().updateCallStatus(roomId, 'rejected');
              await firestore.collection('calls').doc(roomId).delete();
              Navigator.pop(context);
            },
            child: const Text("Reject"),
          ),
          TextButton(
            onPressed: () async {
              await CallInviteService().updateCallStatus(roomId, 'accepted');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    roomId: roomId,
                    isCaller: false,
                    peerName: peerName,
                  ),
                ),
              );
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  /// Incoming group call dialog
  static void showIncomingGroupDialog({
    required BuildContext context,
    required String callerUid,
    required String roomId,
    required String selfUid, // Your own UID
    required Map<String, String> peerRoomIds,
    required List<String> memberUids,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Incoming Group Call"),
        content: Text("$callerUid is inviting you to a group call"),
        actions: [
          TextButton(
            onPressed: () async {
              await CallInviteService().updateGroupCallStatus(
                roomId: roomId,
                participantUid: selfUid,
                status: 'declined',
              );
              Navigator.pop(context);
            },
            child: const Text("Reject"),
          ),
          TextButton(
            onPressed: () async {
              await CallInviteService().updateGroupCallStatus(
                roomId: roomId,
                participantUid: selfUid,
                status: 'accepted',
              );
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupCallScreen(
                    roomId: roomId,
                    peerRoomIds: peerRoomIds,
                    memberUids: memberUids,
                    selfUid: selfUid, // pass your UID
                    isCaller: false,
                  ),
                ),
              );
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  /// Call ended / rejected dialog
  static void showCallEndedDialog(
    BuildContext context, {
    bool rejected = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: Text(rejected ? "Call Rejected" : "Call Ended"),
        content: Text(
          rejected
              ? "The other user rejected the call."
              : "The call has ended.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Group call creation bottom sheet
  static Future<void> showCreateGroupCallDialog({
    required BuildContext context,
    required String selfUid,
  }) async {
    final meSnap = await firestore.collection('users').doc(selfUid).get();
    final friends = List<String>.from(meSnap.data()?['friends'] ?? []);

    if (friends.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("No friends"),
          content: const Text("You don't have friends to start a group with."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    final List<Map<String, String>> friendInfos = [];
    for (final fid in friends) {
      final snap = await firestore.collection('users').doc(fid).get();
      final data = snap.data() ?? {};
      friendInfos.add({
        'uid': fid,
        'name': "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim(),
      });
    }

    final selected = <String>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SizedBox(
                height: 420,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      "Select friends for group call",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: friendInfos.length,
                        itemBuilder: (_, i) {
                          final info = friendInfos[i];
                          final uid = info['uid']!;
                          final name = info['name'] ?? uid;
                          final checked = selected.contains(uid);
                          return CheckboxListTile(
                            value: checked,
                            title: Text(name),
                            onChanged: (v) => setStateSB(() {
                              if (v == true) {
                                selected.add(uid);
                              } else {
                                selected.remove(uid);
                              }
                            }),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: selected.isEmpty
                                  ? null
                                  : () async {
                                      Navigator.pop(context);
                                      await _createAndStartGroup(
                                        context,
                                        selected.toList(),
                                        selfUid,
                                      );
                                    },
                              child: const Text("Start Group Call"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Helper: create & start group call
  static Future<void> _createAndStartGroup(
    BuildContext context,
    List<String> memberUids,
    String selfUid,
  ) async {
    // Include self in members
    if (!memberUids.contains(selfUid)) memberUids.add(selfUid);

    final masterRoomId = await CallInviteService().createGroupInvite(
      callerUid: selfUid,
      memberUids: memberUids,
      video: true,
    );

    if (masterRoomId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create group call.")),
        );
      }
      return;
    }

    final Map<String, String> peerRoomIds = {};
    final ts = DateTime.now().millisecondsSinceEpoch;
    for (final uid in memberUids) {
      peerRoomIds[uid] = "$masterRoomId-$uid-$ts";
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupCallScreen(
          roomId: masterRoomId,
          peerRoomIds: peerRoomIds,
          memberUids: memberUids,
          selfUid: selfUid,
          isCaller: true,
        ),
      ),
    );
  }
}
