import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vixvox/TMDBapi/movie.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'package:vixvox/TMDBapi/tvshow.dart';
import 'package:vixvox/show_details/movie_details.dart';
import 'package:vixvox/show_details/movielistdetails.dart';
import 'package:vixvox/show_details/tvShow_details.dart';

class ActivityWidget extends StatefulWidget {
  const ActivityWidget({super.key});

  @override
  State<ActivityWidget> createState() => ActivityWidgetState();
}

class ActivityWidgetState extends State<ActivityWidget> {
  late List<Map<String, dynamic>> _wishlist = [];
  late PageController _pageController;
  int _currentPageIndex = 0;
  ValueNotifier<String> mediaType = ValueNotifier<String>('Movie');

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
    _fetchWishlistData();
  }
  @override
  void dispose() {
    _pageController.dispose();
    mediaType.dispose();
    super.dispose();
  }
  Future<void> _fetchWishlistData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      if (snapshot.exists) {
        final data = snapshot.data() ?? {};
        final wishlist = data['wishlist'] as Map<String, dynamic>? ?? {};
        final List<Map<String, dynamic>> wishlistData = [];

        for (var entry in wishlist.entries) {
          final listID = entry.key;
          final listName = entry.value['name'] as String;
          final type = entry.value['type'] as String;
          final moviesList = entry.value['list'] as List<dynamic>;

          final List<Movie> movieObjects = [];
          final List<TVShow> tvShowObjects = [];
          if (type == 'Movie') {
            for (var movieId in moviesList) {
              final movie = await tmdb.TMDBApi().getMovie(movieId);
              movieObjects.add(movie);
            }
            wishlistData.add({
            'listName': listName,
            'type': type,
            'moviesList': movieObjects,
            'listID': listID,
          });
          } else {
            for (var tvShowId in moviesList) {
              final tvShow = await tmdb.TMDBApi().getTVShow(tvShowId);
              tvShowObjects.add(tvShow);
            }
            wishlistData.add({
            'listName': listName,
            'type': type,
            'moviesList': tvShowObjects,
            'listID': listID,
          });
          }


        }

        setState(() {
          _wishlist = wishlistData;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching wishlist data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_wishlist.isNotEmpty
            ? _wishlist[_currentPageIndex]['listName']
            : 'My Wishlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditListDialog(context),
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx > 0) {
            if (_currentPageIndex > 0) {
              setState(() {
                _currentPageIndex--;
              });
              _pageController.animateToPage(
                _currentPageIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          } else if (details.delta.dx < 0) {
            if (_currentPageIndex < _wishlist.length - 1) {
              setState(() {
                _currentPageIndex++;
              });
              _pageController.animateToPage(
                _currentPageIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        },
        child: SafeArea(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddListDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWishlist(int index) {
    final type = _wishlist[index]['type'] as String;


    final moviesList = _wishlist[index]['moviesList']; 
    print(moviesList);

    return ListView.builder(
      itemCount: moviesList.length,
      itemBuilder: (context, idx) {
       
          final movie = moviesList[idx];

          if (type == 'Movie') {
            return MovieListItem(
              movie: movie,
              onDismissed: () {
                setState(() {
                  _wishlist[index]['moviesList'].remove(movie);
                  _removeMovieFromWishlist(
                      _wishlist[index]['listID'], movie.id);
                });
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MovieDetailsWidget(movieID: movie.id, movie: movie,),
                  ),
                );
              },
            );
          }
          else {
          return  MovieListItem(
            tvShow: movie ,
            onDismissed: () {
              setState(() {
                _wishlist[index]['moviesList'].remove(movie);
                _removeMovieFromWishlist(
                    _wishlist[index]['listID'], movie.id);
              });
            },
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TvShowDetailsWidget(tvShowId: movie.id, tvshow: movie,),
                ),
              );
            },
          ); }
        
      },
    );
  }

  Future<void> _removeMovieFromWishlist(
      String listID, int movieId) async {
    try {
      DocumentReference doc = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot<Object?> userSnapshot =
            await transaction.get(doc);

        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;

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
      if (kDebugMode) {
        print("Error removing movie from wishlist: $error");
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter Wishlist Name'),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<String>(
              valueListenable: mediaType,
              builder: (context, value, child) {
                return ToggleButtons(
                  isSelected: [value == 'Movie', value == 'TV Show'],
                  onPressed: (index) {
                    if (index == 0) {
                      mediaType.value = 'Movie';
                    } else {
                      mediaType.value = 'TV Show';
                    }
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Movie'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('TV Show'),
                    ),
                  ],
                );
              },
            ),
          ],
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
                await _addWishlist(controller.text.trim(), mediaType.value);
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






Future<void> _addWishlist(String listName, String mediaType) async {
  try {
    DocumentReference doc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);

    final snapshot = await doc.get();
    if (snapshot.exists && !(snapshot.data() as Map).containsKey('wishlist')) {
      await doc.set({'wishlist': {}}, SetOptions(merge: true));
    }

    final listID = listName.hashCode.toString();
    await doc.set({
      'wishlist': {
        listID: {'name': listName, 'type': mediaType, 'list': []}
      }
    }, SetOptions(merge: true));

    await _fetchWishlistData();
  } catch (error) {
    if (kDebugMode) {
      print("Error adding wishlist: $error");
    }
  }
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
      if (kDebugMode) {
        print("Error editing wishlist: $error");
      }
    }
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
          }
        }
      });
    } catch (error) {
      if (kDebugMode) {
        print("Error deleting wishlist: $error");
      }
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
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
}
