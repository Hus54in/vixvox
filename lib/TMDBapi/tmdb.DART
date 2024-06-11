import 'dart:async';
import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:vixvox/TMDBapi/tvshow.dart';
import 'package:vixvox/TMDBapi/movie.dart';
import 'package:vixvox/TMDBapi/cast.dart';
import 'package:vixvox/TMDBapi/media.dart';
import 'dart:typed_data';

class TMDBApi {
  final String _apiKey = "a8db0646a23b7ea703e4c83a5ca720d1";
  final String _baseUrl = 'https://api.themoviedb.org/3';
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  Future<Map<String, dynamic>> _fetchData(String endpoint, {Map<String, dynamic>? params}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final key = '$endpoint?${params ?? {}}';
    final fileInfo = await _cacheManager.getFileFromCache(key);

    if (fileInfo != null && !fileInfo.validTill.isBefore(DateTime.now())) {
      final jsonString = await fileInfo.file.readAsString();
      return json.decode(jsonString);
    }

    final response = await http.get(url.replace(queryParameters: {
      'api_key': _apiKey,
      ...?params,
    }));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      await _cacheManager.putFile(key, Uint8List.fromList(utf8.encode(json.encode(jsonResponse))));
      return jsonResponse;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Movie> getMovie(int movieId) async {
    final response = await _fetchData('/movie/$movieId');
    final trailerResponse = await _fetchData('/movie/$movieId/videos');
    final trailerUrl = trailerResponse['results']?.firstWhere((video) => video['type'] == 'Trailer', orElse: () => null)?['key'];
    final cast = await getMovieCast(movieId);
    final watchProviders = await getMovieWatchProviders(movieId);

    return Movie.fromMap(response, trailerUrl: trailerUrl)
      ..cast.addAll(cast)
      ..watchProviders.addAll(watchProviders);
  }

  Future<List<Cast>> getMovieCast(int movieId) async {
  final response = await _fetchData('/movie/$movieId/credits');
  final castList = response['cast'] as List<dynamic>;



  return castList.map((json) => Cast.fromMap(json)).toList();
}


  Future<Map<String, dynamic>> getMovieWatchProviders(int movieId) async {
    final response = await _fetchData('/movie/$movieId/watch/providers');
    return response['results'] ?? {};
  }

  Future<TVShow> getTVShow(int tvShowId) async {
    final response = await _fetchData('/tv/$tvShowId');
    final trailerResponse = await _fetchData('/tv/$tvShowId/videos');
    final trailerUrl = trailerResponse['results']?.firstWhere((video) => video['type'] == 'Trailer', orElse: () => null)?['key'];
    final cast = await getTVShowCast(tvShowId);
    final watchProviders = await getTVShowWatchProviders(tvShowId);

    return TVShow.fromMap(response, trailerUrl: trailerUrl)
      ..cast.addAll(cast)
      ..watchProviders.addAll(watchProviders);
  }

  Future<List<Cast>> getTVShowCast(int tvShowId) async {
    final response = await _fetchData('/tv/$tvShowId/credits');
    final castList = response['cast'] as List<dynamic>;
    return castList.map((json) => Cast.fromMap(json)).toList();
  }

  Future<Map<String, dynamic>> getTVShowWatchProviders(int tvShowId) async {
    final response = await _fetchData('/tv/$tvShowId/watch/providers');
    return response['results'] ?? {};
  }

  Future<List<Media>> searchMedia(String query) async {
    final baseUrl = 'https://api.themoviedb.org/3/search/multi';
    final queryParams = {
      'api_key': _apiKey,
      'query': query,
    };

    final response = await http.get(Uri.parse('$baseUrl?${_mapToQueryParams(queryParams)}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'];

      List<Media> mediaList = [];
      for (var result in results) {
        if (result['media_type'] == 'movie') {
          mediaList.add(Movie.fromMap(result));
        } else if (result['media_type'] == 'tv') {
          mediaList.add(TVShow.fromMap(result));
        } else {
          throw Exception('Unsupported media type: ${result['media_type']}');
        }
      }

      return mediaList;
    } else {
      throw Exception('Failed to load media');
    }
  }

  

  String _mapToQueryParams(Map<String, dynamic> params) {
    return params.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
  }
}
