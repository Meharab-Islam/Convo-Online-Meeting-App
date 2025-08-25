// ignore_for_file: unused_element

import 'dart:async';

import 'package:calling/call_locig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';


class CallScreen extends StatefulWidget {
  final String roomId;
  final bool isCaller;

  const CallScreen({super.key, required this.roomId, required this.isCaller});

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

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _startCall();
    _startTimer();
  }
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _startCall() async {
    _logic.onRemoteStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };

    _logic.onCallEnded = () {
      Navigator.pop(context);
    };

    try {
      await _logic.initCall(widget.roomId, widget.isCaller);
      _localRenderer.srcObject = _logic.localStream;
    } catch (e) {
      debugPrint("Error starting call: $e");
    }
  }

  void _toggleMic() {
    setState(() {
      _logic.toggleMic();
    });
  }

  void _toggleVideo() {
    setState(() {
      _logic.toggleVideo();
    });
  }

  void _switchCamera() {
    if (_logic.localStream != null) {
      final videoTrack = _logic.localStream!
          .getVideoTracks()
          .firstWhere((track) => track.kind == 'video');
      videoTrack.switchCamera();
    }
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

  Widget _buildLocalVideo() {
    return Positioned(
      left: _localVideoOffset.dx,
      top: _localVideoOffset.dy,
      width: 120,
      height: 160,
      child: _localRenderer.srcObject != null
          ? Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: RTCVideoView(_localRenderer, mirror: true),
            )
          : Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video
            Positioned.fill(
              child: _remoteRenderer.srcObject != null
                  ? RTCVideoView(_remoteRenderer)
                  : const Center(child: Text("Waiting for remote video...", style: TextStyle(color: Colors.white))),
            ),

            // Draggable local video
            Positioned(
              left: _localVideoOffset.dx,
              top: _localVideoOffset.dy,
              width: 120,
              height: 160,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final screenHeight = MediaQuery.of(context).size.height - 100;
                    double x = (_localVideoOffset.dx + details.delta.dx).clamp(0.0, screenWidth - 120);
                    double y = (_localVideoOffset.dy + details.delta.dy).clamp(0.0, screenHeight - 160);
                    _localVideoOffset = Offset(x, y);
                  });
                },
                onPanEnd: (_) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height - 100;
                  double x = (_localVideoOffset.dx + 60 < screenWidth / 2) ? 20 : screenWidth - 140;
                  double y = (_localVideoOffset.dy + 80 < screenHeight / 2) ? 20 : screenHeight - 180;
                  setState(() {
                    _localVideoOffset = Offset(x, y);
                  });
                },
                child: _localRenderer.srcObject != null
                    ? Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RTCVideoView(_localRenderer, mirror: true),
                      )
                    : Container(),
              ),
            ),

            // Room code at top center
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Room: ${widget.roomId}",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            // Timer at top right
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(_secondsElapsed),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.black54,
          padding: const EdgeInsets.symmetric(vertical: 8),
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
      ),
    );


  }
}
