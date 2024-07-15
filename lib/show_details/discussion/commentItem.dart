import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  late ValueNotifier<bool> _isLikedNotifier;
  late ValueNotifier<int> totalLikes = ValueNotifier<int>(0);
  late DateTime pageLoadTime;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUser();
    _isLikedNotifier = ValueNotifier<bool>(false);
    _initializeLikes();
    pageLoadTime = DateTime.now();
  }

  @override
  void dispose() {
    _isLikedNotifier.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot> _fetchUser() {
    final userID = widget.comment['userID'];
    return FirebaseFirestore.instance.collection('users').doc(userID).get();
  }

  void _initializeLikes() {
    final likes = widget.comment['likes'] as List<dynamic>?;
    if (likes != null) {
      _isLikedNotifier.value = likes.contains(FirebaseAuth.instance.currentUser!.uid);
      totalLikes.value = likes.length;
    }
  }

  void _toggleLike() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isLiked = _isLikedNotifier.value;
      _isLikedNotifier.value = !isLiked;
      totalLikes.value += isLiked ? -1 : 1;
      if (isLiked) {
        widget.comment.reference.update({'likes': FieldValue.arrayRemove([user.uid])});
      } else {
        widget.comment.reference.update({'likes': FieldValue.arrayUnion([user.uid])});
      }
    }
  }

  Future<String?> getImageUrl() async {
    try {
      if (widget.comment['deleted'] == true) {
        return  'https://avatar.iran.liara.run/username?username=not+found' ;
      }
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
              if (!snapshot.hasData) {
                return const SizedBox(); // Handle loading state if needed
              }
              String userName = 'User not found';
              if (widget.comment['deleted'] == false) {
               final userData = snapshot.data!.data() as Map<String, dynamic>;
              userName = userData['username'].toString();
              } 
              

              return Row(
                children: [
                  FutureBuilder<String?>(
                    future: getImageUrl(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(); // Handle loading state if needed
                      }

                      return CircleAvatar(
                        radius: 15,
                        backgroundImage: CachedNetworkImageProvider(snapshot.data!),
                      );
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
                  const SizedBox(width: 8),
                  Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _getRatingColor(widget.comment['rating'].toDouble()),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              child: Text(
                                widget.comment['rating'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          _buildCommentText(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _isLikedNotifier,
                    builder: (context, isLiked, _) {
                      return IconButton(
                        icon: isLiked ? Icon(Icons.favorite, color: widget.color) : const Icon(Icons.favorite_border),
                        iconSize: 16,
                        onPressed: _toggleLike,
                      );
                    },
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: totalLikes,
                    builder: (context, likes, _) {
                      return Text(likes.toString());
                    },
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.reply),
                iconSize: 16,
                onPressed: () {
                  widget.onReply(widget.comment.reference); // Pass the DocumentReference
                },
              ),
               if (FirebaseAuth.instance.currentUser!.uid == widget.comment['userID'])
             PopupMenuButton(
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(0)),
                      ),
                      icon: const Icon(Icons.more_horiz),
                      itemBuilder: (context) => [
                       
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text("Edit"),
                            onTap: () {
                              Navigator.pop(context);
                              
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text("Delete"),
                            onTap: () {
                              _deleteComment();
                              Navigator.pop(context);
                              // Handle delete action
                            },
                          ),
                        ),
                      ],
                    ), 
            ],
          ),
          _buildRepliesWidget(),
        ],
      ),
    );
  }

  Widget _buildCommentText() {
    if (widget.comment['deleted'] != true) {
      final commentText = widget.comment['text'] ?? '';
      return Text(
        commentText,
        style: const TextStyle(fontSize: 14),
      );
    } 
      return const Text(
        '[Comment removed]',
        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
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

  void _deleteComment() async {
  
    try {
      // Mark the comment as deleted
      await widget.comment.reference.update({'deleted': true, 'text': ''});

      // Delete related data or handle as needed
      // For example, remove from user's ratings if applicable:
      final userId = widget.comment['userID'];
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final id = widget.movieID ?? widget.tvShowId;
      await userRef.update({
        'ratings.$id': FieldValue.delete(),
      });

     
    } catch (error) {
      print('Failed to delete comment: $error');
      // Handle error scenario, e.g., show error message
    }
  }
    Color _getRatingColor(double rating) {
    if (rating >= 10.0) {
      return Colors.green.shade900;
    } else if (rating >= 7.0) {
      return const Color.fromARGB(255, 9, 151, 14);
    } else if (rating >= 5.0) {
      return Colors.yellow.shade600;
    } else if (rating >= 3.0) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade900;
    }
  }
}
