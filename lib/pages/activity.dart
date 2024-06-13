import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vixvox/TMDBapi/movie.dart';
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
          final moviesList = entry.value['list'] as List<dynamic>;

          final List<Movie> movieObjects = [];
          for (var movieId in moviesList) {
            final movie = await tmdb.TMDBApi().getMovie(movieId);
            movieObjects.add(movie);
          }

          wishlistData.add({
            'listName': listName,
            'moviesList': movieObjects,
            'listID': listID,
          });
        }

        setState(() {
          _wishlist = wishlistData;
        });
      }
    } catch (e) {
      print('Error fetching wishlist data: $e');
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
        // GestureDetector to handle horizontal swipes
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx > 0) {
            // swiped right
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
            // swiped left
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
  final moviesList = _wishlist[index]['moviesList'] as List<Movie>;

  return ListView.builder(
    itemCount: moviesList.length + 1,
    itemBuilder: (context, idx) {
      if (idx == moviesList.length) {
        return _buildAddMovieButton();
      } else {
        final movie = moviesList[idx];
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
              _wishlist[index]['moviesList'].remove(movie);
              _removeMovieFromWishlist(
                  _wishlist[index]['listID'], movie.id);
            });
          },
          child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MovieDetailsWidget(movieID: movie.id),
                    ),
                  );
                },child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    movie.posterUrl,
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${movie.title} (${(movie.releaseDate).substring(movie.releaseDate.length - 4)})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        movie.genres,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${movie.length} • ${movie.voteAverage} ⭐',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditMovieDialog(context, movie);
                    } 
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Write Review',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Write Review'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Rate',
                      child: ListTile(
                        leading: Icon(Icons.star),
                        title: Text('Rate'),
                      ),
                    ),
                     const PopupMenuItem<String>(
                      value: 'Remove',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          )
        );
      }
    },
  );
}

Future<void> _showEditMovieDialog(BuildContext context, Movie movie) async {
  // Implement your edit movie dialog here
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
      print("Error removing movie from wishlist: $error");
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
            decoration:
                const InputDecoration(hintText: 'Enter Wishlist Name'),
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
                color: Colors.grey[200],
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

  Future<void> _addWishlist(String listName) async {
    
    try {
      DocumentReference doc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

      final snapshot = await doc.get();
      if (snapshot.exists && !(snapshot.data() as Map).containsKey('wishlist')) {
        await doc.set({'wishlist': {}}, SetOptions(merge: true));
      }

      final listID = listName.hashCode.toString();
      await doc.set({'wishlist': {listID: {'name': listName, 'list': []}}}, SetOptions(merge: true));

      await _fetchWishlistData();
    } catch (error) {
      print("Error adding wishlist: $error");
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
      print("Error editing wishlist: $error");
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
      print("Error deleting wishlist: $error");
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

