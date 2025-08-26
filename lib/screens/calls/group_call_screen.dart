import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../call_locig.dart';

class GroupCallScreen extends StatefulWidget {
  final String roomId;
  final String selfUid;
  final bool isCaller;
  final Map<String, String> peerRoomIds; // uid -> room-specific roomId
  final List<String> memberUids;

  const GroupCallScreen({
    super.key,
    required this.roomId,
    required this.selfUid,
    required this.isCaller,
    required this.peerRoomIds,
    required this.memberUids,
  });

  @override
  State<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends State<GroupCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final CallLogic _logic = CallLogic();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  Offset _localOffset = const Offset(20, 20);
  bool _localVideoEnabled = true;
  bool _localMicEnabled = true;
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initCallForAllPeers();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  Future<void> _initCallForAllPeers() async {
    await _localRenderer.initialize();

    for (final uid in widget.memberUids) {
      final peerRoomId = widget.peerRoomIds[uid] ?? widget.roomId;
      final peerLogic = CallLogic();

      // Initialize local stream only once
      if (uid == widget.selfUid) {
        _localRenderer.srcObject = _logic.localStream;
      }

      peerLogic.onRemoteStream = (stream, peerId) async {
        if (!_remoteRenderers.containsKey(peerId)) {
          final renderer = RTCVideoRenderer();
          await renderer.initialize();
          _remoteRenderers[peerId] = renderer;
        }
        _remoteRenderers[peerId]!.srcObject = stream;
        if (mounted) setState(() {});
      };

      peerLogic.onCallEnded = () {
        if (_remoteRenderers.containsKey(uid)) {
          _remoteRenderers[uid]!.dispose();
          _remoteRenderers.remove(uid);
          if (mounted) setState(() {});
        }
      };

      await peerLogic.initCall(roomId: peerRoomId, isCaller: widget.isCaller, peerId: uid);

      if (uid == widget.selfUid) {
        _logic.localStream = peerLogic.localStream;
        _localRenderer.srcObject = _logic.localStream;
      }
    }

    if (mounted) setState(() {});
  }

  void _toggleMic() {
    _logic.toggleMic();
    setState(() => _localMicEnabled = _logic.micEnabled);
  }

  void _toggleVideo() {
    _logic.toggleVideo();
    setState(() => _localVideoEnabled = _logic.videoEnabled);
  }

  void _endCall() {
    _logic.endCall();
    for (final renderer in _remoteRenderers.values) {
      renderer.dispose();
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    for (final r in _remoteRenderers.values) r.dispose();
    _logic.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildLocalVideo() {
    return Positioned(
      left: _localOffset.dx,
      top: _localOffset.dy,
      width: 120,
      height: 160,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final width = MediaQuery.of(context).size.width;
            final height = MediaQuery.of(context).size.height - 100;
            _localOffset = Offset(
              (_localOffset.dx + details.delta.dx).clamp(0.0, width - 120),
              (_localOffset.dy + details.delta.dy).clamp(0.0, height - 160),
            );
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: RTCVideoView(_localRenderer, mirror: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remoteWidgets = _remoteRenderers.entries.map((e) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.white12)),
        child: RTCVideoView(e.value),
      );
    }).toList();

    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GridView.count(
            crossAxisCount: 2,
            children: [Container(child: RTCVideoView(_localRenderer))] + remoteWidgets,
          ),
          _buildLocalVideo(),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                "$minutes:$seconds",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              children: [
                FloatingActionButton(
                  heroTag: "mic",
                  onPressed: _toggleMic,
                  child: Icon(_localMicEnabled ? Icons.mic : Icons.mic_off),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  heroTag: "video",
                  onPressed: _toggleVideo,
                  child: Icon(_localVideoEnabled ? Icons.videocam : Icons.videocam_off),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  heroTag: "end",
                  backgroundColor: Colors.red,
                  onPressed: _endCall,
                  child: const Icon(Icons.call_end),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
