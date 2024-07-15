import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vixvox/reviews/reviewdataloader.dart';
import 'package:vixvox/reviews/reviews.dart';

class ProfilePageWidget extends StatefulWidget {
  const ProfilePageWidget({Key? key, required this.userID}) : super(key: key);

  final String userID;

  @override
  State<ProfilePageWidget> createState() => ProfilePageWidgetState();
}
class ProfilePageWidgetState extends State<ProfilePageWidget> {
  DocumentSnapshot? userDoc;
  List<ReviewDataLoader> reviewLoaders = [];
  List<Widget> reviewWidgets = [];
  String? profileImageUrl;
  bool isLoading = false;
  bool hasMore = true;
  bool isFollowing = false;
  List<String> shownUserFollowers = [];
  List<String> shownUserFollowing = [];
  final ScrollController _scrollController = ScrollController();
  QuerySnapshot? lastLoadedSnapshot;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && hasMore) {
      _loadMoreData();
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = await FirebaseFirestore.instance.collection('users').doc(widget.userID).get();
      final imageUrl = await getImageUrl();

      List<ReviewDataLoader> loaders = [];
      if (user.exists) {
        try {
        final ratings = user.get('ratings') as Map<String, dynamic> ;
        for (String key in ratings.keys) {
          for (int i = 0; i < ratings[key].length; i += 2) {
            String reviewId = ratings[key][i + 1];
            loaders.add(ReviewDataLoader(
              documentId: reviewId,
              movieId: int.tryParse(key),
              tvshowId: null, // Assuming there's no TV show equivalent in this context
            ));
          }
        }
      }
      catch (e) {
        print('Failed to load ratings: $e');
      }

        // Fetch followers and following of shown user
        final followersList = user.get('followers') ?? [];
        final followingList = user.get('following') ?? [];

        setState(() {
          shownUserFollowers = List<String>.from(followersList);
          shownUserFollowing = List<String>.from(followingList);
        });
      }

      setState(() {
        userDoc = user;
        reviewLoaders = loaders;
        profileImageUrl = imageUrl;
        reviewWidgets = loaders.map((loader) => ReviewWidget(data: loader, onDelete: _removeReview)).toList();
        isLoading = false;
      });

      // Initialize pagination
      await _paginateReviews();

      // Check if current user is following this user
      await _checkFollowingStatus();
    } catch (error) {
      print('Failed to load profile data: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkFollowingStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(widget.userID).get();
      final followingList = userSnapshot.get('followers') ?? [];
      setState(() {
        isFollowing = followingList.contains(currentUser.uid);
      });
    }
  }

  Future<String?> getImageUrl() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile/${widget.userID}.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _paginateReviews() async {
    if (!hasMore || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot;
      if (lastLoadedSnapshot == null) {
        snapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('userID', isEqualTo: widget.userID)
            .orderBy('dateCreated', descending: true)
            .limit(10)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('userId', isEqualTo: widget.userID)
            .orderBy('timestamp', descending: true)
            .startAfterDocument(lastLoadedSnapshot!.docs.last)
            .limit(10)
            .get();
      }

      final List<ReviewDataLoader> loaders = [];
      for (var doc in snapshot.docs) {
        loaders.add(ReviewDataLoader(
          documentId: doc.id,
          movieId: doc['movieId'],
          tvshowId: doc['tvshowId'], // Adjust as per your document structure
        ));
      }

      setState(() {
        reviewLoaders.addAll(loaders);
        reviewWidgets.addAll(loaders.map((loader) => ReviewWidget(data: loader, onDelete: _removeReview)).toList());
        lastLoadedSnapshot = snapshot;
        isLoading = false;
        hasMore = snapshot.docs.length == 10; // Assuming limit is 10
      });
    } catch (error) {
      print('Failed to paginate reviews: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (!isLoading && hasMore) {
      await _paginateReviews();
    }
  }

  Future<void> _refreshProfileData() async {
    lastLoadedSnapshot = null;
    reviewLoaders.clear();
    reviewWidgets.clear();
    hasMore = true;
    await _loadProfileData();
  }

  void _removeReview(String documentId) {
    setState(() {
      reviewLoaders.removeWhere((loader) => loader.documentId == documentId);
      reviewWidgets.removeWhere((widget) {
        if (widget is ReviewWidget) {
          return widget.data.documentId == documentId;
        }
        return false;
      });
    });
  }

  Future<void> _followUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.userID).update({
          'followers': FieldValue.arrayUnion([currentUser.uid]),
        });
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'following': FieldValue.arrayUnion([widget.userID]),
        });
        setState(() {
          isFollowing = true;
          shownUserFollowers.add(currentUser.uid);
        });
      } catch (error) {
        print('Failed to follow user: $error');
        // Handle error as needed
      }
    }
  }

  Future<void> _unfollowUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.userID).update({
          'followers': FieldValue.arrayRemove([currentUser.uid]),
        });
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'following': FieldValue.arrayRemove([widget.userID]),
        });
        setState(() {
          isFollowing = false;
          shownUserFollowers.remove(currentUser.uid);
        });
      } catch (error) {
        print('Failed to unfollow user: $error');
        // Handle error as needed
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: CachedNetworkImageProvider(
                  profileImageUrl ?? 'https://avatar.iran.liara.run/username?username=${userDoc?.get('displayName')}',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      userDoc?.get('displayName') ?? "User Name Not Found",
                      style: const TextStyle(
                        fontFamily: 'Urbanist',
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${shownUserFollowers.length} Followers | ${shownUserFollowing.length} Following',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10), // Adjust as needed
                    if (FirebaseAuth.instance.currentUser != null &&
                        FirebaseAuth.instance.currentUser!.uid != widget.userID)
                      ElevatedButton(
                        onPressed: isFollowing ? _unfollowUser : _followUser,
                        style: ButtonStyle(
                          backgroundColor: isFollowing ? MaterialStateProperty.all<Color>(Colors.blue) : MaterialStateProperty.all<Color>(Colors.white),
                          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.symmetric(vertical: 10, horizontal: 40)),
                        ),
                        child: Text(
                          isFollowing ? 'Unfollow' : 'Follow',
                          style: TextStyle(
                            color: isFollowing ? Colors.white : Colors.blue,
                            fontSize: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (reviewWidgets.isEmpty && isLoading)
            const Center(child: CircularProgressIndicator())
          else if (reviewWidgets.isEmpty)
            const Center(child: Text('No reviews found'))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshProfileData,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  itemCount: reviewWidgets.length + (hasMore ? 1 : 0),
                  cacheExtent: 1000, // Increase cache extent
                  itemBuilder: (context, index) {
                    if (index == reviewWidgets.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return reviewWidgets[index];
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
