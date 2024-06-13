import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vixvox/TMDBapi/media.dart';
import 'package:vixvox/TMDBapi/movie.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'package:shimmer/shimmer.dart';
import 'package:vixvox/TMDBapi/tvshow.dart';

import '../show_details/movie_details.dart';


class CreatePageWidget extends StatefulWidget {
  const CreatePageWidget({super.key});

  @override
  State<CreatePageWidget> createState() => _CreatePageWidgetState();
}

class _CreatePageWidgetState extends State<CreatePageWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Media> _suggestions = [];
  List<Media> _searchResults = [];
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        top: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Text(
                'Write a Review',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      onChanged: _searchMedia,
                      onFieldSubmitted: _searchOnSubmit,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: 'Search Movies and TV Shows',
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(width: 2),
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
                              _searchController.text = _suggestions[index].title;
                              _performSearch(_suggestions[index].title);
                              setState(() {
                                _suggestions = [];
                              });
                            },
                            child: Text(_suggestions[index].title),
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
        final Media searchResult = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () async {
              final int mediaId = searchResult.id as int;
              if (searchResult is Movie) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailsWidget(movieID: mediaId),
                  ),
                );
              }
            },
            child: Row(
              children: [
                FutureBuilder<String>(
                  future: Future.value(searchResult.posterUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        snapshot.connectionState == ConnectionState.none) {
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
                        child: Image.network(
                          snapshot.data!,
                          width: 100,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _getRatingColor(double.parse(searchResult.voteAverage.toString())),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                searchResult.voteAverage.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (searchResult is Movie)
                            const Icon(
                              Icons.movie,
                              color: Colors.grey,
                              size: 18,
                            ),
                          if (searchResult is TVShow)
                            const Icon(
                              Icons.tv,
                              color: Colors.grey,
                              size: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        searchResult.title,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<String>(
                        future: _getReleaseDate(searchResult.releaseDate),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return const Text('Release Date Error');
                          } else {
                            return Text(
                              snapshot.data ?? 'Release Date not available',
                              softWrap: true,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _searchMedia(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        final suggestions = await tmdb.TMDBApi().searchMedia(query);
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
    final results = await tmdb.TMDBApi().searchMedia(query);
    setState(() {
      _searchResults = results;
    });

    // Dismiss the keyboard after setting search results
    // ignore: use_build_context_synchronously
    FocusScope.of(context).unfocus();
  }

  void _searchOnSubmit(String value) {
    _performSearch(value);
    setState(() {
      _suggestions = [];
    });
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

  Future<String> _getPoster(String? posterPath) async {
    if (posterPath != null) {
      return 'https://image.tmdb.org/t/p/w500$posterPath';
    }
    return '';
  }

  Future<String> _getReleaseDate(String? releaseDate) async {
    return releaseDate ?? 'Release Date not available';
  }
}

