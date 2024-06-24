import 'package:flutter/material.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'package:vixvox/TMDBapi/movie.dart';

class SummaryPage extends StatefulWidget {
  final int movieId;

  const SummaryPage({super.key, required this.movieId});

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late Future<Movie> _movieDetailsFuture;

  @override
  void initState() {
    super.initState();
    _movieDetailsFuture = tmdb.TMDBApi().getMovie(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Summary'),
      ),);
}
}