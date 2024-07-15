import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vixvox/TMDBapi/movie.dart';
import 'package:vixvox/TMDBapi/tmdbdiscover.dart';
import 'package:vixvox/TMDBapi/tvshow.dart';
import 'package:vixvox/show_details/movie_details.dart';
import 'package:vixvox/show_details/tvShow_details.dart';

class PopularWidget extends StatefulWidget {
  const PopularWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PopularWidgetState createState() => _PopularWidgetState();
}

class _PopularWidgetState extends State<PopularWidget> {
  final Tmdbdiscover _tmdbdiscover = Tmdbdiscover();

  Widget _buildMediaList(String title, Future<List<dynamic>> futureMedia) {
    return FutureBuilder<List<dynamic>>(
      future: futureMedia,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no data
        } else {
          final List<dynamic> mediaList = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 275.0,
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: mediaList.length,
                  itemBuilder: (context, index) {
                    final dynamic media = mediaList[index];
                    String imageUrl = ''; // Placeholder for media image URL
                    String title = ''; // Placeholder for media title
                    String releaseDate = ''; // Placeholder for release date or year

                    if (media is Movie) {
                      imageUrl = media.posterUrl;
                      title = media.title;
                      releaseDate = media.releaseDate;
                    } else if (media is TVShow) {
                      imageUrl = media.posterUrl;
                      title = media.title; // Assuming 'name' is the title for TV shows
                      releaseDate = media.releaseDate;
                    }

                    return GestureDetector(
                      onTap: () {
                        if (media is Movie) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailsWidget(movie: media, movieID: media.id),
                            ),
                          );
                        } else if (media is TVShow) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TvShowDetailsWidget(tvShowId: media.id, tvshow: media),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 120.0, // Adjust width as per your design
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                placeholder: (context, url) => const Icon(Icons.movie),
                                errorWidget: (context, url, error) => const Icon(Icons.movie),
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    releaseDate,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(child:  ListView(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      cacheExtent: (10 * 275.0 )+ 300, 
      children: [
        SizedBox( height: 317, child:  _buildMediaList('Popular Movies', _fetchPopularMovies())),
         SizedBox( height: 317, child:  _buildMediaList('Popular TV Shows', _fetchPopulartvshow())),
         SizedBox( height: 317, child: _buildMediaList('Trending Movies', _fetchTrendingMovies())),
         SizedBox( height: 317, child: _buildMediaList('Trending TV Shows', _fetchTrendingtvshow())),
         SizedBox( height: 317, child: _buildMediaList('Upcoming Movies', _fetchUpcomingMovies())),
         SizedBox( height: 317, child: _buildMediaList('Upcoming TV Shows', _fetchUpcomingtvshow())),
         SizedBox( height: 317, child: _buildMediaList('TV Shows Airing Today', _fetchAiringTodaytvshow())),
      ],
    ));
  }

  Future<List<dynamic>> _fetchTrendingMovies() async {
    try {
      final List<Movie> trendingMovies = await _tmdbdiscover.getTrendingMovies();

      return trendingMovies;
    } catch (e) {
      print('Error fetching trending media: $e');
      return [];
    }
  }
    Future<List<dynamic>> _fetchTrendingtvshow() async {
    try {
  
      final List<TVShow> trendingTVShows = await _tmdbdiscover.getTrendingTVShows();
      return  trendingTVShows;
    } catch (e) {
      print('Error fetching trending media: $e');
      return [];
    }
  }

  Future<List<dynamic>> _fetchUpcomingMovies() async {
    try {
      final List<Movie> upcomingMovies = await _tmdbdiscover.getUpcomingMovies();

      return upcomingMovies;
    } catch (e) {
      print('Error fetching upcoming media: $e');
      return [];
    }
  }


    Future<List<dynamic>> _fetchUpcomingtvshow() async {
    try {

      final List<TVShow> upcomingTVShows = await _tmdbdiscover.getUpcomingTVShows();
      return  upcomingTVShows;
    } catch (e) {
      print('Error fetching upcoming media: $e');
      return [];
    }
  }

  Future<List<dynamic>> _fetchAiringTodaytvshow() async {
    try {
      final List<TVShow> airingTodayTVShows = await _tmdbdiscover.getTVShowsAiringToday();
      return airingTodayTVShows;
    } catch (e) {
      print('Error fetching airing today media: $e');
      return [];
    }
  }

    Future<List<dynamic>> _fetchPopularMovies() async {
    try {
      final List<Movie> popularMovies = await _tmdbdiscover.getPopularMovies();

      return popularMovies;
    } catch (e) {
      print('Error fetching popular media: $e');
      throw Exception('Failed to fetch popular media');
    }
  }

    Future<List<dynamic>> _fetchPopulartvshow() async {
    try {

      final List<TVShow> popularTVShows = await _tmdbdiscover.getPopularTVShows();
      return popularTVShows;
    } catch (e) {
      print('Error fetching popular media: $e');
      throw Exception('Failed to fetch popular media');
    }
  }

    bool get wantKeepAlive => true; // Override wantKeepAlive to true

}
