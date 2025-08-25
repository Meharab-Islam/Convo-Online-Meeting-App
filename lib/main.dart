import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'call_screen.dart'; // Import the UI screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "My Meeting",
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.blueGrey[900],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.transparent,
          hintStyle: const TextStyle(color: Colors.white54),
          labelStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: Colors.white70,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _roomController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            
            children: [
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "Welcome to  Convo",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Room Code Input
              Card(
                color: Colors.white10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _roomController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Enter Room Code",
                      labelStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.meeting_room, color: Colors.white70),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Create Room Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final roomId = _roomController.text.trim();
                  if (roomId.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CallScreen(
                        roomId: roomId,
                        isCaller: true,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Create Room",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // Join Room Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.greenAccent[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final roomId = _roomController.text.trim();
                  if (roomId.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CallScreen(
                        roomId: roomId,
                        isCaller: false,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Join Room",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),

              // Footer
              const Center(
                child: Text(
                  "Powered by Meharab Islam Nibir",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}












































// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'firebase_options.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: HomePage(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final _roomController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("WebRTC Room Example")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: _roomController,
//               decoration: const InputDecoration(
//                 labelText: "Enter Room Code",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 final roomId = _roomController.text.trim();
//                 if (roomId.isEmpty) return;
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => CallScreen(
//                       roomId: roomId,
//                       isCaller: true,
//                     ),
//                   ),
//                 );
//               },
//               child: const Text("Create Room"),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: () {
//                 final roomId = _roomController.text.trim();
//                 if (roomId.isEmpty) return;
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => CallScreen(
//                       roomId: roomId,
//                       isCaller: false,
//                     ),
//                   ),
//                 );
//               },
//               child: const Text("Join Room"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CallScreen extends StatefulWidget {
//   final String roomId;
//   final bool isCaller;

//   const CallScreen({super.key, required this.roomId, required this.isCaller});

//   @override
//   State<CallScreen> createState() => _CallScreenState();
// }

// class _CallScreenState extends State<CallScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final _localRenderer = RTCVideoRenderer();
//   final _remoteRenderer = RTCVideoRenderer();
//   RTCPeerConnection? _pc;
//   MediaStream? _localStream;

//   bool _micEnabled = true;
//   bool _videoEnabled = true;

//   @override
//   void initState() {
//     super.initState();
//     _initRenderers();
//     _startCall();
//   }

//   Future<void> _initRenderers() async {
//     await _localRenderer.initialize();
//     await _remoteRenderer.initialize();
//   }

//   Future<void> _startCall() async {
//     // Request permissions
//     final cameraStatus = await Permission.camera.request();
//     final micStatus = await Permission.microphone.request();

//     if (cameraStatus != PermissionStatus.granted ||
//         micStatus != PermissionStatus.granted) {
//       debugPrint("Camera or Microphone permission denied");
//       return;
//     }

//     try {
//       final config = {
//         "iceServers": [
//           {"urls": "stun:stun.l.google.com:19302"}
//         ]
//       };

//       _pc = await createPeerConnection(config);

//       // Get local media
//       _localStream = await navigator.mediaDevices.getUserMedia({
//         "video": true,
//         "audio": true,
//       });
//       _localRenderer.srcObject = _localStream;

//       // Add local tracks
//       _localStream!.getTracks().forEach((track) {
//         _pc?.addTrack(track, _localStream!);
//       });

//       // Handle remote tracks
//       _pc?.onTrack = (RTCTrackEvent event) {
//         if (event.streams.isNotEmpty) {
//           setState(() {
//             _remoteRenderer.srcObject = event.streams[0];
//           });
//         }
//       };

//       // ICE candidates
//       final candidatesCol =
//           _firestore.collection("calls/${widget.roomId}/candidates");

//       _pc?.onIceCandidate = (candidate) {
//         if (candidate != null) {
//           candidatesCol.add(candidate.toMap());
//         }
//       };

//       final callDoc = _firestore.collection("calls").doc(widget.roomId);

//       if (widget.isCaller) {
//         // Caller: create offer
//         final offer = await _pc!.createOffer();
//         await _pc!.setLocalDescription(offer);
//         await callDoc.set({"offer": offer.toMap()});

//         // Listen for answer
//         callDoc.snapshots().listen((snap) async {
//           if (_pc == null ||
//               _pc!.signalingState == RTCSignalingState.RTCSignalingStateClosed) {
//             return;
//           }
//           if (snap.exists && snap.data()!.containsKey("answer")) {
//             final answer = RTCSessionDescription(
//                 snap["answer"]["sdp"], snap["answer"]["type"]);
//             try {
//               await _pc!.setRemoteDescription(answer);
//             } catch (_) {}
//           }
//         });
//       } else {
//         // Callee: read offer
//         final doc = await callDoc.get();
//         if (!doc.exists || !doc.data()!.containsKey("offer")) return;

//         final offer =
//             RTCSessionDescription(doc["offer"]["sdp"], doc["offer"]["type"]);
//         await _pc!.setRemoteDescription(offer);

//         final answer = await _pc!.createAnswer();
//         await _pc!.setLocalDescription(answer);
//         await callDoc.update({"answer": answer.toMap()});
//       }

//       // Listen for ICE candidates
//       candidatesCol.snapshots().listen((snapshot) {
//         if (_pc == null ||
//             _pc!.signalingState == RTCSignalingState.RTCSignalingStateClosed) {
//           return;
//         }
//         for (var docChange in snapshot.docChanges) {
//           if (docChange.type == DocumentChangeType.added) {
//             final data = docChange.doc.data()!;
//             final candidate = RTCIceCandidate(
//               data["candidate"],
//               data["sdpMid"],
//               data["sdpMLineIndex"],
//             );
//             try {
//               _pc?.addCandidate(candidate);
//             } catch (_) {}
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint("Error starting call: $e");
//     }
//   }

//   void _toggleMic() {
//     if (_localStream != null) {
//       for (var track in _localStream!.getAudioTracks()) {
//         track.enabled = !track.enabled;
//       }
//       setState(() {
//         _micEnabled = !_micEnabled;
//       });
//     }
//   }

//   void _toggleVideo() {
//     if (_localStream != null) {
//       for (var track in _localStream!.getVideoTracks()) {
//         track.enabled = !track.enabled;
//       }
//       setState(() {
//         _videoEnabled = !_videoEnabled;
//       });
//     }
//   }

//   void _endCall() {
//     _pc?.close();
//     _pc = null;
//     Navigator.pop(context);
//   }

//   @override
//   void dispose() {
//     _localRenderer.dispose();
//     _remoteRenderer.dispose();
//     _localStream?.dispose();
//     _pc?.close();
//     _pc = null;
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Room: ${widget.roomId}")),
//       body: Stack(
//         children: [
//           // Remote video full screen
//           Positioned.fill(
//             child: _remoteRenderer.srcObject != null
//                 ? RTCVideoView(_remoteRenderer)
//                 : const Center(child: Text("Waiting for remote video...")),
//           ),
//           // Small local video top-left
//           Positioned(
//             top: 20,
//             left: 20,
//             width: 120,
//             height: 160,
//             child: _localRenderer.srcObject != null
//                 ? Container(
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.white, width: 2),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: RTCVideoView(_localRenderer, mirror: true),
//                   )
//                 : Container(),
//           ),
//           // Bottom control buttons
//           Positioned(
//             bottom: 30,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Mute/unmute
//                 IconButton(
//                   icon: Icon(
//                     _micEnabled ? Icons.mic : Icons.mic_off,
//                     color: Colors.white,
//                     size: 30,
//                   ),
//                   onPressed: _toggleMic,
//                 ),
//                 const SizedBox(width: 20),
//                 // End call
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.red,
//                     shape: BoxShape.circle,
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.call_end, color: Colors.white, size: 30),
//                     onPressed: _endCall,
//                   ),
//                 ),
//                 const SizedBox(width: 20),
//                 // Video on/off
//                 IconButton(
//                   icon: Icon(
//                     _videoEnabled ? Icons.videocam : Icons.videocam_off,
//                     color: Colors.white,
//                     size: 30,
//                   ),
//                   onPressed: _toggleVideo,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
