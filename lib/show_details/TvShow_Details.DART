import 'dart:io';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;

class TVShowDetailsWidget extends StatefulWidget {
  const TVShowDetailsWidget({Key? key, required this.tvShowID}) : super(key: key);

  final int tvShowID;

  @override
  _TVShowDetailsWidgetState createState() => _TVShowDetailsWidgetState();
}

class _TVShowDetailsWidgetState extends State<TVShowDetailsWidget> {
  late String _tvShowTitle;
  late String _tvShowPoster;
  late String _tvShowSummary;
  late String _tvShowReleaseDate;
  late String _tvShowGenres;
  late double _rating = 0.0;
  late List<Map<String, dynamic>> _tvShowCast = [];
  late int _tvShowLength = 0;
  late String _trailer = '';
  late Map<String, dynamic> _watchProviders = {};
  late Color dominantColor = Colors.black;
  late Color darkVibrantColor = Colors.grey.shade900;
  late bool add_button = false;
  late String _selectedList = '0'; // Selected wishlist from dropdown
  late Map<String, dynamic> _items = {'0': {'name': 'My List', 'list': [1234, 5678]}};

  @override
  void initState() {
    super.initState();
    _fetchTVShowDetails();
    _buildDropdownItems();
    _isTVShowAddedToSelectedList();
  }

  Future<void> _fetchTVShowDetails() async {
    _tvShowLength = await tmdb.TMDBApi().getTVShowLength(widget.tvShowID) ?? 0;
    _tvShowReleaseDate = await tmdb.TMDBApi().getTVShowReleaseDate(widget.tvShowID) ?? '';
    _tvShowGenres = await tmdb.TMDBApi().getTVShowGenres(widget.tvShowID) ?? '';
    _tvShowTitle = await tmdb.TMDBApi().getTVShowTitle(widget.tvShowID) ?? '';
    _tvShowSummary = await tmdb.TMDBApi().getTVShowSummary(widget.tvShowID) ?? '';
    _trailer = await tmdb.TMDBApi().getTVShowTrailer(widget.tvShowID) ?? '';

    final tvShowPoster = await tmdb.TMDBApi().getTVShowPoster(widget.tvShowID);
    setState(() {
      _tvShowPoster = tvShowPoster;
    });

    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      FileImage(File(_tvShowPoster)),
    );

    setState(() {
      dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
      darkVibrantColor = paletteGenerator.darkVibrantColor?.color ?? dominantColor;
    });

    final providers = await tmdb.TMDBApi().getTVShowWatchProviders(widget.tvShowID);
    setState(() {
      _watchProviders = providers["results"]["CA"] ?? {};
    });

    final cast = await tmdb.TMDBApi().getTVShowCast(widget.tvShowID); // Fetch cast information
    setState(() {
      _tvShowCast = cast;
    });

    final ratings = await tmdb.TMDBApi().gettvshowRatings(widget.tvShowID);
    setState(() {
      _rating = ratings['averageRating'] ?? 0.0;
    });
  }

  @override
Widget build(BuildContext context) {
  TextStyle linkStyle = const TextStyle(color: Colors.blue);

  return Scaffold(
    appBar: AppBar(
      title: Text(_tvShowTitle),
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            dominantColor,
            darkVibrantColor,
            Colors.black,
          ],
          stops: const [0.0, 0.0, 0.7],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _tvShowPoster.isNotEmpty
                        ? Image.file(File(_tvShowPoster), width: 120, height: 180)
                        : Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 120,
                              height: 180,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tvShowTitle,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _tvShowSummary,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Genres: $_tvShowGenres',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Release Date: $_tvShowReleaseDate',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          width: 100,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _getRatingColor(_rating),
                          ),
                          child: Center(
                            child: Text(
                              '${_rating.toStringAsFixed(1)}/10.0',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                       _buildTrailerButton()
                      ])// Add Trailer Button
                ),
           
            Column(
                  children: [
                    const Text(
                      'Watch Providers',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _buildProviderWidgets(),
                    ),
                  ],
                ),
            _buildCastWidgets(),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildCastWidgets() {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tvShowCast.map<Widget>((castMember) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                ClipOval(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: FileImage(File(castMember['profilePic'])) // Use Image.file for locally cached image
                        
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  castMember['name'],
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 8),
                Text(
                  castMember['character'],
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
}


  Future<void> _buildDropdownItems() async {
    DocumentReference doc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

    // Check if the wishlist already exists

    // ...

    DocumentSnapshot<Object?> wishlistSnapshot = await doc.get();

    Map<String, dynamic>? wishlistMap = wishlistSnapshot['wishlist'] as Map<String, dynamic>?;
    setState(() {
      _items = wishlistMap ?? {};
      _selectedList = _items.keys.first;
      add_button = _isTVShowAddedToSelectedList();
    });
  }

Widget _buildTrailerButton() {
  return Padding(
    padding: const EdgeInsets.all(5),
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(5),
          child: IconButton(
            icon: Icon(Icons.play_arrow, size: 40),
            onPressed: () async {
              bool nativeAppLaunchSucceeded = false;
              if (_trailer.isNotEmpty) {
                final bool nativeAppLaunchSucceeded = await launch(_trailer,
                    universalLinksOnly: true, forceSafariVC: false, forceWebView: false);

                if (!nativeAppLaunchSucceeded) {
                  await launch(_trailer, forceSafariVC: true);
                }
              }
            },
          ),
        ),
        Text(
          'Play Trailer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    ),
  );
}



  List<Widget> _buildProviderWidgets() {
    List<Widget> widgets = [];

    // Iterate through each provider item
    _watchProviders.forEach((key, value) {
      // Iterate through each provider type (flatrate, buy, rent)
      for (var providerType in ['flatrate']) {
        if (key == providerType) {
          // Create a row of provider logos and names
          final providerRow = Row(
            children: (value as List<dynamic>).map<Widget>((provider) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          'https://image.tmdb.org/t/p/w92${provider['logo_path']}',
                          width: 70,
                          height: 70,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        provider['provider_name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );

          // Wrap the row with SingleChildScrollView for horizontal scrolling
          widgets.add(
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: providerRow,
              ),
            ),
          );
        }
      }
    });

    return widgets;
  }

  Future<void> addTVShowToWishlist(String listID, int tvShowID) async {
    try {
      // Get a reference to the user's document
      DocumentReference doc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Retrieve the user document within the transaction
        DocumentSnapshot<Object?> userSnapshot = await transaction.get(doc);

        // Ensure the user document exists
        if (userSnapshot.exists) {
          Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

          // Ensure wishlist field exists
          if (!userData.containsKey('wishlist')) {
            userData['wishlist'] = {};
          }

          Map<String, dynamic> wishlistMap = userData['wishlist'];

          List<dynamic> tvShowsList = wishlistMap[listID]['list'];

          // Check if the tvShowID already exists in the list
          if (!tvShowsList.contains(tvShowID)) {
            // Add the tvShowID to the tvShows list
            tvShowsList.add(tvShowID);
          }

          // Update the user document with the modified wishlist data
          transaction.update(doc, {'wishlist': wishlistMap});
          _items[_selectedList]?['list'].add(tvShowID);
        }
      });
    } catch (error) {
      // Handle any errors that occur during the transaction
      print("Error adding TV show to wishlist: $error");
    }
  }

  Future<void> removeTVShowFromWishlist(String listID, int tvShowID) async {
    try {
      // Get a reference to the user's document
      DocumentReference doc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Retrieve the user document within the transaction
        DocumentSnapshot<Object?> userSnapshot = await transaction.get(doc);

        // Ensure the user document exists
        if (userSnapshot.exists) {
          Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

          // Ensure wishlist field exists
          if (!userData.containsKey('wishlist')) {
            userData['wishlist'] = {};
          }

          Map<String, dynamic> wishlistMap = userData['wishlist'];

          // Check if the listID exists in the wishlist
          if (wishlistMap.containsKey(listID)) {
            List<dynamic> tvShowsList = wishlistMap[listID]['list'];

            // Check if the tvShowID exists in the list
            if (tvShowsList.contains(tvShowID)) {
              // Remove the tvShowID from the tvShows list
              tvShowsList.remove(tvShowID);
            }

            // Update the user document with the modified wishlist data
            _items[_selectedList]?['list'].remove(tvShowID);
            transaction.update(doc, {'wishlist': wishlistMap});
          }
        }
      });
    } catch (error) {
      // Handle any errors that occur during the transaction
      print("Error removing TV show from wishlist: $error");
    }
  }

  bool _isTVShowAddedToSelectedList() {
    // Check if the selected list contains the TV show ID
    if (_items.containsKey(_selectedList)) {
      List<dynamic>? tvShowsList = _items[_selectedList]?['list'];
      return tvShowsList != null && tvShowsList.contains(widget.tvShowID);
    }
    return false;
  }
  Color _getRatingColor(double rating) {
    if (rating >= 10.0) {
      return Colors.green.shade900;
    } else if (rating >= 7.0) {
      return const Color.fromARGB(255, 9, 151, 14);
    } else if (rating >= 5.0) {
      return Colors.yellow.shade600;
    } else if (rating >= 3.0) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade900;
    }
  }

}
