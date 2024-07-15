import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vixvox/TMDBapi/movie.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'package:vixvox/TMDBapi/tvshow.dart';

class ReviewDataLoader {
  final int? movieId;
  final int? tvshowId;
  final String documentId;

  Movie? movie;
  TVShow? tvShow;
  late Future<Map<String, dynamic>> _reviewAndUserDocumentFuture;
  


  ReviewDataLoader({this.movieId, this.tvshowId, required this.documentId}) {
    _initializeData();
    _reviewAndUserDocumentFuture = _initializeReviewAndUserDocument();
  }

    get datecreated => _reviewAndUserDocumentFuture.then((value) => value['review']['datecreated']);
  Future<void> _initializeData() async {
    if (movieId != null) {
      movie = await tmdb.TMDBApi().getMovie(movieId!);
    } else if (tvshowId != null) {
      tvShow = await tmdb.TMDBApi().getTVShow(tvshowId!);
    }
  }

  Future<Map<String, dynamic>> _initializeReviewAndUserDocument() async {
    final collectionName = movieId != null ? 'movies' : 'tv_shows';
    final documentRef = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(movieId != null ? movieId.toString() : tvshowId.toString())
        .collection('comments')
        .doc(documentId);

    final reviewSnapshot = await documentRef.get();

    if (!reviewSnapshot.exists) {
      throw Exception('Review not found');
    }

    final data = reviewSnapshot.data() as Map<String, dynamic>;
    final userId = data['userID'] as String;

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!userSnapshot.exists) {
      throw Exception('User not found');
    }

    return {
      'review': reviewSnapshot,
      'user': userSnapshot,
    };
  }

  Future<Map<String, dynamic>> get reviewAndUserDocument async {
    return await _reviewAndUserDocumentFuture;
  }

  Future<String?> getImageUrl(String userId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile/$userId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
   
      return null;
    }
  }

  String timeAgoSinceDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} years ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} months ago';
    } else if (diff.inDays > 7) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  String? getTMDBTitleWithYear() {
    try {
      if (movieId != null) {
        return movie?.titlewyear;
      } else if (tvshowId != null) {
        return tvShow?.titlewyear;
      }
    } catch (e) {
      return null;
    }
    return null;
   
  }

  Movie? getMedia() {
    return movie;
  }

  TVShow? getTVShow() {
    return tvShow;
  }
}
