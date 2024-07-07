import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {

  static Future<List<UserProfile>> searchUsersByUsername(String query) async {
    final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

    try {
      final snapshot = await _usersCollection.where('username', isGreaterThanOrEqualTo: query).get();
      return snapshot.docs.map((doc) => UserProfile.fromSnapshot(doc)).toList();
    } catch (e) {
      print('Error searching users by username: $e');
      return [];
    }
  }

  static Future<List<UserProfile>> searchUsersByDisplayName(String query) async {
      final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

    try {
      final snapshot = await _usersCollection.where('displayName', isGreaterThanOrEqualTo:  query).get();
   
      return snapshot.docs.map((doc) => UserProfile.fromSnapshot(doc)).toList();
    } catch (e) {
      print('Error searching users by display name: $e');
      return [];
    }
  }
}
class UserProfile {
  final String userID;
  final String username;
  final String displayName;
  final String? profileImageUrl;

  UserProfile({
    required this.userID,
    required this.username,
    required this.displayName,
    this.profileImageUrl,
  });

  factory UserProfile.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;


    return UserProfile(
      userID: doc.id,
      username: data?['username'] ?? '',
      displayName: data?['displayName'] ?? '',
      profileImageUrl: doc.id,
    );
  }
}

