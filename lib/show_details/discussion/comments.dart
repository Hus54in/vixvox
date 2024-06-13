import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentsWidget extends StatefulWidget {
  final int movieID;

  const CommentsWidget({Key? key, required this.movieID}) : super(key: key);

  @override
  _CommentsWidgetState createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  late Query<Map<String, dynamic>> _commentsQuery; // Declare query variable
  DocumentSnapshot? _lastDocument; // Track the last document for pagination
  final ScrollController _scrollController = ScrollController(); // Scroll controller
  List<DocumentSnapshot> _comments = []; // List to hold all comments

  @override
  void initState() {
    super.initState();
    _commentsQuery = FirebaseFirestore.instance
        .collection('movies')
        .doc(widget.movieID.toString())
        .collection('comments')
        .orderBy('dateCreated', descending: true)
        .limit(15); // Initial query for first 15 comments

    // Attach listener to scroll controller
    _scrollController.addListener(_scrollListener);

    // Call method to load comments initially
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

        // Handle null snapshot or empty data
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No comments yet.'));
        }

        // Extract new comments from snapshot
        final newComments = snapshot.data!.docs;

        // Update _lastDocument for pagination
        _lastDocument = newComments.isNotEmpty ? newComments[newComments.length - 1] : null;

        return ListView.builder(
          controller: _scrollController, // Assign scroll controller to ListView
          itemCount: _comments.length,
          itemBuilder: (context, index) {
            final comment = _comments[index];
            final userID = comment['userID'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userID).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: const Text('Loading...'),
                    subtitle: Text(comment['text']),
                  );
                }
                if (snapshot.hasError) {
                  return ListTile(
                    title: Text('Error: ${snapshot.error}'),
                    subtitle: Text(comment['text']),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final userName = userData['displayName'].toString();
                

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Expanded(
          child: Text(
            userName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
    const SizedBox(height: 4),
    Text(
      comment['text'],
      style: const TextStyle(fontSize: 14),
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        TextButton.icon(
          icon: const Icon(Icons.favorite_border),
          label: const Text('Like'),
          onPressed: () {
            // Handle like button press
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.reply),
          label: const Text('Reply'),
          onPressed: () {
            // Handle reply button press
          },
        ),
       
         IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {
                // Handle options button press
              },
            ),

    const Divider(), // Optional: Add a divider between comments for visual separation
  ],
    )]

 
);


              },
            );
          },
        );
      },
    );
  }

  void _scrollListener() {
    // Check if the user has scrolled to the end of the list
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      loadMoreComments();
    }
  }

  void loadComments() async {
    final snapshot = await _commentsQuery.get();
    final comments = snapshot.docs;

    setState(() {
      _comments.addAll(comments);
    });
  }

  void loadMoreComments() async {
    if (_lastDocument != null) {
      // Construct a new query starting after the last document
      final nextQuery = _commentsQuery.startAfterDocument(_lastDocument!).limit(15);

      final snapshot = await nextQuery.get();
      final newComments = snapshot.docs;

      setState(() {
        _comments.addAll(newComments);
        _lastDocument = newComments.isNotEmpty ? newComments[newComments.length - 1] : null;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }
}
