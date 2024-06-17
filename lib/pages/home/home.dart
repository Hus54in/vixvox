import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vixvox/TMDBapi/movie.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'package:vixvox/show_details/movie_details.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key, Key? customKey});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final int movieId = 299534; // Example movie ID
  late Future<Movie> _movieFuture;

  @override
  void initState() {
    super.initState();
    _movieFuture = _fetchMovie();
  }

  Future<Movie> _fetchMovie() async {
    return await tmdb.TMDBApi().getMovie(movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Text('Changes UnderWay');
  }
}
