import 'package:flutter/material.dart';
import 'package:vixvox/TMDBapi/tvshow.dart';
import '../TMDBapi/movie.dart';

class MovieListItem extends StatelessWidget {
  final Movie? movie;
  final TVShow? tvShow;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  const MovieListItem({
    Key? key,
    this.movie,
    this.tvShow,
    required this.onDismissed,
    required this.onTap,
  }) : super(key: key);

  Color _getRatingColor(double rating) {
    if (rating >= 10.0) {
      return Colors.green.shade900;
    } else if (rating >= 7.0) {
      return const Color.fromARGB(255, 9, 151, 14);
    } else if (rating >= 5.0) {
      return Colors.yellow.shade600;
    } else if (rating >= 3.0) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      onDismissed: (direction) => onDismissed(),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  movie?.posterUrl ?? tvShow?.posterUrl ?? '',
                  width: 100,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row (
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [ Expanded( child: Text(
                      movie?.titlewyear ?? tvShow?.titlewyear ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )),  Icon((movie != null) ? Icons.movie_creation_outlined : Icons.tv , color: Colors.grey, size: 20,)],
                    ),
                    Text(
                      movie?.genres ?? tvShow?.genres ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${(movie?.length ?? tvShow?.length ?? '').isNotEmpty ? '${movie?.length ?? tvShow?.length} • ' : ''}${movie?.voteAverage ?? tvShow?.voteAverage ?? ''} ⭐',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
