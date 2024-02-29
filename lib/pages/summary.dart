import 'package:flutter/material.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;

class SummaryPage extends StatefulWidget {
  final int movieId;

  const SummaryPage({super.key, required this.movieId});

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late Future<Map<String, dynamic>> _movieDetailsFuture;

  @override
  void initState() {
    super.initState();
    _movieDetailsFuture = tmdb.TMDBApi().getMovieDetails(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Summary'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _movieDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final movieDetails = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      movieDetails['overview'] ?? 'No summary available',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<Map<String, dynamic>>(
                    future: tmdb.TMDBApi().getMovieRatings(widget.movieId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        final ratings = snapshot.data!;
                        return Column(
                          children: [
                            Text('Budget: ${movieDetails['budget']}'),
                            Text('Revenue: ${movieDetails['revenue']}'),
                            const SizedBox(height: 20),
                            FutureBuilder<Map<String, dynamic>>(
                              future: tmdb.TMDBApi().getProductionCompany(movieDetails['production_companies'][0]['id']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                } else {
                                  final companyDetails = snapshot.data!;
                                  return Column(
                                    children: [
                                      Image.network(
                                        'https://image.tmdb.org/t/p/w200${companyDetails['logo_path']}',
                                        width: 100,
                                        height: 100,
                                      ),
                                      Text(
                                        companyDetails['name'],
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            FutureBuilder<String>(
                              future: tmdb.TMDBApi().getCollectionBackdrop(movieDetails['belongs_to_collection']['id']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                } else {
                                  return Image.network(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: FutureBuilder<String>(
                                    future: tmdb.TMDBApi().getMoviePoster(widget.movieId),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      } else if (snapshot.hasError) {
                                        return Center(child: Text('Error: ${snapshot.error}'));
                                      } else {
                                        return Image.network(
                                          snapshot.data!,
                                          width: 150,
                                          height: 200,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    color: Colors.black.withOpacity(0.7),
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          movieDetails['belongs_to_collection']['name'],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 18, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
