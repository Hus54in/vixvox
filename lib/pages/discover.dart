import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vixvox/TMDBapi/media.dart';
import 'package:vixvox/TMDBapi/movie.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'package:shimmer/shimmer.dart';
import '../show_details/movie_details.dart';

class DiscoverWidget extends StatefulWidget {
  const DiscoverWidget({super.key});

  @override
  State<DiscoverWidget> createState() => _DiscoverWidgetState();
}

class _DiscoverWidgetState extends State<DiscoverWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Media> _results = [];
  List<Media> _suggestions = [];
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
              padding: EdgeInsetsDirectional.fromSTEB(16, 0, 0, 0),
              child: Text('See trending movies and TV shows'),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onFieldSubmitted: _performSearch,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: 'Search Movies and TV Shows',
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
            if (_suggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
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
                ),
              )
            else
              Expanded(
                child: _results.isNotEmpty
                    ? ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          return _buildResultItem(_results[index]);
                        },
                      )
                    : Center(
                        child: Text('No results found'),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(Media media) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailsWidget(movieID: media.id ),
            ),
          );
        },
        child: Row(
          children: [
            FutureBuilder<String>(
              future: Future.value(media.posterUrl),
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
                          color: _getRatingColor(media.voteAverage),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          media.voteAverage.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      media is Movie
                          ? const Icon(
                              Icons.movie,
                              color: Colors.grey,
                              size: 18,
                            )
                          : const Icon(
                              Icons.tv,
                              color: Colors.grey,
                              size: 18,
                            ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    media.title,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<String>(
                    future: Future.value(media.releaseDate),
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
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchSuggestions(query);
      } else {
        setState(() {
          _suggestions = [];
          _results = [];
        });
      }
    });
  }

  void _searchSuggestions(String query) async {
    final suggestions = await tmdb.TMDBApi().searchMedia(query);
    setState(() {
      _suggestions = suggestions.take(5).toList();
    });
  }

  void _performSearch(String query) async {
    final results = await tmdb.TMDBApi().searchMedia(query);
    setState(() {
      _results = results;
      _suggestions = [];
    });
    FocusScope.of(context).unfocus();
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
