// ignore_for_file: unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class CallLogic {
  RTCPeerConnection? pc;
  MediaStream? localStream;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Callbacks
  Function(MediaStream)? onRemoteStream;
  Function()? onCallEnded;

  bool micEnabled = true;
  bool videoEnabled = true;

  // Initialize media and peer connection
  Future<void> initCall(String roomId, bool isCaller) async {
    // Request permissions
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus != PermissionStatus.granted ||
        micStatus != PermissionStatus.granted) {
      throw Exception("Camera or Microphone permission denied");
    }

    try {
      final config = {
        "iceServers": [
          {"urls": "stun:stun.l.google.com:19302"}
        ]
      };

      pc = await createPeerConnection(config);

      // Get local media
      localStream = await navigator.mediaDevices.getUserMedia({
        "video": true,
        "audio": true,
      });

      // Add local tracks
      localStream!.getTracks().forEach((track) {
        pc?.addTrack(track, localStream!);
      });

      // Handle remote tracks
      pc?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty && onRemoteStream != null) {
          onRemoteStream!(event.streams[0]);
        }
      };

      // ICE candidates
      final candidatesCol =
          firestore.collection("calls/$roomId/candidates");

      pc?.onIceCandidate = (candidate) {
        if (candidate != null) {
          candidatesCol.add(candidate.toMap());
        }
      };

      final callDoc = firestore.collection("calls").doc(roomId);

      if (isCaller) {
        final offer = await pc!.createOffer();
        await pc!.setLocalDescription(offer);
        await callDoc.set({"offer": offer.toMap()});

        callDoc.snapshots().listen((snap) async {
          if (pc == null ||
              pc!.signalingState == RTCSignalingState.RTCSignalingStateClosed) return;
          if (snap.exists && snap.data()!.containsKey("answer")) {
            final answer = RTCSessionDescription(
                snap["answer"]["sdp"], snap["answer"]["type"]);
            try {
              await pc!.setRemoteDescription(answer);
            } catch (_) {}
          }
        });
      } else {
        final doc = await callDoc.get();
        if (!doc.exists || !doc.data()!.containsKey("offer")) return;

        final offer =
            RTCSessionDescription(doc["offer"]["sdp"], doc["offer"]["type"]);
        await pc!.setRemoteDescription(offer);

        final answer = await pc!.createAnswer();
        await pc!.setLocalDescription(answer);
        await callDoc.update({"answer": answer.toMap()});
      }

      // Listen for ICE candidates
      candidatesCol.snapshots().listen((snapshot) {
        if (pc == null ||
            pc!.signalingState == RTCSignalingState.RTCSignalingStateClosed) return;
        for (var docChange in snapshot.docChanges) {
          if (docChange.type == DocumentChangeType.added) {
            final data = docChange.doc.data()!;
            final candidate = RTCIceCandidate(
              data["candidate"],
              data["sdpMid"],
              data["sdpMLineIndex"],
            );
            try {
              pc?.addCandidate(candidate);
            } catch (_) {}
          }
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  // Toggle microphone
  void toggleMic() {
    if (localStream != null) {
      for (var track in localStream!.getAudioTracks()) {
        track.enabled = !track.enabled;
      }
      micEnabled = !micEnabled;
    }
  }

  // Toggle camera
  void toggleVideo() {
    if (localStream != null) {
      for (var track in localStream!.getVideoTracks()) {
        track.enabled = !track.enabled;
      }
      videoEnabled = !videoEnabled;
    }
  }

  // End call
  void endCall() {
    pc?.close();
    pc = null;
    onCallEnded?.call();
  }

  void dispose() {
    localStream?.dispose();
    pc?.close();
    pc = null;
  }
}
