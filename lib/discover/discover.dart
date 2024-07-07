import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vixvox/TMDBapi/media.dart';
import 'package:vixvox/TMDBapi/movie.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'package:vixvox/TMDBapi/tvshow.dart';
import 'package:vixvox/discover/firestoreservice.dart';
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
  List<Media> _movieTVShowResults = [];
  List<UserProfile> _userResults = [];
  bool _searchPerformed = false; // Track if search has been performed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _searchController,
              onFieldSubmitted: _onSearchChanged,
              decoration: const InputDecoration(
                labelText: 'Search Movies/TV Shows and Users',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2, // Number of tabs
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
          ),
        ],
      ),
    );
  }

Widget _buildMovieTVShowTab() {
  if (_movieTVShowResults.isEmpty) {
    return const Center(child: Text('No results found'));
  }
  return ListView.builder(
    itemCount: _movieTVShowResults.length,
    itemBuilder: (context, index) {
      final media = _movieTVShowResults[index];
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
          setState(() {
            _movieTVShowResults.removeAt(index);
          });
        },
      );
    },
  );
}


  Widget _buildUserTab() {
    if (_userResults.isEmpty) {
      return const Center(child: Text('No users found'));
    }
    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final userProfile = _userResults[index];
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
                builder: (context) => 
                
                Scaffold(
                  appBar: AppBar(
                    title: Text(userProfile.username),),
                body:
                ProfilePageWidget(userID: userProfile.userID)),
              ),
            );
          },
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    _searchMedia(query);
    _searchUsers(query);
    setState(() {
      _searchPerformed = true;
    });
  }

  void _searchMedia(String query) async {
    final results = await tmdb.TMDBApi().searchMedia(query);
    setState(() {
      _movieTVShowResults = results;
    });
  }

  void _searchUsers(String query) async {
    final usernameResults = await FirestoreService.searchUsersByUsername(query);
    final displayNameResults = await FirestoreService.searchUsersByDisplayName(query);
    final sortedResults = _sortUserResults(usernameResults, displayNameResults);
    setState(() {
      _userResults = sortedResults;
    });
  }

  List<UserProfile> _sortUserResults(List<UserProfile> usernames, List<UserProfile> displayNames) {
    Set<String> seenUsernames = Set();
    List<UserProfile> uniqueList = [];

    // Add usernames first
    for (UserProfile user in usernames) {
      if (!seenUsernames.contains(user.username)) {
        uniqueList.add(user);
        seenUsernames.add(user.username);
      }
    }

    // Add displayNames that are not already in the list
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



