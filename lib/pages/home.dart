import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vixvox/pages/movie_details.dart';
import 'package:vixvox/TMDBapi/tmdb.dart' as tmdb;

import 'homemodel.dart';
export 'home.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key, Key? customKey});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        body: SafeArea(
          top: true,
          child: ListView(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.vertical,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Align(
                    alignment: const AlignmentDirectional(-1, 0),
                    child: Container(
                      width: 55,
                      height: 55,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Image.network(
                        'https://picsum.photos/seed/315/600',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: AlignmentDirectional(0, 0),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(15, 0, 0, 0),
                      child: Text(
                        'Hello World',
                      ),
                    ),
                  ),
                  const Align(
                    alignment: AlignmentDirectional(0, 0),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(15, 0, 0, 0),
                      child: Text(
                        'Hello World',
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: const AlignmentDirectional(-1, -1),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 2, 5),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Your text here',
                              style: const TextStyle(color: Colors.black), // Add your text style here
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Your onTap logic here
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: const AlignmentDirectional(1, 0),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(3, 5, 5, 5),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          // Your onTap logic here
                        
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MovieDetailsWidget(
                                movieID: 299534,
                              ),
                            ),
                          );
                        },
                        child: FutureBuilder<String>(
                          future: tmdb.TMDBApi().getMoviePoster(299534),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return const Icon(Icons.error);
                            } else {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:  Image(
  image: NetworkImage(snapshot.data ?? ''),
  height: 200,
  fit: BoxFit.contain,
  alignment: Alignment.centerRight,
  errorBuilder: (context, error, stackTrace) {
    return Image.file(
      File(snapshot.data ?? ''),
      height: 200,
      fit: BoxFit.contain,
      alignment: Alignment.centerRight,
    );
  },
),

                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  HomePageModel createModel(BuildContext context, HomePageModel Function() param1) {
    // Add your code logic here
    return HomePageModel(); // Replace 'HomePageModel()' with your actual return value
  }
}
