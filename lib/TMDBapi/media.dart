

class Media {
  final int id;
  final String title;
  final String genres;
  final String releaseDate;
  final String summary;
  final String posterUrl;
  final String? trailerUrl;
  final double voteAverage;
  final String? titlewyear;

  Media({
    required this.id,
    required this.title,
    required this.genres,
    required this.releaseDate,
    required this.summary,
    required this.posterUrl,
    this.trailerUrl,
    required this.voteAverage,
    required this.titlewyear,
  });


}
