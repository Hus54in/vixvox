import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePageWidget extends StatefulWidget {
  const ProfilePageWidget({Key? key, required this.userID}) : super(key: key);
  final String userID;

  @override
  State<ProfilePageWidget> createState() => ProfilePageWidgetState();
}

class ProfilePageWidgetState extends State<ProfilePageWidget> {
  Future<String?> getImageUrl() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile/${widget.userID}.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting image URL: $e');
      return null;
    }
  }

  DocumentSnapshot? userDoc;

  @override
  void initState() {
    super.initState();
    getuserdata();
  }

  void getuserdata() async {
    try {
      final user = await FirebaseFirestore.instance.collection('users').doc(widget.userID).get();
      setState(() {
        userDoc = user;
      });
    } catch (e) {
      print('Error getting user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding ( 
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<String?>(
          future: getImageUrl(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading image'));
            } else if (snapshot.hasData) {
              return CircleAvatar(
                radius: 35,
                backgroundImage: CachedNetworkImageProvider(snapshot.data!),
              );
            } else {
              return CircleAvatar(
                radius: 35,
                backgroundImage: CachedNetworkImageProvider(
                    'https://avatar.iran.liara.run/username?username=${widget.userID}'),
              );
            }
          },
        ),
        const SizedBox(width: 20), // Add space between avatar and user name
        Expanded(
          child: Text(
            textAlign: TextAlign.center,
            userDoc?.get('displayName') ?? "User Name Not Found",
            style: const TextStyle(
              fontFamily: 'Urbanist',
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          )
        ),
      ],
    ));
  }
}
