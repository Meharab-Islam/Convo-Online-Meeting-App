import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  final _db = FirebaseFirestore.instance;

  /// Send a friend request from [fromUid] to [toUid]
  Future<void> sendRequest({
    required String fromUid,
    required String toUid,
  }) async {
    if (fromUid == toUid) return;

    final toRef = _db.collection('users').doc(toUid);
    final fromRef = _db.collection('users').doc(fromUid);

    await _db.runTransaction((tx) async {
      final toSnap = await tx.get(toRef);
      final fromSnap = await tx.get(fromRef);

      final incoming = List<String>.from(toSnap.data()?['incomingRequests'] ?? []);
      final outgoing = List<String>.from(fromSnap.data()?['outgoingRequests'] ?? []);

      if (!incoming.contains(fromUid)) incoming.add(fromUid);
      if (!outgoing.contains(toUid)) outgoing.add(toUid);

      tx.update(toRef, {'incomingRequests': incoming});
      tx.update(fromRef, {'outgoingRequests': outgoing});
    });
  }

  /// Accept a friend request from [fromUid]
  Future<void> acceptRequest({
    required String meUid,
    required String fromUid,
  }) async {
    final meRef = _db.collection('users').doc(meUid);
    final fromRef = _db.collection('users').doc(fromUid);

    await _db.runTransaction((tx) async {
      final meSnap = await tx.get(meRef);
      final fromSnap = await tx.get(fromRef);

      final meIncoming = List<String>.from(meSnap.data()?['incomingRequests'] ?? []);
      final fromOutgoing = List<String>.from(fromSnap.data()?['outgoingRequests'] ?? []);
      final meFriends = List<String>.from(meSnap.data()?['friends'] ?? []);
      final fromFriends = List<String>.from(fromSnap.data()?['friends'] ?? []);

      meIncoming.remove(fromUid);
      fromOutgoing.remove(meUid);

      if (!meFriends.contains(fromUid)) meFriends.add(fromUid);
      if (!fromFriends.contains(meUid)) fromFriends.add(meUid);

      tx.update(meRef, {
        'incomingRequests': meIncoming,
        'friends': meFriends,
      });

      tx.update(fromRef, {
        'outgoingRequests': fromOutgoing,
        'friends': fromFriends,
      });
    });
  }

  /// Decline a friend request from [fromUid]
  Future<void> declineRequest({
    required String meUid,
    required String fromUid,
  }) async {
    final meRef = _db.collection('users').doc(meUid);
    final fromRef = _db.collection('users').doc(fromUid);

    await _db.runTransaction((tx) async {
      final meSnap = await tx.get(meRef);
      final fromSnap = await tx.get(fromRef);

      final meIncoming = List<String>.from(meSnap.data()?['incomingRequests'] ?? []);
      final fromOutgoing = List<String>.from(fromSnap.data()?['outgoingRequests'] ?? []);

      meIncoming.remove(fromUid);
      fromOutgoing.remove(meUid);

      tx.update(meRef, {'incomingRequests': meIncoming});
      tx.update(fromRef, {'outgoingRequests': fromOutgoing});
    });
  }

  /// Remove a friend from both users
  Future<void> removeFriend({
    required String meUid,
    required String friendUid,
  }) async {
    final meRef = _db.collection('users').doc(meUid);
    final friendRef = _db.collection('users').doc(friendUid);

    await _db.runTransaction((tx) async {
      final meSnap = await tx.get(meRef);
      final friendSnap = await tx.get(friendRef);

      final meFriends = List<String>.from(meSnap.data()?['friends'] ?? []);
      final friendFriends = List<String>.from(friendSnap.data()?['friends'] ?? []);

      meFriends.remove(friendUid);
      friendFriends.remove(meUid);

      tx.update(meRef, {'friends': meFriends});
      tx.update(friendRef, {'friends': friendFriends});
    });
  }

   /// Cancel an outgoing friend request from meUid to friendUid
  Future<void> cancelRequest({
    required String meUid,
    required String friendUid,
  }) async {
    final meRef = _db.collection('users').doc(meUid);
    final friendRef = _db.collection('users').doc(friendUid);

    await _db.runTransaction((tx) async {
      final meSnap = await tx.get(meRef);
      final friendSnap = await tx.get(friendRef);

      final outgoing = List<String>.from(meSnap.data()?['outgoingRequests'] ?? []);
      final incoming = List<String>.from(friendSnap.data()?['incomingRequests'] ?? []);

      outgoing.remove(friendUid);
      incoming.remove(meUid);

      tx.update(meRef, {'outgoingRequests': outgoing});
      tx.update(friendRef, {'incomingRequests': incoming});
    });
  }
}
