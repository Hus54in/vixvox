import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'package:shimmer/shimmer.dart';
import '../show_details/movie_details.dart';

class ActivityWidget extends StatefulWidget {
  const ActivityWidget({Key? key}) : super(key: key);

  @override
  State<ActivityWidget> createState() => ActivityWidgetState();
}

class ActivityWidgetState extends State<ActivityWidget> {
  late List<Map<String, dynamic>> _wishlist = [];
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
    _fetchWishlistData();
  }

  Future<void> _fetchWishlistData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
      if (snapshot.exists) {
        final data = snapshot.data() ?? {};
        final wishlist = data['wishlist'] as Map<String, dynamic>? ?? {};
        _wishlist = wishlist.entries.map((entry) {
          final listID = entry.key;
          final listName = entry.value['name'] as String;
          final data = entry.value['list'] as List<dynamic>;
          return {
            'listName': listName,
            'moviesList': data,
            'listID': listID,
          };
        }).toList();
        setState(() {});
      }
    } catch (e) {
      print('Error fetching wishlist data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_wishlist.isNotEmpty ? _wishlist[_currentPageIndex]['listName'] : 'My Wishlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditListDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: _wishlist.length,
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return _buildWishlist(index);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddListDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWishlist(int index) {
  final moviesList = _wishlist[index]['moviesList'] as List<dynamic>;

  return ListView.builder(
    itemCount: moviesList.length + 1,
    itemBuilder: (context, index) {
      if (index == moviesList.length) {
        return _buildAddMovieButton();
      } else {
        final movieId = moviesList[index];
        return Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.red,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.delete, color: Colors.white),
            ),
          ),
          onDismissed: (direction) {
            setState(() {
              _wishlist[_currentPageIndex]['moviesList'].remove(movieId);
              removeMovieFromWishlist(_wishlist[_currentPageIndex]['listID'], movieId);
            });
          },
          child: Padding(
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
              child: FutureBuilder<String>(
                future: _loadPoster(movieId, retryCount: 3),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting || snapshot.connectionState == ConnectionState.none) {
                    return Shimmer.fromColors(
                      baseColor: Colors.black,
                      highlightColor: Colors.black12,
                      child: Container(
                        width: 100,
                        height: 150,
                        color: Colors.black,
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
                    return Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(snapshot.data!),
                            width: 100,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
  future: tmdb.TMDBApi().getMovieTitle(movieId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    } else if (snapshot.hasError) {
      return const Text('Movie Title Error');
    } else {
      return FutureBuilder<String>(
        future: _getReleaseYear(movieId), // Await _getReleaseYear here
        builder: (context, yearSnapshot) {
          if (yearSnapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (yearSnapshot.hasError) {
            return const Text('Release Year Error');
          } else {
            final releaseYear = yearSnapshot.data ?? '';
            return Text(
              '${snapshot.data} ($releaseYear)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            );
          }
        },
      );
    }
  },
),

                            FutureBuilder<String>(
                              future: tmdb.TMDBApi().getMovieGenres(movieId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return const Text('Genre Error');
                                } else {
                                  return Text(
                                    snapshot.data!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  );
                                }
                              },
                            ),
                            FutureBuilder<String>(
                              future: tmdb.TMDBApi().getMovieLength(movieId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return const Text('Length Error');
                                } else {
                                  return Text(
                                    snapshot.data!,
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
                    );
                  }
                },
              ),
            ),
          ),
        );
      }
    },
  );
}

Future<String> _getReleaseYear(int movieId) async {
  final releaseDate = await tmdb.TMDBApi().getMovieReleaseDate(movieId);
  final year = releaseDate.substring(releaseDate.length - 4);
  return year;
}



  Future<String> _loadPoster(int movieId, {int retryCount = 3}) async {
    try {
      return await tmdb.TMDBApi().getMoviePoster(movieId);
    } catch (e) {
      if (retryCount > 0) {
        return _loadPoster(movieId, retryCount: retryCount - 1);
      } else {
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
          title: const Text('Add New Wishlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter Wishlist Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await _addWishlist(controller.text.trim());
                  controller.clear();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddMovieButton() {
    return GestureDetector(
      onTap: () {
        // Handle add movie action
      },
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                width: 100,
                height: 150,
                color: Colors.grey[200], // Light grey color
                child: const Center(
                  child: Icon(
                    Icons.add,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Movie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> removeMovieFromWishlist(String listID, int movieId) async {
    try {
      DocumentReference doc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot<Object?> userSnapshot = await transaction.get(doc);

        if (userSnapshot.exists) {
          Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

          if (!userData.containsKey('wishlist')) {
            userData['wishlist'] = {};
          }

          Map<String, dynamic> wishlistMap = userData['wishlist'];

          if (wishlistMap.containsKey(listID)) {
            List<dynamic> moviesList = wishlistMap[listID]['list'];

            if (moviesList.contains(movieId)) {
              moviesList.remove(movieId);

              transaction.update(doc, {'wishlist': wishlistMap});

              setState(() {});
            }
          }
        }
      });
    } catch (error) {
      print("Error removing movie from wishlist: $error");
    }
  }

  Future<void> _addWishlist(String listName) async {
    DocumentReference doc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

    DocumentSnapshot<Object?> wishlistSnapshot = await doc.get();
    if (wishlistSnapshot.exists && !(wishlistSnapshot.data() as Map).containsKey('wishlist')) {
      await doc.set({'wishlist': {}}, SetOptions(merge: true));
    }
    Map<String, dynamic>? wishlistMap = wishlistSnapshot['wishlist'] as Map<String, dynamic>?;
    if (wishlistMap == null || !wishlistMap.containsKey(listName.hashCode.toString())) {
      await doc.set({'wishlist': {listName.hashCode.toString(): {'name': listName, 'list': []}}}, SetOptions(merge: true));
      await _fetchWishlistData();
      _buildWishlist(_currentPageIndex);
    }
  }

  Future<void> _showEditListDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController(text: _wishlist[_currentPageIndex]['listName']);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Wishlist'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter New Wishlist Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await _editWishlist(controller.text.trim());
                  controller.clear();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () async {
                await _confirmDeleteList(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editWishlist(String newListName) async {
    try {
      String listID = _wishlist[_currentPageIndex]['listID'];

      DocumentReference doc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot<Object?> userSnapshot = await transaction.get(doc);

        if (userSnapshot.exists) {
          Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

          if (!userData.containsKey('wishlist')) {
            userData['wishlist'] = {};
          }

          Map<String, dynamic> wishlistMap = userData['wishlist'];

          if (wishlistMap.containsKey(listID)) {
            wishlistMap[listID]['name'] = newListName;

            transaction.update(doc, {'wishlist': wishlistMap});

            setState(() {
              _wishlist[_currentPageIndex]['listName'] = newListName;
            });
          }
        }
      });
    } catch (error) {
      print("Error editing wishlist: $error");
    }
  }

  Future<void> _confirmDeleteList(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this wishlist?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteWishlist();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteWishlist() async {
    try {
      String listID = _wishlist[_currentPageIndex]['listID'];

      DocumentReference doc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot<Object?> userSnapshot = await transaction.get(doc);

        if (userSnapshot.exists) {
          Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

          if (!userData.containsKey('wishlist')) {
            userData['wishlist'] = {};
          }

          Map<String, dynamic> wishlistMap = userData['wishlist'];

          if (wishlistMap.containsKey(listID)) {
            wishlistMap.remove(listID);

            transaction.update(doc, {'wishlist': wishlistMap});

            setState(() {
              _wishlist.removeAt(_currentPageIndex);
              if (_currentPageIndex >= _wishlist.length) {
                _currentPageIndex--;
                _pageController.jumpToPage(_currentPageIndex);
              }
            });
             Navigator.of(context).pop();
          }
        }
      });
    } catch (error) {
      print("Error deleting wishlist: $error");
    }
  }
}
