import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vixvox/reviews/reviewdataloader.dart';
import 'package:vixvox/reviews/reviews.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePageWidget> {
  late final User _currentUser;
  late List<String> _followingIds = []; // Store ids of users current user is following
  List<ReviewDataLoader> _reviews = []; // Store reviews to display

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _fetchFollowingIds();
  }

  Future<void> _fetchFollowingIds() async {
    final followingSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .get();

    setState(() {
      _followingIds = List<String>.from(followingSnapshot.data()?['following'] ?? []);
    });

    _fetchFollowingReviews();
  }

  Future<void> _fetchFollowingReviews() async {
    List<ReviewDataLoader> reviews = [];

    for (String userId in _followingIds) {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('users')
        .doc(userId)
        .get();

     if (reviewsSnapshot.exists) {
      try {
        final ratings = reviewsSnapshot.get('ratings') as Map<String, dynamic>;
        for (String key in ratings.keys) {
          for (int i = 0; i < ratings[key].length; i += 2) {
            String reviewId = ratings[key][i + 1];
            reviews.add(ReviewDataLoader(
              documentId: reviewId,
              movieId: int.tryParse(key),
              tvshowId: null, // Assuming there's no TV show equivalent in this context
            ));
          }
        }
      }
        catch (e) {
          if (kDebugMode) {
            print(e);
          }
        }
      }
    }
    try {
    reviews.sort((a, b) => b.datecreated.compareTo(a.datecreated));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    setState(() {
      _reviews = reviews;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following Reviews'),
      ),
      body: _reviews.isEmpty
          ? const Center(child: Text('No reviews found'))
          : ListView.builder(
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                return ReviewWidget(
                  data: _reviews[index],
                  onDelete: _handleDelete,
                );
              },
            ),
    );
  }

  void _handleDelete(String reviewId) {
    // Handle delete logic if needed
    print('Deleting review with id: $reviewId');
  }
}
