import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vixvox/show_details/discussion/comments.dart';   
class DiscussionPage extends StatefulWidget {
  final int movieID;

  const DiscussionPage({Key? key, required this.movieID}) : super(key: key);

  @override
  _DiscussionPageState createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final TextEditingController _textController = TextEditingController();
  double _userRating = 0.0;
  bool _showRatingSlider = false;
  bool _replyingToSelf = false; // New state variable
  final FocusNode _textFocus = FocusNode(); // Focus node for the text field

  @override
  void initState() {
    super.initState();
    _checkUserRatedMovie();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CommentsWidget(movieID: widget.movieID),
        ),
        // Ensure comment input and rating slider are always at the bottom
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Visibility(
                visible: _showRatingSlider,
                child: Slider(
                  value: _userRating,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  label: _userRating.toStringAsFixed(1),
                  onChanged: (newValue) {
                    setState(() {
                      _userRating = newValue;
                    });
                  },
                ),
              ),
              TextField(
                focusNode: _textFocus, // Assign the focus node
                controller: _textController,
                decoration: InputDecoration(
                  hintText: _replyingToSelf
                      ? 'Replying to self'
                      : 'Enter your comment...',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _checkUserRatedMovie() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userData.exists) {
        final data = userData.data() as Map<String, dynamic>;
        if (data.containsKey('ratings') &&
            data['ratings'].containsKey(widget.movieID.toString())) {
          setState(() {
            _userRating = data['ratings'][widget.movieID.toString()];
            _showRatingSlider = false;
            _replyingToSelf = true;
          });
        } else {
          setState(() {
            _showRatingSlider = true;
          });
        }
      }
    }
  }

  void _sendMessage() {
    if (_textController.text.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final movieRating = _userRating.toInt();
        userRef.update({
          'ratings.${widget.movieID.toString()}': movieRating,
        }).then((_) {
          FirebaseFirestore.instance
              .collection('movies')
              .doc(widget.movieID.toString())
              .collection('comments')
              .add({
                'text': _textController.text,
                'userID': user.uid,
                'dateCreated': Timestamp.now(),
                'rating': movieRating,
              })
              .then((_) {
                setState(() {
                  _textController.clear();
                  _showRatingSlider = false;
                  _replyingToSelf = true;
                });
              })
              .catchError((error) {
                print('Failed to add comment: $error');
              });
        }).catchError((error) {
          print('Failed to update user ratings: $error');
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose(); // Dispose focus node
    super.dispose();
  }
}


