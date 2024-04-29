import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixvox/pages/moviemodel.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'package:shimmer/shimmer.dart';
import 'package:vixvox/pages/summary.dart';

class MovieDetailsWidget extends StatefulWidget {
  const MovieDetailsWidget({
    super.key,
    required this.movieID,
  });

  final int movieID;

  @override
  State<MovieDetailsWidget> createState() => _MovieDetailsWidgetState();
}

class _MovieDetailsWidgetState extends State<MovieDetailsWidget> {
  late MovieDetailsModel _model;
  late Map<String, dynamic> _items = {'0': {'name': 'My List', 'list': [1234, 5678]}};
  late bool add_button = false;
  late String _movieLength;
  late String _movieReleaseDate;
  late String _movieGenres;
  late String _movieName;
  late String _summary;
  late String _trailer;
  late String _moviePoster = ''; // Initialize with an empty string
  late Map<String, dynamic> _watchProviders = {};
  late double _rating = 0.0;
  late Color dominantColor = Colors.black;
  late Color darkVibrantColor = Colors.grey.shade900;
  final _cacheManager = DefaultCacheManager();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final bool _showAppBar = true;
  final String _countryCode = 'CA'; // Hardcoded country code for Canada

  late String _selectedList = '0'; // Selected wishlist from dropdown

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MovieDetailsModel());
    _buildDropdownItems();
    _fetchMovieDetails();
    _isMovieAddedToSelectedList();
  }

  Future<void> _fetchMovieDetails() async {
    _movieLength = await tmdb.TMDBApi().getMovieLength(widget.movieID) ?? '';
    _movieReleaseDate =
        await tmdb.TMDBApi().getMovieReleaseDate(widget.movieID) ?? '';
    _movieGenres = await tmdb.TMDBApi().getMovieGenres(widget.movieID) ?? '';
    _movieName = await tmdb.TMDBApi().getMovieTitle(widget.movieID) ?? '';
    _summary = await tmdb.TMDBApi().getMovieSummary(widget.movieID) ?? '';
    _trailer = await tmdb.TMDBApi().getMovieTrailer(widget.movieID) ?? '';

    final moviePoster = await tmdb.TMDBApi().getMoviePoster(widget.movieID);
    setState(() {
      _moviePoster = moviePoster;
    });

    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      FileImage(File(_moviePoster)),
    );

    setState(() {
      dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
      darkVibrantColor =
          paletteGenerator.darkVibrantColor?.color ?? dominantColor;
    });

    final providers = await tmdb.TMDBApi().getMovieWatchProviders(widget.movieID);
    setState(() {
      _watchProviders = providers["results"][_countryCode] ?? {};
    });

    final ratings = await tmdb.TMDBApi().getMovieRatings(widget.movieID);
    setState(() {
      _rating = ratings['averageRating'] ?? 0.0;
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle linkStyle = const TextStyle(color: Colors.blue);
    return Scaffold(
      key: scaffoldKey,
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
        child: NestedScrollView(
          headerSliverBuilder:
              (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: false, // App bar is not pinned
                floating:
                    true, // App bar becomes visible as soon as you scroll up
                snap: true, // App bar snaps into view when you scroll up quickly
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return FlexibleSpaceBar(
                      title: Text(
                        _movieName,
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  },
                ),
              ),
            ];
          },
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _moviePoster.isNotEmpty
                                  ? SizedBox(
                                      width: 150,
                                      height: 200,
                                      child: Image.file(File(_moviePoster)),
                                    )
                                  : Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        width: 150,
                                        height: 200,
                                        color: Colors.white,
                                      ),
                                    ), // Use a Placeholder widget or any other widget to indicate the absence of a poster
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Text(
                                _movieLength,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Text(
                                _movieReleaseDate,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Text(
                                _movieGenres,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                        ],
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
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: IconButton(
                              iconSize: 40,
                              icon: const Icon(Icons.play_arrow),
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
                            style: GoogleFonts.getFont(
                              'Roboto',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
Padding(
  padding: const EdgeInsets.all(15),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 200, // Provide a specific width
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<String>(
            hint: const Row(
              children: [
                Icon(
                  Icons.list,
                  size: 16,
                  color: Colors.yellow,
                ),
                SizedBox(
                  width: 4,
                ),
                Expanded(
                  child: Text(
                    'Select Wishlist',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            isExpanded: true,
            items: _items.entries
                .map((entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(
                        entry.value['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            value: _selectedList,
            onChanged: (value) {
              setState(() {
                _selectedList = value!;
                add_button = _isMovieAddedToSelectedList();
              });
            },
            buttonStyleData: ButtonStyleData(
              height: 50,
              width: 160,
              padding: const EdgeInsets.only(left: 14, right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black26,
                ),
                color: Colors.blueGrey.shade900, // Adjust color if needed
              ),
              elevation: 2,
            ),
            iconStyleData: const IconStyleData(
              icon: Icon(
                Icons.keyboard_arrow_down_rounded, // Change the arrow direction
              ),
              iconSize: 24,
              iconEnabledColor: Colors.white,
              iconDisabledColor: Colors.grey,
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200,
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.blueGrey.shade900, // Adjust color if needed
              ),
              scrollbarTheme: ScrollbarThemeData(
                radius: const Radius.circular(40),
                thickness: MaterialStateProperty.all(6),
                thumbVisibility: MaterialStateProperty.all(true),
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(
              height: 40,
              padding: EdgeInsets.only(left: 14, right: 14),
            ),
          ),
        ),
      ),
      IconButton(
  icon: Icon(
    add_button ? Icons.check : Icons.add,
  ),
  onPressed: () {
     setState(() {
    // Check if the movie is already added to the selected list
    if (_isMovieAddedToSelectedList()) {
      // Movie is added, remove it from the selected list
      removeMovieFromWishlist(_selectedList, widget.movieID);
      add_button = false;
    } else {
      // Movie is not added, add it to the selected list
      addMovieToWishlist(_selectedList, widget.movieID);
      add_button = true;
    }
   });
  },
  
)



    ],
  ),
),



                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary:',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white),
                          children: <TextSpan>[
                            TextSpan(
                              text: _summary.length <= 200
                                  ? _summary
                                  : '${_summary.substring(0, 200)}...',
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: ' Read more',
                              style: linkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SummaryPage(movieId: widget.movieID),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FutureBuilder<List<Map<String, String>>>(
                          future: tmdb.TMDBApi().getMovieCredits(widget.movieID),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              List<Map<String, String>> credits = snapshot.data ?? [];
                              return Row(
                                children: credits.map((credit) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Column(
                                      children: [
                                        ClipOval(
                                          child: CircleAvatar(
                                            radius: 40,
                                            backgroundImage: FileImage(File(credit['profilePic']!)),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          credit['name'] ?? '',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

Future<void> _buildDropdownItems() async {
  DocumentReference doc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

  // Check if the wishlist already exists
  DocumentSnapshot<Object?> wishlistSnapshot = await doc.get();

  Map<String, dynamic>? wishlistMap = wishlistSnapshot['wishlist'] as Map<String, dynamic>?;
  setState(() {
    _items = wishlistMap ?? {};
    _selectedList = _items.keys.first;
    add_button = _isMovieAddedToSelectedList();
  });

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

  Future<void> addMovieToWishlist(String listID, int movieId) async {
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



        List<dynamic> moviesList = wishlistMap[listID]['list'];

        // Check if the movieId already exists in the list
        if (!moviesList.contains(movieId)) {
          // Add the movieId to the movies list
          moviesList.add(movieId);
        }

        // Update the user document with the modified wishlist data
        transaction.update(doc, {'wishlist': wishlistMap});
        _items[_selectedList]?['list'].add(movieId);
        //_buildDropdownItems();
      }
    });
  } catch (error) {
    // Handle any errors that occur during the transaction
    print("Error adding movie to wishlist: $error");
  }
}
Future<void> removeMovieFromWishlist(String listID, int movieId) async {
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
          List<dynamic> moviesList = wishlistMap[listID]['list'];

          // Check if the movieId exists in the list
          if (moviesList.contains(movieId)) {
            // Remove the movieId from the movies list
            moviesList.remove(movieId);
          }

          // Update the user document with the modified wishlist data
          _items[_selectedList]?['list'].remove(movieId);
          transaction.update(doc, {'wishlist': wishlistMap});
          //_buildDropdownItems();
        }
      }
    });
  } catch (error) {
    // Handle any errors that occur during the transaction
    print("Error removing movie from wishlist: $error");
  }
}

  MovieDetailsModel createModel(BuildContext context, MovieDetailsModel Function() param1) {
    return MovieDetailsModel();
  }


bool _isMovieAddedToSelectedList() {
  // Check if the selected list contains the movie ID
  if (_items.containsKey(_selectedList)) {
    List<dynamic>? movieList = _items[_selectedList]?['list']; // Assuming 'list' key contains the movie list
    return movieList != null && movieList.contains(widget.movieID);
  }
  return false;
}

}
