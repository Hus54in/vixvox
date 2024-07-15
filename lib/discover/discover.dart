import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vixvox/TMDBapi/media.dart';
import 'package:vixvox/TMDBapi/movie.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'package:vixvox/TMDBapi/tvshow.dart';
import 'package:vixvox/discover/firestoreservice.dart';
import 'package:vixvox/discover/popular.dart';
import 'package:vixvox/profile/profile_page.dart';
import 'package:vixvox/show_details/movie_details.dart';
import 'package:vixvox/show_details/movielistdetails.dart';
import 'package:vixvox/show_details/tvShow_details.dart';

class DiscoverWidget extends StatefulWidget {
  const DiscoverWidget({Key? key}) : super(key: key);

  @override
  State<DiscoverWidget> createState() => _DiscoverWidgetState();
}

class _DiscoverWidgetState extends State<DiscoverWidget> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<List<Media>> _movieTVShowResults = ValueNotifier([]);
  final ValueNotifier<List<UserProfile>> _userResults = ValueNotifier([]);
  final ValueNotifier<List<String>> _suggestions = ValueNotifier([]);
  final ValueNotifier<bool> _searchPerformed = ValueNotifier(false);
  final ValueNotifier<bool> _isFocused = ValueNotifier(false);
  final FocusNode _focusNode = FocusNode();
  final PopularWidget _popularwidget = const PopularWidget();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _movieTVShowResults.dispose();
    _userResults.dispose();
    _suggestions.dispose();
    _searchPerformed.dispose();
    _isFocused.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: TextFormField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: 'Search',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                focusColor: Colors.white,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
              onTap: () {
                setState(() {
                                  _isFocused.value = true;
                _searchPerformed.value = false;
                });

              },
              onFieldSubmitted: (query) {
                setState(() {
                _isFocused.value = false;
                _focusNode.unfocus();
                _searchPerformed.value = true;
                _searchMedia(query);
                _searchUsers(query); });
              },
            ),
          
        ),
        leading: ValueListenableBuilder<bool>(
          valueListenable: _searchPerformed,
          builder: (context, searchPerformed, _) {
            return _searchPerformed.value || _isFocused.value
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () {
                      setState(() {
                        _searchPerformed.value = false;
                        _searchController.clear();
                        _movieTVShowResults.value.clear();
                        _suggestions.value.clear();
                        _userResults.value.clear();
                        _isFocused.value = false; // Defocus search field
                        _focusNode.unfocus();
                      });
                    },
                  )
                : const SizedBox.shrink();
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Visibility(
                visible: !_isFocused.value && !_searchPerformed.value,
                child: _popularwidget,
              ),
            
       
          ValueListenableBuilder<bool>(
            valueListenable: _isFocused,
            builder: (context, isFocused, _) {
              return isFocused ? _buildSuggestions() : Container();
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _searchPerformed,
            builder: (context, searchPerformed, _) {
              return searchPerformed
                  ? Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const TabBar(
                              tabs: [
                                Tab(text: 'Movies/TV Shows'),
                                Tab(text: 'Users'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildMovieTVShowTab(),
                                  _buildUserTab(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Expanded(
      child: ValueListenableBuilder<List<String>>(
        valueListenable: _suggestions,
        builder: (context, suggestions, _) {
          return ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(suggestions[index]),
                onTap: () {
                  _searchController.text = suggestions[index];
                  _onSearchChanged();
                  _isFocused.value = false;
                  _focusNode.unfocus();
                  _searchPerformed.value = true;
                  _searchMedia(suggestions[index]);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMovieTVShowTab() {
    return ValueListenableBuilder<List<Media>>(
      valueListenable: _movieTVShowResults,
      builder: (context, results, _) {
        if (results.isEmpty) {
          return const Center(child: Text('No results found'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final media = results[index];
            return MovieListItem(
              movie: media is Movie ? media : null,
              tvShow: media is TVShow ? media : null,
              onTap: () {
                if (media is Movie) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailsWidget(movieID: media.id),
                    ),
                  );
                } else if (media is TVShow) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TvShowDetailsWidget(tvShowId: media.id),
                    ),
                  );
                }
              },
              onDismissed: () {
                _movieTVShowResults.value.removeAt(index);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserTab() {
    return ValueListenableBuilder<List<UserProfile>>(
      valueListenable: _userResults,
      builder: (context, results, _) {
        if (results.isEmpty) {
          return const Center(child: Text('No users found'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final userProfile = results[index];
            return ListTile(
              leading: FutureBuilder<String?>(
                future: getImageUrl(userProfile.userID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircleAvatar(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return const CircleAvatar(
                      child: Icon(Icons.error),
                    );
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(snapshot.data!),
                    );
                  }
                  return const CircleAvatar(
                    child: Icon(Icons.person),
                  );
                },
              ),
              title: Text(userProfile.username),
              subtitle: Text(userProfile.displayName),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text(userProfile.username),
                      ),
                      body: ProfilePageWidget(userID: userProfile.userID),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (_isFocused.value) {
      _fetchSuggestions(query);
    } else {
      _searchMedia(query);
      _searchUsers(query);
      _searchPerformed.value = true;
    }
  }

  void _fetchSuggestions(String query) async {
    if (!_isFocused.value) {
      return;
    }
    final results = await tmdb.TMDBApi().searchMedia(query);
    List<String> suggestions = results.take(5).map((media) => media.title).toList();
    _suggestions.value = suggestions;
  }

  void _searchMedia(String query) async {
    final results = await tmdb.TMDBApi().searchMedia(query);
    _movieTVShowResults.value = results;
  }

  void _searchUsers(String query) async {
    final usernameResults = await FirestoreService.searchUsersByUsername(query);
    final displayNameResults = await FirestoreService.searchUsersByDisplayName(query);
    final sortedResults = _sortUserResults(usernameResults, displayNameResults);
    _userResults.value = sortedResults;
  }

  List<UserProfile> _sortUserResults(List<UserProfile> usernames, List<UserProfile> displayNames) {
    Set<String> seenUsernames = Set();
    List<UserProfile> uniqueList = [];

    for (UserProfile user in usernames) {
      if (!seenUsernames.contains(user.username)) {
        uniqueList.add(user);
        seenUsernames.add(user.username);
      }
    }

    for (UserProfile user in displayNames) {
      if (!seenUsernames.contains(user.username)) {
        uniqueList.add(user);
        seenUsernames.add(user.username);
      }
    }

    return uniqueList;
  }

  Future<String?> getImageUrl(String userid) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile/$userid.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
