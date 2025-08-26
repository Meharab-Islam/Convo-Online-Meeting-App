import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class CallLogic {
  RTCPeerConnection? pc;
  MediaStream? localStream;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Callbacks
  Function(MediaStream stream, String peerId)? onRemoteStream;
  Function(bool enabled, String peerId)? onRemoteVideoToggle;
  Function()? onCallEnded;

  bool micEnabled = true;
  bool videoEnabled = true;

  final Map<String, MediaStream> _remoteStreams = {}; // peerId -> MediaStream

  /// Initialize call (one-to-one or group)
  Future<void> initCall({
    required String roomId,
    required bool isCaller,
    String? peerId, // peerId for one-to-one call
  }) async {
    // Request permissions
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus != PermissionStatus.granted ||
        micStatus != PermissionStatus.granted) {
      throw Exception("Camera or Microphone permission denied");
    }

    final config = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"}
      ]
    };

    pc = await createPeerConnection(config);

    // Local media
    localStream = await navigator.mediaDevices.getUserMedia({
      "video": true,
      "audio": true,
    });

    // Add local tracks
    localStream!.getTracks().forEach((track) => pc?.addTrack(track, localStream!));

    // Handle remote tracks
    pc?.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        final id = peerId ?? event.streams[0].id;
        _remoteStreams[id] = stream;
        onRemoteStream?.call(stream, id);

        final videoEnabled = stream.getVideoTracks().isNotEmpty &&
            stream.getVideoTracks().first.enabled;
        onRemoteVideoToggle?.call(videoEnabled, id);
      }
    };

    // ICE candidates
    final candidatesCol = firestore.collection("calls/$roomId/candidates");
    pc?.onIceCandidate = (candidate) {
      candidatesCol.add(candidate.toMap());
    };

    final callDoc = firestore.collection("calls").doc(roomId);

    if (isCaller) {
      final offer = await pc!.createOffer();
      await pc!.setLocalDescription(offer);
      await callDoc.set({"offer": offer.toMap()});

      callDoc.snapshots().listen((snap) async {
        if (pc == null) return;
        if (snap.exists && snap.data()!.containsKey("answer")) {
          final answer = RTCSessionDescription(
              snap["answer"]["sdp"], snap["answer"]["type"]);
          await pc!.setRemoteDescription(answer);
        }
      });
    } else {
      final doc = await callDoc.get();
      if (!doc.exists || !doc.data()!.containsKey("offer")) return;

      final offer = RTCSessionDescription(doc["offer"]["sdp"], doc["offer"]["type"]);
      await pc!.setRemoteDescription(offer);

      final answer = await pc!.createAnswer();
      await pc!.setLocalDescription(answer);
      await callDoc.update({"answer": answer.toMap()});
    }

    candidatesCol.snapshots().listen((snapshot) {
      if (pc == null) return;
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final data = docChange.doc.data()!;
          final candidate = RTCIceCandidate(
            data["candidate"],
            data["sdpMid"],
            data["sdpMLineIndex"],
          );
          pc?.addCandidate(candidate);
        }
      }
    });
  }

  /// Toggle microphone
  void toggleMic() {
    if (localStream != null) {
      for (var track in localStream!.getAudioTracks()) {
        track.enabled = !track.enabled;
      }
      micEnabled = !micEnabled;
    }
  }

  /// Toggle camera
  void toggleVideo() {
    if (localStream != null) {
      for (var track in localStream!.getVideoTracks()) {
        track.enabled = !track.enabled;
      }
      videoEnabled = !videoEnabled;
    }
  }

  /// End call
  void endCall() {
    pc?.close();
    pc = null;
    localStream?.dispose();
    _remoteStreams.clear();
    onCallEnded?.call();
  }

  void dispose() {
    localStream?.dispose();
    pc?.close();
    pc = null;
    _remoteStreams.clear();
  }

  MediaStream? getRemoteStream(String peerId) => _remoteStreams[peerId];
  bool isRemoteVideoEnabled(String peerId) {
    final stream = _remoteStreams[peerId];
    if (stream == null) return false;
    return stream.getVideoTracks().isNotEmpty &&
        stream.getVideoTracks().first.enabled;
  }

  Function(String peerId)? onPeerLeft;

  // Example: call this when a peer disconnects
  void handlePeerLeft(String peerId) {
    onPeerLeft?.call(peerId);
  }
}
