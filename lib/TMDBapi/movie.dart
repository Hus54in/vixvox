import 'package:intl/intl.dart';
import 'package:vixvox/TMDBapi/cast.dart';
import 'package:vixvox/TMDBapi/media.dart';
import 'package:vixvox/TMDBapi/tmdb.dart';

class Movie extends Media {
  final String length;
  final int budget;
  final int voteCount;
  final double voteAverage;
  final List<Cast> cast;
  final Map<String, dynamic> watchProviders;

  

  Movie({
    required super.id,
    required super.title,
    required this.length,
    required super.genres,
    required super.releaseDate,
    required super.summary,
    required super.posterUrl,
    super.trailerUrl,
    required this.budget,
    required this.voteCount,
    required this.cast,
    this.watchProviders = const {},
    required this.voteAverage,
    required super.titlewyear,
  }) : super( voteAverage: 0.0);

  factory Movie.fromMap(Map<String, dynamic> map, {String? trailerUrl}) {
    return Movie(
      id: map['id'] as int, // Ensure id is an integer
      title: map['title'] ?? 'Unknown', // Provide default value if title is null
      length: _getMovieLength(map['runtime']),
      genres: _getMovieGenres(map),
      releaseDate: _getFormattedDate(map['release_date']),
      summary: map['overview'] ?? 'No summary available', // Provide default value if summary is null
      posterUrl: _getPosterUrl(map['poster_path']),
      trailerUrl: trailerUrl,
      budget: map['budget'] ?? 0, // Provide default value if budget is null
      voteAverage: map['vote_average']?.toDouble() ?? 0.0, // Ensure voteAverage is a double and provide default if null
      voteCount: map['vote_count'] ?? 0, // Provide default value if voteCount is null
      cast: [], // Initialize cast as an empty list
      watchProviders: map['watch/providers'] != null ? Map<String, dynamic>.from(map['watch/providers']) : {}, // Ensure watchProviders map is properly converted
      titlewyear: _gettitlewyear( map['title'], map['release_date']  ),

    );
  }

  static String _getMovieLength(int? runtime) {
    if (runtime == null) return '';
    int hours = runtime ~/ 60;
    int minutes = runtime % 60;
    return '$hours hour $minutes mins';
  }

  static String _getMovieGenres(Map<String,dynamic> genres) {
    if (genres['genres'] == null && genres['genre_ids'] != null){
      List<int> genreIds = List<int>.from(genres['genre_ids']);
    List<String> genreNames = genreIds.map((id) => TMDBApi().movieidtogenre(id) ?? "").toList();
    return genreNames.join(' • ');}
    else{
    return  genres['genres'].map((genre) => genre['name'].toString()).join(' • ');
    }
  }

  static String _getFormattedDate(String? date) {
    if (date == null || date.length == 0){ return 'N/A';}
    return DateFormat('MMMM dd, yyyy').format(DateTime.parse(date));
  }

  static String _getPosterUrl(String? posterPath) {
    return posterPath != null ? 'https://image.tmdb.org/t/p/w185$posterPath' : '';
  }

  static String _gettitlewyear(String title, String releaseDate) {
     if (releaseDate == null || releaseDate.isEmpty){ return '';}
    var date =  DateFormat('yyyy').format(DateTime.parse(releaseDate));
    return '$title ($date)';
  }
}
