class AppUser {
final String uid;
final String firstName;
final String lastName;
final String email;
final List<String> friends; // list of userIds
final List<String> incomingRequests; // userIds
final List<String> outgoingRequests; // userIds
final List<String> fcmTokens; // device tokens


AppUser({
required this.uid,
required this.firstName,
required this.lastName,
required this.email,
this.friends = const [],
this.incomingRequests = const [],
this.outgoingRequests = const [],
this.fcmTokens = const [],
});


String get initials =>
(firstName.isNotEmpty ? firstName[0] : '?').toUpperCase() +
(lastName.isNotEmpty ? lastName[0] : '').toUpperCase();


Map<String, dynamic> toMap() => {
'firstName': firstName,
'lastName': lastName,
'email': email,
'friends': friends,
'incomingRequests': incomingRequests,
'outgoingRequests': outgoingRequests,
'fcmTokens': fcmTokens,
};


factory AppUser.fromDoc(String uid, Map<String, dynamic> data) => AppUser(
uid: uid,
firstName: data['firstName'] ?? '',
lastName: data['lastName'] ?? '',
email: data['email'] ?? '',
friends: List<String>.from(data['friends'] ?? const []),
incomingRequests: List<String>.from(data['incomingRequests'] ?? const []),
outgoingRequests: List<String>.from(data['outgoingRequests'] ?? const []),
fcmTokens: List<String>.from(data['fcmTokens'] ?? const []),
);
}
