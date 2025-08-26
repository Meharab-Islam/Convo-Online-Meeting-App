import 'package:calling/services/call_invite_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class CallController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CallInviteService callService = CallInviteService();

  /// Listen to one-to-one calls
  void listenIncomingOneToOneCalls({
    required String userId,
    required BuildContext context,
    required Function(String callerUid, String roomId) onIncoming,
    required Function({bool rejected}) onEnded,
  }) {
    firestore.collection('calls')
      .where('calleeUid', isEqualTo: userId)
      .snapshots()
      .listen((snapshot) {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final roomId = data['roomId'] as String;
          final status = data['status'] as String;
          final callerUid = data['callerUid'] as String;

          if (status == 'ringing') {
            onIncoming(callerUid, roomId);
          } else if (status == 'ended') {
            onEnded(rejected: false);
          } else if (status == 'rejected') {
            onEnded(rejected: true);
          }
        }
      });
  }

  /// Listen to group calls
  void listenIncomingGroupCalls({
    required String userId,
    required BuildContext context,
    required Function(String callerUid, String roomId) onIncoming,
  }) {
    firestore.collection('groupCalls')
      .where('participants.$userId.status', isEqualTo: 'ringing')
      .snapshots()
      .listen((snapshot) {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final roomId = data['roomId'] as String;
          final callerUid = data['callerUid'] as String;
          onIncoming(callerUid, roomId);
        }
      });
  }

  /// Accept a call
  Future<void> acceptCall(String roomId, {bool isGroup = false, String? participantUid}) async {
    if (isGroup) {
      await callService.updateGroupCallStatus(
        roomId: roomId,
        participantUid: participantUid!,
        status: 'accepted',
      );
    } else {
      await callService.updateCallStatus(roomId, 'accepted');
    }
  }

  /// Reject a call
  Future<void> rejectCall(String roomId, {bool isGroup = false, String? participantUid}) async {
    if (isGroup) {
      await callService.updateGroupCallStatus(
        roomId: roomId,
        participantUid: participantUid!,
        status: 'declined',
      );
    } else {
      await callService.updateCallStatus(roomId, 'rejected');
    }
  }
}
