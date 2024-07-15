import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vixvox/TMDBapi/tvshow.dart';
import 'package:vixvox/TMDBapi/movie.dart';

class Tmdbdiscover {
  final String _apiKey = "a8db0646a23b7ea703e4c83a5ca720d1";
  final String _baseUrl = 'https://api.themoviedb.org/3';
  

  Future<List<Movie>> getTrendingMovies() async {
    print('searched');
    final url = '$_baseUrl/trending/movie/week?api_key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      Iterable list = jsonData['results'];
      return list.map((movieJson) => Movie.fromMap(movieJson)).toList();
    } else {
      throw Exception('Failed to load trending movies');
    }
  }

  Future<List<Movie>> getPopularMovies() async {
    final url = '$_baseUrl/movie/popular?api_key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      Iterable list = jsonData['results'];
      return list.map((movieJson) => Movie.fromMap(movieJson)).toList();
    } else {
      throw Exception('Failed to load popular movies');
    }
  }

  Future<List<Movie>> getUpcomingMovies() async {
    final url = '$_baseUrl/movie/upcoming?api_key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      Iterable list = jsonData['results'];
      return list.map((movieJson) => Movie.fromMap(movieJson)).toList();
    } else {
      throw Exception('Failed to load upcoming movies');
    }
  }

  Future<List<TVShow>> getTrendingTVShows() async {
    final url = '$_baseUrl/trending/tv/week?api_key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      Iterable list = jsonData['results'];
      return list.map((tvShowJson) => TVShow.fromMap(tvShowJson)).toList();
    } else {
      throw Exception('Failed to load trending TV shows');
    }
  }

  Future<List<TVShow>> getPopularTVShows() async {
    final url = '$_baseUrl/tv/popular?api_key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      Iterable list = jsonData['results'];
      return list.map((tvShowJson) => TVShow.fromMap(tvShowJson)).toList();
    } else {
      throw Exception('Failed to load popular TV shows');
    }
  }

  Future<List<TVShow>> getUpcomingTVShows() async {
    final url = '$_baseUrl/tv/on_the_air?api_key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      Iterable list = jsonData['results'];
      return list.map((tvShowJson) => TVShow.fromMap(tvShowJson)).toList();
    } else {
      throw Exception('Failed to load upcoming TV shows');
    }
  }

  Future<List<TVShow>> getTVShowsAiringToday() async {
    final url = '$_baseUrl/tv/airing_today?api_key=$_apiKey&language=en-US&page=1';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      Iterable list = jsonData['results'];
      return list.map((tvShowJson) => TVShow.fromMap(tvShowJson)).toList();
    } else {
      throw Exception('Failed to load TV shows airing today');
    }
  }

  Future<List<TVShow>> getTopRatedTVShows() async {
    final url = '$_baseUrl/tv/top_rated?api_key=$_apiKey&language=en-US&page=1';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      Iterable list = jsonData['results'];
      return list.map((tvShowJson) => TVShow.fromMap(tvShowJson)).toList();
    } else {
      throw Exception('Failed to load top rated TV shows');
    }
  }
}
