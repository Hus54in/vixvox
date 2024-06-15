import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:vixvox/show_details/discussion/comments.dart';

class DiscussionPage extends StatefulWidget {
  final int movieID;
  final Color color;

  const DiscussionPage({Key? key, required this.movieID, required this.color}) : super(key: key);

  @override
  _DiscussionPageState createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final TextEditingController _textController = TextEditingController();
  double _userRating = 0.0;
  bool _showRatingSlider = false;
  bool _replyingToSelf = false;
  final FocusNode _textFocus = FocusNode();
  DocumentReference? _replyingToCommentRef;
 ValueNotifier<double> _sliderValue = ValueNotifier<double>(0.0);
  @override
  void initState() {
    super.initState();
    _checkUserRatedMovie();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshComments,
              child: CommentsWidget(
                key: UniqueKey(), // Key to force rebuild CommentsWidget on refresh
                movieID: widget.movieID,
                color: widget.color,
                onReply: (commentRef) {
                  setState(() {
                    _replyingToCommentRef = commentRef as DocumentReference<Object?>?;
                    _textFocus.requestFocus();
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ValueListenableBuilder<double>(
                      valueListenable: _sliderValue,
                      builder: (context, sliderValue, _) {
                        return Text(sliderValue.toStringAsFixed(1), style: const TextStyle(fontSize: 18));
                      },
                    ),
                    Expanded(
                      child: Visibility(
                        visible: _showRatingSlider,
                        child: InteractiveSlider(
                          min: 0.0,
                          max: 10.0,
                          onChanged: (newValue) {
                            _sliderValue.value = newValue;
                          },
                          onProgressUpdated: (newValue) {
                            setState(() {
                              _userRating = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        child: new ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: 300.0,
                          ),
                          child: TextField(
                          focusNode: _textFocus,
                          maxLines: null,
                          autofocus: true,
                          controller: _textController,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: _replyingToCommentRef != null ? 'Replying to comment...' : 'Enter your comment...',
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16.0)),
                            
                          ),
                        ),
                      ),
                        ),)
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshComments() async {
    setState(() {
      // Update any necessary state variables related to refreshing comments
    });
  }

  Future<void> _checkUserRatedMovie() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userData.exists) {
        final data = userData.data() as Map<String, dynamic>;
        if (data.containsKey('ratings') && data['ratings'].containsKey(widget.movieID.toString())) {
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
      if (_replyingToCommentRef != null) {
        _sendReply();
      } else {
        _sendComment();
      }
    }
  }

  void _sendComment() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final movieRating = _sliderValue.value.toInt(); // Use slider value here
      final commentText = _textController.text;

      userRef.update({
        'ratings.${widget.movieID.toString()}': [movieRating],
      }).then((_) {
        FirebaseFirestore.instance
            .collection('movies')
            .doc(widget.movieID.toString())
            .collection('comments')
            .add({
              'text': commentText,
              'userID': user.uid,
              'dateCreated': Timestamp.now(),
              'rating': movieRating,
              'likes': [],
            })
            .then((commentDoc) {
              userRef.update({
                'ratings.${widget.movieID.toString()}': FieldValue.arrayUnion([commentDoc.id]),
              }).then((_) {
                setState(() {
                  _textController.clear();
                  _showRatingSlider = false;
                  _replyingToSelf = true;
                });
              }).catchError((error) {
                print('Failed to update user comments: $error');
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

  void _sendReply() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _replyingToCommentRef != null) {
      final commentText = _textController.text;

      _replyingToCommentRef!
          .collection('replies')
          .add({
            'text': commentText,
            'userID': user.uid,
            'dateCreated': Timestamp.now(),
            'likes': [],
          }).then((_) {
            setState(() {
              _textController.clear();
              _replyingToCommentRef = null;
            });
          }).catchError((error) {
            print('Failed to add reply: $error');
          });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }
}

class SliderWidget extends StatefulWidget {
  final ValueNotifier<double> sliderValue;

  const SliderWidget({Key? key, required this.sliderValue}) : super(key: key);

  @override
  _SliderWidgetState createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.sliderValue,
      builder: (context, value, child) {
        return InteractiveSlider(
          min: 0.0,
          max: 10.0,
          onChanged: (newValue) {
            widget.sliderValue.value = newValue;
          },
          onProgressUpdated: (newValue) {
            // Handle value update if needed
          },
        );
      },
    );
  }
}
