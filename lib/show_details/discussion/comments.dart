import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vixvox/show_details/discussion/commentItem.dart';

class CommentsWidget extends StatefulWidget {
  final int movieID;
  final Function(DocumentReference) onReply; // Change callback to pass DocumentReference
  final Color color;
  const CommentsWidget({Key? key, required this.movieID, required this.onReply, required this.color}) : super(key: key);

  @override
  _CommentsWidgetState createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  late Query<Map<String, dynamic>> _commentsQuery;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _comments = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _commentsQuery = FirebaseFirestore.instance
        .collection('movies')
        .doc(widget.movieID.toString())
        .collection('comments')
        .orderBy('dateCreated', descending: true)
        .limit(15);

    _scrollController.addListener(_scrollListener);
    loadComments();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _commentsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _comments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No comments yet.'));
        }

        final newComments = snapshot.data!.docs;
        // Avoid duplicate comments
        if (_comments.isEmpty) {
          _comments = newComments;
        }

        return Padding (padding:const EdgeInsets.only( top: 12.0, left: 8, right: 4), child: ListView.builder(
          controller: _scrollController,
          itemCount: _comments.length,
          itemBuilder: (context, index) {
            final comment = _comments[index];
            return  CommentItem(
              comment: comment,
              movieID: widget.movieID, color: widget.color,
              onReply: (commentRef) => widget.onReply(commentRef), // Use the callback to handle reply
            );
          },
        ));
      },
    );
  }

  void _scrollListener() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels != 0) {
        loadMoreComments();
      }
    }
  }

  void loadComments() {
    _commentsQuery.get().then((snapshot) {
      setState(() {
        _comments = snapshot.docs;
        _lastDocument = _comments.isNotEmpty ? _comments.last : null;
      });
    }).catchError((error) {
      print('Failed to load comments: $error');
    });
  }

  void loadMoreComments() {
    if (_isLoadingMore || _lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    _commentsQuery.startAfterDocument(_lastDocument!).get().then((snapshot) {
      setState(() {
        _comments.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _isLoadingMore = false;
      });
    }).catchError((error) {
      print('Failed to load more comments: $error');
      setState(() {
        _isLoadingMore = false;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
