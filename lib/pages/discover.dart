import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import '../show_details/movie_details.dart'; // Import the movie details page
import 'package:shimmer/shimmer.dart'; // Import the shimmer package
export 'discover_model.dart';

class DiscoverWidget extends StatefulWidget {
  const DiscoverWidget({super.key});

  @override
  State<DiscoverWidget> createState() => _DiscoverWidgetState();
}

class _DiscoverWidgetState extends State<DiscoverWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // Remove the app bar
      body: SafeArea(
        top: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16, 0, 0, 0),
              child: Text('See trending movies'),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      onChanged: _searchMovies,
                      onFieldSubmitted: _searchOnSubmit, // Search when enter is pressed
                      textInputAction: TextInputAction.search, // Change enter button to search for iOS
                      decoration: InputDecoration(
                        labelText: 'Search Movies',
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _suggestions.isNotEmpty
                  ? ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: InkWell(
                            onTap: () {
                              _searchController.text = _suggestions[index]['title'];
                              _performSearch(_suggestions[index]['title']); // Perform search on suggestion click
                              // Clear suggestions list when a suggestion is tapped
                              setState(() {
                                _suggestions = [];
                              });
                            },
                            child: Text(_suggestions[index]['title']),
                          ),
                        );
                      },
                    )
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () async {
              final movieId = _searchResults[index]['id'];
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
                  future: _loadPoster(_searchResults[index]['id'], retryCount: 3), // Retry 3 times if loading fails
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
                    Text(
                      _searchResults[index]['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        
                      ),
                    ),
                    FutureBuilder<String>(
                      future: tmdb.TMDBApi().getMovieReleaseDate(_searchResults[index]['id']),
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

  void _searchMovies(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        final suggestions = await tmdb.TMDBApi().searchMovies(query);
        setState(() {
          _suggestions = suggestions.take(5).toList();
        });
      }
    });

    // Clear suggestions list if query is empty
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
    }
  }

  void _performSearch(String query) async {
    final results = await tmdb.TMDBApi().searchMovies(query);
    setState(() {
      _searchResults = results;
    });

    // Dismiss the keyboard after setting search results
    FocusScope.of(context).unfocus();
  }

  void _searchOnSubmit(String value) {
    _performSearch(value);
    setState(() {
      _suggestions = [];
    });
  }
}
