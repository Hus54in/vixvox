import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:flutter/material.dart';

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
  late List<DropdownMenuItem<String>> _items = [];

  late String _movieLength;
  late String _movieReleaseDate;
  late String _movieGenres;
  late String _movieName;
  late String _summary;
  late String _trailer;
  late String _moviePoster = ''; // Initialize with an empty string
  late Map<String, dynamic> _watchProviders = {};
  late double _rating = 0.0;
  late Color dominantColor;
  late Color darkVibrantColor;
  final _cacheManager = DefaultCacheManager();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final bool _showAppBar = true;
  final String _countryCode = 'CA'; // Hardcoded country code for Canada

  late String _selectedList = ''; // Selected wishlist from dropdown

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MovieDetailsModel());
    _fetchMovieDetails();
    _buildDropdownItems();
  }

  Future<void> _fetchMovieDetails() async {
    _movieLength = await tmdb.TMDBApi().getMovieLength(widget.movieID) ?? '';
    _movieReleaseDate =
        await tmdb.TMDBApi().getMovieReleaseDate(widget.movieID) ?? '';
    _movieGenres = await tmdb.TMDBApi().getMovieGenres(widget.movieID) ?? '';
    _movieName = await tmdb.TMDBApi().getMovieTitle(widget.movieID) ?? '';
    _summary = await tmdb.TMDBApi().getMovieSummary(widget.movieID) ?? '';
    _trailer = await tmdb.TMDBApi().getTrailer(widget.movieID) ?? '';

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
                        _movieName ?? '',
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
                            child: Text(
                              _movieLength,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              _movieReleaseDate,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              _movieGenres,
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
                      DropdownButton<String>(
                        value: _selectedList,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedList = newValue!;
                          });
                        },
                        items:  _items,
                        hint: Text(
                          'Select Wishlist',
                          style: TextStyle(color: Colors.white),
                        ),
                        dropdownColor: Colors.grey[800],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (_selectedList.isNotEmpty) {
                            addMovieToWishlist(_selectedList, widget.movieID);
                          } else {
                            



                              SnackBar(
                                content: Text('Please select a wishlist'),
                              );
                            
                          }
                        },
                      ),
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
  DocumentReference doc =
      FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

  // Check if the wishlist already exists
  DocumentSnapshot<Object?> wishlistSnapshot = await doc.get();

  Map<String, dynamic>? wishlistMap = wishlistSnapshot['wishlist'] as Map<String, dynamic>?;
  if (wishlistMap != null) {
    // Clear the existing items before adding new ones
    _items.clear();

    // Add a default item for no selection
    _items.add(
      DropdownMenuItem(
        value: '',
        child: Text(
          'Select Wishlist',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );

    // Iterate through each wishlist in Firebase and create a dropdown item
    wishlistMap.forEach((key, value) {
      // Append a timestamp to ensure uniqueness
      String uniqueValue = '$key-${DateTime.now().millisecondsSinceEpoch}';
      _items.add(
        DropdownMenuItem(
          value: uniqueValue,
          child: Text(
            key,
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    });
  }
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

  Future<void> addMovieToWishlist(String listName, int movieId) async {

    // Get a reference to the user's document
    DocumentReference doc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);
    // Check if the wishlist already exists
    DocumentSnapshot<Object?> wishlistSnapshot = await doc.get();
  if (wishlistSnapshot.exists && !(wishlistSnapshot.data() as Map).containsKey('wishlist')) {
  // Wishlist field exists
  // Now you can access the wishlist data
  await doc.set({'wishlist': {}}, SetOptions(merge: true));
} 
Map<String, dynamic>? wishlistMap = wishlistSnapshot['wishlist'] as Map<String, dynamic>?;
      print(wishlistMap);
      if (wishlistMap == null || !wishlistMap.containsKey(listName)) {
        await doc.set({'wishlist': {listName:[]}});
      } 
    
  List<dynamic>? moviesList = wishlistMap?[listName] as List<dynamic>?;
          print(moviesList);
          if (moviesList != null) {
            // Check if the movieId already exists in the list
            if (!moviesList.contains(movieId)) {
              // Add the movieId to the movies list

            wishlistMap?[listName].add(movieId);
            await doc.set({'wishlist': wishlistMap}, SetOptions(merge: true));
            }
          

}   

  } 
  MovieDetailsModel createModel(BuildContext context, MovieDetailsModel Function() param1) {
    return MovieDetailsModel();
  }
}
