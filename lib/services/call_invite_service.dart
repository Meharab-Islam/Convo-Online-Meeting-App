import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CallInviteService {
  final _db = FirebaseFirestore.instance;

  /// ------------------ ONE-TO-ONE CALL ------------------
  Future<String> createOneToOneInvite({
    required String callerUid,
    required String calleeUid,
    required bool video,
  }) async {
    final roomId = const Uuid().v4();
    final callRef = _db.collection('calls').doc(roomId);

    await callRef.set({
      "callerUid": callerUid,
      "calleeUid": calleeUid,
      "roomId": roomId,
      "type": video ? "video" : "audio",
      "status": "ringing",
      "createdAt": FieldValue.serverTimestamp(),
    });

    // Update call lists
    await _db.collection('users').doc(callerUid).update({
      "outgoingCalls": FieldValue.arrayUnion([roomId]),
    });
    await _db.collection('users').doc(calleeUid).update({
      "incomingCalls": FieldValue.arrayUnion([roomId]),
    });

    return roomId;
  }

  Future<void> updateCallStatus(String roomId, String status) async {
    final callRef = _db.collection('calls').doc(roomId);
    final docSnapshot = await callRef.get();
    if (!docSnapshot.exists) return;

    final data = docSnapshot.data()!;
    final callerUid = data['callerUid'] as String?;
    final calleeUid = data['calleeUid'] as String?;

    if (callerUid == null || calleeUid == null) return;

    await callRef.update({"status": status});

    if (status == 'rejected' || status == 'ended') {
      await callRef.update({"callEndedFor": [callerUid, calleeUid]});
      await Future.delayed(const Duration(seconds: 1));
      await callRef.delete();
    }
  }

  /// ------------------ GROUP CALL ------------------
  Future<String> createGroupInvite({
    required String callerUid,
    required List<String> memberUids,
    required bool video,
  }) async {
    if (memberUids.isEmpty) throw Exception("Member list cannot be empty");

    final masterRoomId = const Uuid().v4();
    final callRef = _db.collection('groupCalls').doc(masterRoomId);

    // Build participants map
    final Map<String, Map<String, dynamic>> participants = {
      for (var uid in memberUids)
        uid: {
          "status": uid == callerUid ? "accepted" : "ringing",
          "joinedAt": uid == callerUid ? FieldValue.serverTimestamp() : null,
        }
    };

    await callRef.set({
      "callerUid": callerUid,
      "roomId": masterRoomId,
      "type": video ? "video" : "audio",
      "participants": participants,
      "status": "ringing",
      "createdAt": FieldValue.serverTimestamp(),
    });

    // Update users
    await _db.collection('users').doc(callerUid).update({
      "outgoingCalls": FieldValue.arrayUnion([masterRoomId]),
    });

    for (var uid in memberUids) {
      if (uid == callerUid) continue;
      await _db.collection('users').doc(uid).update({
        "incomingCalls": FieldValue.arrayUnion([masterRoomId]),
      });
    }

    return masterRoomId;
  }

  /// Update a participant status in group call
  Future<void> updateGroupCallStatus({
    required String roomId,
    required String participantUid,
    required String status, // accepted, declined, ended
  }) async {
    final callRef = _db.collection('groupCalls').doc(roomId);

    // Update participant status
    final updates = <String, dynamic>{
      "participants.$participantUid.status": status,
    };
    if (status == "accepted") {
      updates["participants.$participantUid.joinedAt"] =
          FieldValue.serverTimestamp();
    }
    await callRef.update(updates);

    // Check if all participants left or declined
    if (status == "declined" || status == "ended") {
      final snapshot = await callRef.get();
      final participants =
          snapshot.data()?['participants'] as Map<String, dynamic>? ?? {};
      final activeParticipants = participants.values
          .where((p) => p['status'] == 'accepted' || p['status'] == 'ringing')
          .toList();

      if (activeParticipants.isEmpty) {
        await endGroupCall(roomId);
      }
    }
  }

  /// End the group call for everyone
  Future<void> endGroupCall(String roomId) async {
    final callRef = _db.collection('groupCalls').doc(roomId);
    await callRef.update({
      "status": "ended",
      "endedAt": FieldValue.serverTimestamp(),
    });

    // Delay then delete
    await Future.delayed(const Duration(seconds: 2));
    await callRef.delete();
  }
}
