import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'movie_details.dart'; // Import the movie details page
import 'package:shimmer/shimmer.dart'; // Import the shimmer package
export 'discover_model.dart';

class ActivityWidget extends StatefulWidget {
  const ActivityWidget({Key? key});

  @override
  State<ActivityWidget> createState() => ActivityWidgetState();
}

class ActivityWidgetState extends State<ActivityWidget> {
  late List<Map<String, dynamic>> _wishlist = []; // Initialize the wishlist

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddListDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get(), // Replace 'user_id' with actual user ID
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final data = snapshot.data?.data() ?? {};
              final wishlist = data['wishlist'] as Map<String, dynamic>? ?? {};

              _wishlist = wishlist.entries.map((entry) {
                final listName = entry.key;
                final moviesList = entry.value as List<dynamic>;
                return {
                  'listName': listName,
                  'moviesList': moviesList,
                };
              }).toList();

              return Column(
                children: [
                  _buildListNames(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildWishlist(),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildListNames() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _wishlist.length,
        itemBuilder: (context, index) {
          final listName = _wishlist[index]['listName'] as String;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                // Implement onTap action here
              },
              child: Chip(
                label: Text(listName),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWishlist() {
    return ListView.builder(
      itemCount: _wishlist.length,
      itemBuilder: (context, index) {
        final moviesList = _wishlist[index]['moviesList'] as List<dynamic>;
        return Column(
          children: moviesList.map<Widget>((movieId) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailsWidget(movieID: movieId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    FutureBuilder<String>(
                      future: _loadPoster(movieId, retryCount: 3), // Retry 3 times if loading fails
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting || snapshot.connectionState == ConnectionState.none) {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 100,
                              height: 150,
                              color: Colors.white,
                            ),
                          );
                        } else if (snapshot.hasError || snapshot.data == null) {
                          return SizedBox(
                            width: 100,
                            height: 150,
                            child: Center(
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 100,
                                  height: 150,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              File(snapshot.data!), // Load image from local file
                              width: 100,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: tmdb.TMDBApi().getMovieTitle(movieId), // Convert movie ID to String
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return const Text('Movie Title Error');
                            } else {
                              return Text(
                                snapshot.data ?? 'Movie Title not available',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                          },
                        ),
                        FutureBuilder<String>(
                          future: tmdb.TMDBApi().getMovieReleaseDate(movieId), // Convert movie ID to String
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return const Text('Release Date Error');
                            } else {
                              return Text(
                                snapshot.data ?? 'Release Date not available',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<String> _loadPoster(int movieId, {int retryCount = 3}) async {
    try {
      return await tmdb.TMDBApi().getMoviePoster(movieId);
    } catch (e) {
      if (retryCount > 0) {
        // Retry loading poster
        return _loadPoster(movieId, retryCount: retryCount - 1);
      } else {
        // No more retries, return empty string
        return '';
      }
    }
  }

  Future<void> _showAddListDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Wishlist'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter Wishlist Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await _addWishlist(controller.text.trim());
                  controller.clear();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addWishlist(String listName) async {
    // Get a reference to the user's document
    DocumentReference doc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);
    // Check if the wishlist already exists
    DocumentSnapshot<Object?> wishlistSnapshot = await doc.get();
    if (wishlistSnapshot.exists && !(wishlistSnapshot.data() as Map).containsKey('wishlist')) {
      // Wishlist field exists
      // Now you can access the wishlist data
      await doc.set({'wishlist': {}}, SetOptions(merge: true));
    }
    Map<String, dynamic>? wishlistMap = wishlistSnapshot['wishlist'] as Map<String, dynamic>?;
    if (wishlistMap == null || !wishlistMap.containsKey(listName)) {
      await doc.set({'wishlist': {listName: []}}, SetOptions(merge: true));
    }
  }
}
