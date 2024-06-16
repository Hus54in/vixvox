import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class CommentItem extends StatefulWidget {
  final DocumentSnapshot comment;
  final int? movieID;
  final int? tvShowId;
  final Function(DocumentReference) onReply;
  final Color color;

  const CommentItem({
    required this.comment,
     this.movieID,
     this.tvShowId,
    required this.onReply,
    required this.color,
  });

  @override
  _CommentItemState createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  late Future<DocumentSnapshot> _userFuture;
  bool isLiked = false;
  int totalLikes = 0;
  late DateTime pageLoadTime; // Time when the page was loaded

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUser();
    _initializeLikes();
    pageLoadTime = DateTime.now(); // Record the time when the page was loaded
  }

  Future<DocumentSnapshot> _fetchUser() {
    final userID = widget.comment['userID'];
    return FirebaseFirestore.instance.collection('users').doc(userID).get();
  }

  void _initializeLikes() {
    final likes = widget.comment['likes'] as List<dynamic>?;
    if (likes != null) {
      setState(() {
        totalLikes = likes.length;
        isLiked = likes.contains(FirebaseAuth.instance.currentUser!.uid);
      });
    }
  }

  Future<String?> getImageUrl() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile/${widget.comment['userID']}.jpg');
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
      child: Column(
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
                  subtitle: Text(widget.comment['text']),
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
                        return CircleAvatar(
                          radius: 15,
                          backgroundImage: CachedNetworkImageProvider(
                              'https://avatar.iran.liara.run/username?username=${widget.comment['userID']}'),
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
                    _formatTime(widget.comment['dateCreated']),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            widget.comment['text'],
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: isLiked ? Icon(Icons.favorite, color: widget.color) : const Icon(Icons.favorite_border),
                    iconSize: 16,
                    onPressed: () {
                      likeComment(widget.comment.reference, isLiked);
                    },
                  ),
                  Text(totalLikes.toString()),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.reply),
                iconSize: 16,
                onPressed: () {
                  widget.onReply(widget.comment.reference); // Pass the DocumentReference
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                iconSize: 16,
                onPressed: () {
                  // Handle options button press
                },
              ),
            ],
          ),
          _buildRepliesWidget(),
        ],
      ),
    );
  }

  Widget _buildRepliesWidget() {
    final collectionName = widget.movieID != null ? 'movies' : 'tv_shows';
    final commentId = widget.comment.id;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .doc(widget.movieID != null ? widget.movieID.toString() : widget.tvShowId.toString())
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .orderBy('dateCreated', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final replies = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: replies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
              child: CommentItem(
                comment: reply,
                movieID: widget.movieID,
                onReply: widget.onReply,
                color: widget.color,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void likeComment(DocumentReference commentRef, bool isLiked) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (isLiked) {
        commentRef.update({
          'likes': FieldValue.arrayRemove([user.uid]),
        }).then((_) {
          setState(() {
            this.isLiked = false;
            totalLikes -= 1;
          });
        });
      } else {
        commentRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        }).then((_) {
          setState(() {
            this.isLiked = true;
            totalLikes += 1;
          });
        });
      }
    }
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
