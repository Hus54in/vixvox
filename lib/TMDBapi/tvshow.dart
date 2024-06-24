import 'package:intl/intl.dart';
import 'package:vixvox/TMDBapi/cast.dart';
import 'package:vixvox/TMDBapi/media.dart';

class TVShow extends Media {
  final String length;
  final List<Cast> cast;
  final Map<String, dynamic> watchProviders;

  TVShow({
    required super.id,
    required super.title,
    required this.length,
    required super.genres,
    required super.releaseDate,
    required super.summary,
    required super.posterUrl,
    super.trailerUrl,
    required this.cast,
    required this.watchProviders,
    required voteAverage,
  }) : super(
          voteAverage: voteAverage, // Use the provided voteAverage
        );

  factory TVShow.fromMap(Map<String, dynamic> map, {String? trailerUrl}) {
    

    return TVShow(
      id: map['id'] as int, // Ensure id is an integer
      title: map['name'] ?? 'Unknown', // Provide default value if title is null
      length: _getTVShowLength(map['number_of_seasons'], map['number_of_episodes']),
      genres: _getTVShowGenres(map),
      releaseDate: _getTVShowReleaseDate(map['first_air_date']),
      summary: map['overview'] ?? 'No summary available', // Provide default value if summary is null
      posterUrl: _getTVShowPoster(map['poster_path']),
      trailerUrl: trailerUrl,
      voteAverage: map['vote_average']?.toDouble() ?? 0.0, // Ensure voteAverage is a double and provide default if null
      cast: [], // Initialize cast as an empty list
      watchProviders: map['watch/providers'] != null ? Map<String, dynamic>.from(map['watch/providers']) : {}, // Ensure watchProviders map is properly converted
    );
  }

  static String _getTVShowLength(int? numberOfSeasons, int? numberOfEpisodes) {
    if (numberOfSeasons == null || numberOfEpisodes == null) return 'N/A';
    return '$numberOfSeasons Seasons • $numberOfEpisodes Episodes';
  }

  static String _getTVShowGenres(Map<String,dynamic> genres) {
    if (genres['genres'] == null ){
      return 'N/A';}
    else{
    return  genres['genres'].map((genre) => genre['name'].toString()).join(' • ');
    }
  }

  static String _getTVShowReleaseDate(String? releaseDate) {
    if (releaseDate == null) return 'N/A';
    return DateFormat('MMMM dd, yyyy').format(DateTime.parse(releaseDate));
  }

  static String _getTVShowPoster(String? posterPath) {
    return posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';
  }
}
