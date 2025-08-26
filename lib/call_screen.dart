import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:calling/call_locig.dart';

class CallScreen extends StatefulWidget {
  final String roomId;
  final bool isCaller;
  final String peerName;

  const CallScreen({
    super.key,
    required this.roomId,
    required this.isCaller,
    required this.peerName,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final CallLogic _logic = CallLogic();

  Offset _localVideoOffset = const Offset(20, 20);
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _remoteVideoEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _startCall();
    _startTimer();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  Future<void> _startCall() async {
    // Remote stream callback
    _logic.onRemoteStream = (stream, peerId) {
      setState(() {
        _remoteRenderer.srcObject = stream;
        _remoteVideoEnabled = stream.getVideoTracks().isNotEmpty &&
            stream.getVideoTracks().first.enabled;
      });
    };

    // Remote video toggle callback
    _logic.onRemoteVideoToggle = (enabled, peerId) {
      setState(() {
        _remoteVideoEnabled = enabled;
      });
    };

    // Call ended
    _logic.onCallEnded = () {
      setState(() {
        _remoteRenderer.srcObject = null; // show avatar
      });
      Navigator.pop(context);
    };

    try {
      await _logic.initCall(roomId: widget.roomId, isCaller: widget.isCaller);
      _localRenderer.srcObject = _logic.localStream;
    } catch (e) {
      debugPrint("Error starting call: $e");
    }
  }

  void _toggleMic() => _logic.toggleMic();
  void _toggleVideo() => _logic.toggleVideo();
  void _switchCamera() {
    final videoTrack = _logic.localStream!
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    // ignore: deprecated_member_use
    videoTrack.switchCamera();
  }

  void _endCall() {
    _logic.endCall();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _timer?.cancel();
    _logic.dispose();
    super.dispose();
  }

  // --- Avatar Widget ---
  Widget _buildAvatar(String name) {
    final initials = name.isNotEmpty
        ? name.trim().split(" ").map((e) => e[0]).take(2).join()
        : "?";
    return Container(
      color: Colors.grey[700],
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- Local Video (draggable) ---
  Widget _buildLocalVideo() {
    return Positioned(
      left: _localVideoOffset.dx,
      top: _localVideoOffset.dy,
      width: 120,
      height: 160,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height - 100;
            double x = (_localVideoOffset.dx + details.delta.dx)
                .clamp(0.0, screenWidth - 120);
            double y = (_localVideoOffset.dy + details.delta.dy)
                .clamp(0.0, screenHeight - 160);
            _localVideoOffset = Offset(x, y);
          });
        },
        child: _logic.localStream != null
            ? Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RTCVideoView(_localRenderer, mirror: true),
              )
            : _buildAvatar("You"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video / avatar
            Positioned.fill(
              child: _remoteVideoEnabled && _remoteRenderer.srcObject != null
                  ? RTCVideoView(_remoteRenderer)
                  : _buildAvatar(widget.peerName),
            ),

            // Local video
            _buildLocalVideo(),

            // Room info
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Room: ${widget.roomId}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

            // Timer
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$minutes:$seconds",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom controls
      bottomNavigationBar: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              heroTag: "mic",
              onPressed: _toggleMic,
              backgroundColor: Colors.black54,
              child: Icon(_logic.micEnabled ? Icons.mic : Icons.mic_off),
            ),
            FloatingActionButton(
              heroTag: "video",
              onPressed: _toggleVideo,
              backgroundColor: Colors.black54,
              child: Icon(_logic.videoEnabled ? Icons.videocam : Icons.videocam_off),
            ),
            FloatingActionButton(
              heroTag: "switch",
              onPressed: _switchCamera,
              backgroundColor: Colors.black54,
              child: const Icon(Icons.cameraswitch),
            ),
            FloatingActionButton(
              heroTag: "end",
              onPressed: _endCall,
              backgroundColor: Colors.red,
              child: const Icon(Icons.call_end),
            ),
          ],
        ),
      ),
    );
  }
}
