import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixvox/TMDBapi/cast.dart';
import 'package:vixvox/TMDBapi/movie.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:vixvox/TMDBapi/tmdb.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vixvox/pages/summary.dart';
import 'package:vixvox/show_details/discussion/discussion.dart';

class MovieDetailsWidget extends StatefulWidget {
  const MovieDetailsWidget({super.key, required this.movieID});

  final int movieID;

  @override
  State<MovieDetailsWidget> createState() => _MovieDetailsWidgetState();
}

class _MovieDetailsWidgetState extends State<MovieDetailsWidget> {
  Map<String, dynamic> _items = {'0': {'name': 'My List', 'list': [1234, 5678]}};
  bool addButton = false;
  Movie? _movie;
  String _selectedList = '0';
  Color dominantColor = Colors.black;
  Color darkVibrantColor = Colors.black;
  Map<String, dynamic> _watchProviders = {};
  List<Locale> systemLocales = [];
  String? _countryCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _buildDropdownItems();
    _fetchMovieDetails();
    systemLocales = WidgetsBinding.instance.window.locales;
    _countryCode = systemLocales.first.countryCode;
  }

  Future<void> _fetchMovieDetails() async {
    _movie = await TMDBApi().getMovie(widget.movieID);
    PaletteGenerator paletteGenerator = PaletteGenerator.fromColors([PaletteColor(Colors.blueGrey, 111)]);
    if (_movie!.posterUrl != null && _movie!.posterUrl.isNotEmpty) {
      paletteGenerator = await PaletteGenerator.fromImageProvider(NetworkImage(_movie!.posterUrl!));
    }
    setState(() {
      dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
      darkVibrantColor = paletteGenerator.darkVibrantColor?.color ?? dominantColor;
    });
    _watchProviders = await TMDBApi().getMovieWatchProviders(widget.movieID);
    setState(() {
      _watchProviders = _watchProviders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: dominantColor, 
        title: Text(
          _movie?.title ?? '',
          style: const TextStyle(fontSize: 20),
        ),
        leading: BackButton(color: Colors.white),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Details'),
            Tab(text: 'Discussion'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [dominantColor, darkVibrantColor, Colors.black],
            stops: const [0.0, 0.0, 0.7],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          children: [
            details(), DiscussionPage(movieID: widget.movieID)
        ] ))));
  
     } 

      

 Widget details()  {
  return SingleChildScrollView(
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
                                child: _movie?.posterUrl.isNotEmpty ?? false
                                          ? SizedBox(
                                              width: 150,
                                              height: 200,
                                              child: Image.network(_movie!.posterUrl),
                                            )
                                          : Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                width: 150,
                                                height: 200,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      _movie?.length ?? '',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      _movie?.releaseDate ?? '',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      _movie?.genres ?? '',
                                      style: const TextStyle(color: Colors.white),
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
                                    color: _getRatingColor(_movie?.voteAverage ?? 0.0),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${_movie?.voteAverage?.toStringAsFixed(1)}/10.0',
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
                                if (_movie?.trailerUrl != null && _movie!.trailerUrl!.isNotEmpty) {
                                  final bool nativeAppLaunchSucceeded = await launch(
                                    _movie!.trailerUrl!,
                                    universalLinksOnly: true,
                                    forceSafariVC: false,
                                    forceWebView: false,
                                  );

                                  if (!nativeAppLaunchSucceeded) {
                                    await launch(_movie!.trailerUrl!, forceSafariVC: true);
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
                        width: 200,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            hint: const Row(
                              children: [
                                Icon(
                                  Icons.list,
                                  size: 16,
                                  color: Colors.yellow,
                                ),
                                SizedBox(width: 4),
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
                            items: _items.entries.map((entry) {
                              return DropdownMenuItem<String>(
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
                              );
                            }).toList(),
                            value: _selectedList,
                            onChanged: (value) {
                              setState(() {
                                _selectedList = value!;
                                addButton = _isMovieAddedToSelectedList();
                              });
                            },
                            buttonStyleData: ButtonStyleData(
                              height: 50,
                              width: 160,
                              padding: const EdgeInsets.only(left: 14, right: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black26),
                                color: Colors.blueGrey.shade900,
                              ),
                              elevation: 2,
                            ),
                            iconStyleData: const IconStyleData(
                              icon: Icon(Icons.keyboard_arrow_down_rounded),
                              iconSize: 24,
                              iconEnabledColor: Colors.white,
                              iconDisabledColor: Colors.grey,
                            ),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 200,
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.blueGrey.shade900,
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
                          addButton ? Icons.check : Icons.add,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isMovieAddedToSelectedList()) {
                              removeMovieFromWishlist(_selectedList, widget.movieID);
                              addButton = false;
                            } else {
                              addMovieToWishlist(_selectedList, widget.movieID);
                              addButton = true;
                            }
                          });
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
                      ),                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${_movie!.summary.substring(0,200)}...',
                              style: const TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: ' Read more',
                              style: const TextStyle(color: Colors.blue),
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
                            children: _movie!.cast.map((credit) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  children: [
                                    ClipOval(
                                      child: CircleAvatar(
                                        radius: 40,
                                        backgroundImage: NetworkImage(
                                          'https://image.tmdb.org/t/p/w500${credit.profilePath}',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      credit.name,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                       
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
          );
 }

Future<void> _buildDropdownItems() async {
    DocumentReference doc = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);

    DocumentSnapshot<Object?> wishlistSnapshot = await doc.get();
    Map<String, dynamic>? wishlistMap = wishlistSnapshot['wishlist'] as Map<String, dynamic>?;

    setState(() {
      _items = wishlistMap ?? {};
      _selectedList = _items.keys.first;
      addButton = _isMovieAddedToSelectedList();
    });
  }

  List<Widget> _buildProviderWidgets() {
    List<Widget> widgets = [];

    _watchProviders.forEach((key, value) {
      if (key == _countryCode) {
        final providers = value as Map<String, dynamic>;
        providers.forEach((key, value) {
          if (key == 'flatrate') {
            final providerList = value as List<dynamic>;
            for (var provider in providerList) {
              final logoPath = provider['logo_path'];
              final providerName = provider['provider_name'];
              if (logoPath != null && providerName != null) {
                widgets.add(
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.network(
                              'https://image.tmdb.org/t/p/w92$logoPath',
                              width: 70,
                              height: 70,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            providerName,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          }
        });
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
      DocumentReference doc = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot<Object?> userSnapshot = await transaction.get(doc);

        if (userSnapshot.exists) {
          Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

          if (!userData.containsKey('wishlist')) {
            userData['wishlist'] = {};
          }

          Map<String, dynamic> wishlistMap = userData['wishlist'];
          List<dynamic> moviesList = wishlistMap[listID]['list'];

          if (!moviesList.contains(movieId)) {
            moviesList.add(movieId);
          }

          transaction.update(doc, {'wishlist': wishlistMap});
          _items[_selectedList]?['list'].add(movieId);
        }
      });
    } catch (error) {
      print("Error adding movie to wishlist: $error");
    }
  }

  Future<void> removeMovieFromWishlist(String listID, int movieId) async {
    try {
      DocumentReference doc = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);

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
            }

            transaction.update(doc, {'wishlist': wishlistMap});
            _items[_selectedList]?['list'].remove(movieId);
          }
        }
      });
    } catch (error) {
      print("Error removing movie from wishlist: $error");
    }
  }

  bool _isMovieAddedToSelectedList() {
    if (_items.containsKey(_selectedList)) {
      List<dynamic>? movieList = _items[_selectedList]?['list'];
      return movieList != null && movieList.contains(widget.movieID);
    }
    return false;
  }
}