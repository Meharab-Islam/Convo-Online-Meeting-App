import 'package:flutter/material.dart';
import 'package:calling/call_screen.dart';
import 'package:calling/services/call_invite_service.dart';

class IncomingCallWidget extends StatelessWidget {
  final String callerId;
  final String roomId;
  final String callerName; // Optional: show caller name

  const IncomingCallWidget({
    super.key,
    required this.callerId,
    required this.roomId,
    this.callerName = "",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Incoming Call"),
      content: Text(
          "User ${callerName.isNotEmpty ? callerName : callerId} is calling you"),
      actions: [
        TextButton(
          onPressed: () async {
            // Reject call
            await CallInviteService().updateCallStatus(roomId, 'ended');
            Navigator.pop(context);
          },
          child: const Text("Reject"),
        ),
        TextButton(
          onPressed: () async {
            // Accept call
            await CallInviteService().updateCallStatus(roomId, 'accepted');
            Navigator.pop(context); // Close the dialog first
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  roomId: roomId,
                  isCaller: false,
                  peerName: callerName.isNotEmpty ? callerName : callerId,
                ),
              ),
            );
          },
          child: const Text("Accept"),
        ),
      ],
    );
  }
}
