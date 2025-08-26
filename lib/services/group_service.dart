import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';


class GroupService {
final _db = FirebaseFirestore.instance;
final _uuid = const Uuid();


Future<String> createGroup({required String ownerUid, required String name, required List<String> memberUids}) async {
final groupId = _uuid.v4();
final doc = _db.collection('groups').doc(groupId);
await doc.set({
'name': name,
'ownerId': ownerUid,
'members': memberUids.toSet().toList(),
'createdAt': FieldValue.serverTimestamp(),
});
return groupId;
}


Future<void> addMember(String groupId, String uid) async {
final ref = _db.collection('groups').doc(groupId);
await ref.update({
'members': FieldValue.arrayUnion([uid])
});
}


Future<void> removeMember(String groupId, String uid) async {
final ref = _db.collection('groups').doc(groupId);
await ref.update({
'members': FieldValue.arrayRemove([uid])
});
}
}