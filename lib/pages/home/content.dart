import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class content extends StatefulWidget {
  final int? movieID;
  final int? tvShowId;
  final String commentID;

  const content({
    Key? key,
    this.movieID,
    this.tvShowId,
    required this.commentID,
  }) : super(key: key);

  @override
  _contentState createState() => _contentState();
}

class _contentState extends State<content> {
  late Future<DocumentSnapshot> _commentFuture;
  late Future<DocumentSnapshot> _userFuture;
  late DateTime pageLoadTime; // Time when the page was loaded

  @override
  void initState() {
    super.initState();
    _commentFuture = _fetchComment();
    _userFuture = _fetchUser();
    pageLoadTime = DateTime.now(); // Record the time when the page was loaded
  }

  Future<DocumentSnapshot> _fetchComment() {
    final collectionName = widget.movieID != null ? 'movies' : 'tv_shows';
    final documentID = widget.movieID != null ? widget.movieID.toString() : widget.tvShowId.toString();
    return FirebaseFirestore.instance
        .collection(collectionName)
        .doc(documentID)
        .collection('comments')
        .doc(widget.commentID)
        .get();
  }

  Future<DocumentSnapshot> _fetchUser() async {
    final commentSnapshot = await _commentFuture;
    final userID = commentSnapshot['userID'];
    return FirebaseFirestore.instance.collection('users').doc(userID).get();
  }

  Future<String?> getImageUrl() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile/${widget.commentID}.jpg'); // Example path, adjust as needed
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting image URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.0),
      child: FutureBuilder<DocumentSnapshot>(
        future: _commentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTile(
              title: Text('Loading...'),
              subtitle: Text('...'),
            );
          }
          if (snapshot.hasError) {
            return ListTile(
              title: Text('Error: ${snapshot.error}'),
              subtitle: const Text('Failed to load comment'),
            );
          }

          final commentData = snapshot.data!.data() as Map<String, dynamic>;
          final commentText = commentData['text'].toString();
          final commentTimestamp = commentData['dateCreated'] as Timestamp;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: _userFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                      subtitle: Text('...'),
                    );
                  }
                  if (snapshot.hasError) {
                    return ListTile(
                      title: Text('Error: ${snapshot.error}'),
                      subtitle: const Text('Failed to load user data'),
                    );
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final userName = userData['username'].toString();

                  return Row(
                    children: [
                      FutureBuilder<String?>(
                        future: getImageUrl(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return const Center(child: Text('Error loading image'));
                          } else if (snapshot.hasData) {
                            return CircleAvatar(
                              radius: 15,
                              backgroundImage: CachedNetworkImageProvider(snapshot.data!),
                            );
                          } else {
                            return const CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.grey, // Placeholder color
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(commentTimestamp),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                commentText,
                style: const TextStyle(fontSize: 14),
              ),
              // Additional UI elements and logic can be added here based on your requirements
            ],
          );
        },
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    // Calculate elapsed time from pageLoadTime to comment's timestamp
    DateTime commentTime = timestamp.toDate();
    Duration difference = pageLoadTime.difference(commentTime);

    // Format elapsed time
    if (difference.inDays > 0) {
      return DateFormat.yMMMd().format(commentTime); // Format: Jan 1, 2023
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h '; // Format: 5h ago
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m '; // Format: 10m ago
    } else {
      return 'Just now';
    }
  }
}
