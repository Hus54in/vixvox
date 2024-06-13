import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:vixvox/TMDBapi/movie.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;
import 'package:palette_generator/palette_generator.dart';

class WriteAMovieReviewPage extends StatefulWidget {
  final int movieID;

  const WriteAMovieReviewPage({super.key, required this.movieID, required Movie movie});

  @override
  _WriteAMovieReviewPageState createState() => _WriteAMovieReviewPageState();
}

class _WriteAMovieReviewPageState extends State<WriteAMovieReviewPage> {
  late String _posterUrl = '';
  late String _title = '';
  late String _length = '';
  late String _releaseDate = '';
  late Color dominantColor = Colors.black;
  late Color darkVibrantColor = Colors.grey.shade900;
  bool _isLoading = true;
  double _value = 0.0;

  // Text field controller
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMovieDetails();
  }

  Future<void> _loadMovieDetails() async {
    try {
      final media = await tmdb.TMDBApi().getMovie(widget.movieID);
      _posterUrl = media.posterUrl;
      _title = media.title;
      _length =  media.length;
      _releaseDate = media.releaseDate;

      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(_posterUrl),
      );

      setState(() {
        dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
        darkVibrantColor = paletteGenerator.darkVibrantColor?.color ?? dominantColor;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      print('Error loading movie details: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        dominantColor,
                        darkVibrantColor,
                        Colors.black,
                      ],
                      stops: const [0.0, 0.0, 0.7],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: kToolbarHeight), // Height of AppBar
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Movie Poster
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(
                                    File(_posterUrl),
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
                                      // Movie Title
                                      Text(
                                        _title,
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      // Movie Length
                                      Text(
                                        _length,
                                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 8),
                                      // Release Date
                                      Text(
                                        _releaseDate,
                                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
      onVerticalDragStart: (details) {
        setState(() {
          _updateValue(details.localPosition.dy);
        });
      },
      onVerticalDragUpdate: (details) {
        setState(() {
          _updateValue(details.localPosition.dy);
        });
      },
      onVerticalDragEnd: (details) {
        // Reset or finalize any state as needed
      },
      child: Container(
        height: 50,
        width: 50,
        color: Colors.grey,
        child: 
            Text(
              _value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 20),
            
        ),
      ),
    ),
                          const SizedBox(height: 16),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child:
                            TextField(
                              controller: _reviewController,
                              decoration:  const InputDecoration(
                                hintText: 'Write your review here...',
                                border: InputBorder.none,
                                filled: true,
                                fillColor: Colors.black54 // Adjust the color according to your preference
                              ),
                              maxLines: 4,
                            ),),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    title: const Text('Write a Review'),
                    elevation: 0, // Remove shadow
                  ),
                ),
              ],
            ),
    );
  }
void _updateValue(double dy) {
  setState(() {
    // Adjust the sensitivity based on your preference
    double sensitivity = 0.1;
    
    // Calculate the change in value based on the vertical drag direction
    double change = dy * sensitivity;

    // Update the value based on the direction of the drag
    if (change > 0) {
      // Dragging down
      _value -= (change ~/ 0.5) * 0.5; // Round the change to the nearest 0.5
      _value = _value.clamp(0.0, 10.0); // Ensure the value stays within range
    } else {
      // Dragging up
      _value -= (change ~/ 0.5) * 0.5; // Round the change to the nearest 0.5
      _value = _value.clamp(0.0, 10.0); // Ensure the value stays within range
    }
  });
}




  @override
  void dispose() {
    // Dispose of the text controller when the widget is disposed
    _reviewController.dispose();
    super.dispose();
  }
}
