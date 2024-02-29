import 'dart:async';
import 'dart:typed_data'; // Import Uint8List

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TMDBApi {
  final String apiKey = "a8db0646a23b7ea703e4c83a5ca720d1";
  final String baseUrl = 'https://api.themoviedb.org/3';
  final _cacheManager = DefaultCacheManager();

  Future<Map<String, dynamic>> _fetchData(String endpoint, {Map<String, dynamic>? params}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final key = '$endpoint?${params ?? {}}';
    final fileInfo = await _cacheManager.getFileFromCache(key);
    if (fileInfo != null && !fileInfo.validTill.isBefore(DateTime.now())) {
      // File exists in cache and is valid
      final jsonString = await fileInfo.file.readAsString();
      return json.decode(jsonString);
    }

    final response = await http.get(url.replace(queryParameters: {
      'api_key': apiKey,
      ...?params,
    }));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      await _cacheManager.putFile(
        key,
        utf8.encode(json.encode(jsonData)), // Storing encoded JSON data
        maxAge: const Duration(days: 7), // Example cache duration
      );
      return jsonData;
    } else {
      throw Exception('Failed to fetch data from TMDB API');
    }
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final endpoint = '/movie/$movieId';
    return await _fetchData(endpoint);
  }

  Future<Map<String, dynamic>> getTVShowDetails(int tvShowId) async {
    final endpoint = '/tv/$tvShowId';
    return await _fetchData(endpoint);
  }


  // Movie getters and setters
  Future<String> getMovieTitle(int movieId) async {
    final movieDetails = await getMovieDetails(movieId);
    return movieDetails['title'];
  }

  Future<String> getMovieLength(int movieId) async {
    final movieDetails = await getMovieDetails(movieId);
    int mins = movieDetails['runtime'];
    int hours = mins ~/ 60;
    int minutes = mins % 60;
    return '$hours hour $minutes mins';
  }

  Future<String> getMovieGenres(int movieId) async {
    final movieDetails = await getMovieDetails(movieId);
    final genres = movieDetails['genres'] as List<dynamic>;
    return genres.map((genre) => genre['name'].toString()).join(' • ');
  }

  Future<String> getMovieReleaseDate(int movieId) async {
  final movieDetails = await getMovieDetails(movieId);
  final releaseDate = DateTime.parse(movieDetails['release_date'].toString());
  final formattedReleaseDate = DateFormat('MMMM dd, yyyy').format(releaseDate);
  return formattedReleaseDate;
}

  Future<String> getMovieSummary(int movieId) async {
    final movieDetails = await getMovieDetails(movieId);
    return movieDetails['overview'];
  }

  Future<String> getMoviePoster(int movieId) async {
    final movieDetails = await getMovieDetails(movieId);
    final posterPath = movieDetails['poster_path'];
    final posterUrl = posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';
    return await _cacheImage(posterUrl);
  }


  // TV show getters and setters
  Future<String> getTVShowTitle(int tvShowId) async {
    final tvShowDetails = await getTVShowDetails(tvShowId);
    return tvShowDetails['name'];
  }

  Future<int> getTVShowLength(int tvShowId) async {
    final tvShowDetails = await getTVShowDetails(tvShowId);
    final episodeRuntime = tvShowDetails['episode_run_time'] as List<dynamic>;
    return episodeRuntime.isNotEmpty ? episodeRuntime[0] : 0;
  }

  Future<List<String>> getTVShowGenres(int tvShowId) async {
    final tvShowDetails = await getTVShowDetails(tvShowId);
    final genres = tvShowDetails['genres'] as List<dynamic>;
    return genres.map((genre) => genre['name'].toString()).toList();
  }

  Future<String> getTVShowReleaseDate(int tvShowId) async {
    final tvShowDetails = await getTVShowDetails(tvShowId);
    return tvShowDetails['first_air_date'];
  }

  Future<String> getTVShowSummary(int tvShowId) async {
    final tvShowDetails = await getTVShowDetails(tvShowId);
    return tvShowDetails['overview'];
  }

  Future<String> getTVShowPoster(int tvShowId) async {
    final tvShowDetails = await getTVShowDetails(tvShowId);
    final posterPath = tvShowDetails['poster_path'];
    return 'https://image.tmdb.org/t/p/original$posterPath';
  }

  Future<String?> getTrailer(int movieId) async {
    final endpoint = '/movie/$movieId/videos';
    final response = await _fetchData(endpoint);
  
    final results = response['results'] as List<dynamic>;
    final trailer = results.firstWhere(
      (result) => result['type'] == 'Trailer',
      orElse: () => null,
    );

    return trailer != null ? 'https://www.youtube.com/watch?v=${trailer['key']}' : null;
  }

  Future<List<Map<String, dynamic>>> getTrendingMovies() async {
    final endpoint = '/trending/movie/week';
    final response = await _fetchData(endpoint);
    final results = response['results'] as List<dynamic>;

    return results.map((result) {
      return {
        'id': result['id'],
        'title': result['title'],
        'poster': 'https://image.tmdb.org/t/p/original${result['poster_path']}',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTrendingTVShows() async {
    final endpoint = '/trending/tv/week';
    final response = await _fetchData(endpoint);
    final results = response['results'] as List<dynamic>;

    return results.map((result) {
      return {
        'id': result['id'],
        'title': result['name'],
        'poster': 'https://image.tmdb.org/t/p/original${result['poster_path']}',
      };
    }).toList();
  }

  Future<List<Map<String, String>>> getMovieCredits(int movieId) async {
  final endpoint = '/movie/$movieId/credits';
  final response = await _fetchData(endpoint);

  final cast = response['cast'] as List<dynamic>;
  final List<Map<String, String>> credits = [];

  for (final actor in cast.take(12)) {
    final profilePath = actor['profile_path'];
    final profilePicUrl = profilePath != null ? 'https://image.tmdb.org/t/p/w185$profilePath' : '';
    
    final cachedProfilePicUrl = await _cacheImage(profilePicUrl);
    credits.add({
      'name': actor['name'].toString(),
      'profilePic': cachedProfilePicUrl,
    });
  }

  return credits;
}

Future<String> _cacheImage(String imageUrl) async {
  if (imageUrl.isEmpty) {
    throw Exception('Empty image URL');
  }

  final key = imageUrl;
  final fileInfo = await _cacheManager.getFileFromCache(key);
  if (fileInfo != null && !fileInfo.validTill.isBefore(DateTime.now())) {
    // File exists in cache and is valid
    return fileInfo.file.path!;
  }

  final response = await http.get(Uri.parse(imageUrl));

  if (response.statusCode == 200) {
    // Compress the image
    final Uint8List compressedImage = await response.bodyBytes;

    await _cacheManager.putFile(
      key,
      compressedImage,
      maxAge: const Duration(days: 7), // Example cache duration
    );
    return fileInfo?.file.path ?? ''; // Use null-aware operator to access fileInfo.file.path
  } else {
    // Handle the case when the response status code is not 200
    throw Exception('Failed to load image: ${response.statusCode}');
  }
}






Future<List<Map<String, dynamic>>> searchMovies(String query) async {
  final response = await http.get(
    Uri.parse('https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final results = data['results'] as List;
    
    // Cache the entire response
    await _cacheManager.putFile(
      'search_$query', 
      utf8.encode(response.body), // Encode the response body to bytes
      maxAge: const Duration(days: 7), // Example cache duration
    );

    // Return a list of maps containing movie ID and name
    return results.map((result) {
      return {
        'id': result['id'] as int,
        'title': result['title'] as String,

      };
    }).toList();
  } else {
    throw Exception('Failed to search movies');
  }
}

  Future<Map<String, dynamic>> getMovieWatchProviders(int movieId) async {
    final endpoint = '/movie/$movieId/watch/providers';
    return await _fetchData(endpoint);
}
Future<Map<String, dynamic>> getMovieRatings(int movieId) async {
  final endpoint = '/movie/$movieId';
  final response = await _fetchData(endpoint);
  return {
    'averageRating': response['vote_average'],
    'voteCount': response['vote_count'],
  };
}

Future<Map<String, dynamic>> getCollectionDetails(int collectionId) async {
  final endpoint = '/collection/$collectionId';
  return await _fetchData(endpoint);
}

Future<String> getCollectionPoster(int collectionId) async {
  final collectionDetails = await getCollectionDetails(collectionId);
  final posterPath = collectionDetails['poster_path'];
  return 'https://image.tmdb.org/t/p/original$posterPath';
}

Future<String> getCollectionBackdrop(int collectionId) async {
  final collectionDetails = await getCollectionDetails(collectionId);
  final backdropPath = collectionDetails['backdrop_path'];
  return 'https://image.tmdb.org/t/p/original$backdropPath';
}

Future<Map<String, dynamic>> getProductionCompany(int companyId) async {
  final endpoint = '/company/$companyId';
  return await _fetchData(endpoint);
}

Future<int> getMovieBudget(int movieId) async {
  final movieDetails = await getMovieDetails(movieId);
  return movieDetails['budget'];
}

Future<int> getVoteCount(int movieId) async {
  final movieDetails = await getMovieDetails(movieId);
  return movieDetails['vote_count'];
}

  }