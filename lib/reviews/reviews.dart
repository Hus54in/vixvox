import 'dart:core';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vixvox/reviews/reviewdataloader.dart';
import 'package:vixvox/show_details/movie_details.dart';
import 'package:vixvox/show_details/tvShow_details.dart';

class ReviewWidget extends StatefulWidget {
  final ReviewDataLoader data;
  final Function(String) onDelete;

  const ReviewWidget({Key? key, required this.data, required this.onDelete}) : super(key: key);

  @override
  _ReviewWidgetState createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> with AutomaticKeepAliveClientMixin {
  late ValueNotifier<bool> _isLiked;
  late ValueNotifier<int> _totalLikes;
  bool _isReplying = false;
  final TextEditingController _textController = TextEditingController();
  late ValueNotifier<int> _replyCount; // Track number of replies
  late ValueNotifier<bool> _isEditingNotifier; // Track edit mode
  late ValueNotifier<String> _currentTextNotifier; // Store current text for editing

  @override
  void initState() {
    super.initState();
    _initializeLikes();
    _replyCount = ValueNotifier<int>(0); // Initialize _replyCount with 0
    _fetchReplyCount();
    _currentTextNotifier = ValueNotifier<String>('');
    _isEditingNotifier = ValueNotifier<bool>(false);
  }

  void _toggleReply() {
    setState(() {
      _isReplying = !_isReplying;
    });
  }

  Future<void> _edit() async {
    final reviewData = await widget.data.reviewAndUserDocument;
    final reviewRef = reviewData['review'].reference;
    try {
      await reviewRef.update({
        'text': _textController.text,
      });
      _isEditingNotifier.value = false;
      _currentTextNotifier.value = _textController.text;
    } catch (error) {
      if (kDebugMode) {
        print('Failed to delete reply: $error');
      }
      // Handle error scenario, e.g., show error message
    }
  }

  Future<void> _deleteReply() async {
    final reviewData = await widget.data.reviewAndUserDocument;
    final reviewRef = reviewData['review'].reference;
    final userRef = reviewData['user'].reference;
    final id = widget.data.movieId ?? widget.data.tvshowId;
    try {
      await reviewRef.update({
        'deleted': true,
        'text': '',
      });

      await userRef.update({
        'ratings.$id': FieldValue.delete(),
      });
      widget.onDelete(widget.data.documentId);
    } catch (error) {
      if (kDebugMode) {
        print('Failed to delete reply: $error');
      }
      // Handle error scenario, e.g., show error message
    }
  }

  void likeComment(DocumentReference commentRef, bool isLiked) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (isLiked) {
        commentRef.update({
          'likes': FieldValue.arrayRemove([user.uid]),
        }).then((_) {
          _isLiked.value = false;
          _totalLikes.value -= 1;
        }).catchError((error) {
          if (kDebugMode) {
            print('Failed to unlike comment: $error');
          }
        });
      } else {
        commentRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        }).then((_) {
          _isLiked.value = true;
          _totalLikes.value += 1;
        }).catchError((error) {
          if (kDebugMode) {
            print('Failed to like comment: $error');
          }
        });
      }
    }
  }

  void _initializeLikes() async {
    final data = await widget.data.reviewAndUserDocument;
    final reviewData = data['review'].data() as Map<String, dynamic>;
    final likes = reviewData['likes'] as List<dynamic>? ?? [];
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    _totalLikes = ValueNotifier<int>(likes.length);
    _isLiked = ValueNotifier<bool>(currentUserUid != null && likes.contains(currentUserUid));
  }

  Future<void> _fetchReplyCount() async {
    final repliesSnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.data.documentId)
        .collection('replies')
        .get();

    _replyCount.value = repliesSnapshot.docs.length;
  }

  Future<void> _addReply(String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newReply = {
      'content': content,
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.data.documentId)
        .collection('replies')
        .add(newReply);

    _textController.clear();
    _replyCount.value += 1;
  }

  void _toggleLike() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (_isLiked.value) {
      FirebaseFirestore.instance.collection('reviews').doc(widget.data.documentId).update({
        'likes': FieldValue.arrayRemove([userId]),
      });
      _isLiked.value = false;
      _totalLikes.value -= 1;
    } else {
      FirebaseFirestore.instance.collection('reviews').doc(widget.data.documentId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
      _isLiked.value = true;
      _totalLikes.value += 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return  FutureBuilder<Map<String, dynamic>>(
      future: widget.data.reviewAndUserDocument,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildShimmerCard();
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading review'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No review data found'));
        }

        final reviewData = snapshot.data!['review'].data() as Map<String, dynamic>;
        final userData = snapshot.data!['user'].data() as Map<String, dynamic>;

        final dateCreated = reviewData['dateCreated'] as Timestamp;
        final rating = reviewData['rating'] ;
        _currentTextNotifier.value = reviewData['text'] as String;
        final userId = reviewData['userID'] as String;
        final displayName = userData['displayName'] ?? 'Unknown User';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FutureBuilder<String?>(
                      future: widget.data.getImageUrl(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildShimmerCircle();
                        } else if (snapshot.hasError) {
                          return const Center(child: Text('Error loading image'));
                        } else if (snapshot.hasData) {
                          return CircleAvatar(
                            radius: 14,
                            foregroundImage: CachedNetworkImageProvider(snapshot.data!, scale: 0.5),
                          );
                        } else {
                          return CircleAvatar(
                            radius: 14,
                            foregroundImage: CachedNetworkImageProvider(
                              'https://avatar.iran.liara.run/username?username=$userId',
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              widget.data.timeAgoSinceDate(dateCreated),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (widget.data.movieId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MovieDetailsWidget(
                                        movieID: widget.data.movieId!,
                                        movie: widget.data.getMedia(),
                                      ),
                                    ),
                                  );
                                } else if (widget.data.tvshowId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TvShowDetailsWidget(
                                        tvShowId: widget.data.tvshowId!,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                widget.data.getTMDBTitleWithYear() ?? 'N/A',
                                style: const TextStyle(color: Colors.blue, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _getRatingColor(rating.toDouble()),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              child: Text(
                                rating.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 38),
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _isEditingNotifier,
                        builder: (context, isEditing, child) {
                          return isEditing
                              ? Expanded(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 300.0,
                                    ),
                                    child: TextField(
                                      maxLines: null,
                                      autofocus: false,
                                      controller: _textController,
                                      textCapitalization: TextCapitalization.sentences,
                                      textInputAction: TextInputAction.newline,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(16.0)),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            // Handle button press action, e.g., send message
                                            _edit();
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Text(_currentTextNotifier.value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _isLiked,
                          builder: (context, isLiked, child) {
                            return IconButton(
                              icon: isLiked ? const Icon(Icons.favorite) : const Icon(Icons.favorite_border),
                              iconSize: 16,
                              onPressed: () async {
                                final data = await widget.data.reviewAndUserDocument;
                                final reviewRef = data['review'].reference;
                                likeComment(reviewRef, isLiked);
                              },
                            );
                          },
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: _totalLikes,
                          builder: (context, totalLikes, child) {
                            return Text(totalLikes.toString());
                          },
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.reply),
                      iconSize: 16,
                      onPressed: () {
                        _toggleReply();
                      },
                    ),
                    PopupMenuButton(
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(0)),
                      ),
                      icon: const Icon(Icons.more_horiz),
                      itemBuilder: (context) => [
                        if (FirebaseAuth.instance.currentUser?.uid == reviewData['userID'])  
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text("Edit"),
                            onTap: () {
                              _startEditing(_currentTextNotifier.value);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                         if (FirebaseAuth.instance.currentUser?.uid == reviewData['userID'])  
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text("Delete"),
                            onTap: () {
                              _deleteReply();
                              Navigator.pop(context);
                              // Handle delete action
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isReplying)
                  Row(
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 300.0,
                          ),
                          child: TextField(
                            maxLines: null,
                            autofocus: true,
                            controller: _textController,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.send,
                            decoration: const InputDecoration(
                              hintText: 'Write a reply',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(16.0)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendReply,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startEditing(String initialText) {
    _isEditingNotifier.value = true;
    _textController.text = initialText; // Set initial text in the TextField
    _currentTextNotifier.value = initialText; // Store the current text for comparison or reset
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

  Future<void> _sendReply() async {
    final user = FirebaseAuth.instance.currentUser;
    final data = await widget.data.reviewAndUserDocument;
    final reviewRef = data['review'].reference;
    if (user != null && reviewRef != null) {
      final commentText = _textController.text;

      reviewRef.collection('replies').add({
        'text': commentText,
        'userID': user.uid,
        'dateCreated': Timestamp.now(),
        'likes': [],
      }).then((_) {
        _replyCount.value += 1; // Increment reply count
        _textController.clear();
        _isReplying = false;
      }).catchError((error) {
        if (kDebugMode) {
          print('Failed to add reply: $error');
        }
      });
    }
  }

  Widget buildShimmerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildShimmerCircle(),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildShimmerBox(width: 100, height: 16),
                        const SizedBox(width: 10),
                        _buildShimmerBox(width: 50, height: 12),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _buildShimmerBox(width: 150, height: 13),
                        const SizedBox(width: 10),
                        _buildShimmerBox(width: 30, height: 12),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 38),
                Expanded(child: _buildShimmerBox(height: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildShimmerBox(width: 20, height: 16),
                const SizedBox(width: 5),
                _buildShimmerBox(width: 20, height: 16),
                const SizedBox(width: 5),
                _buildShimmerBox(width: 20, height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCircle({double size = 28.0}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildShimmerBox({double width = double.infinity, double height = 24.0}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _currentTextNotifier.dispose();
    _isEditingNotifier.dispose();
    super.dispose();
  }
}
