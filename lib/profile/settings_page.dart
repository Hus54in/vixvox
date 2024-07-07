import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vixvox/profile/menu/menu.dart';
import 'package:vixvox/profile/profile_page.dart';

class SettingsPageWidget extends StatefulWidget {
  const SettingsPageWidget({Key? key}) : super(key: key);

  @override
  State<SettingsPageWidget> createState() => _SettingsPageWidgetState();
}

class _SettingsPageWidgetState extends State<SettingsPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  void selectImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? _file = await _picker.pickImage(source: ImageSource.gallery);
    if (_file != null) {
      final img = await _file.readAsBytes();
      final storageref = FirebaseStorage.instance
          .ref()
          .child('profile/${FirebaseAuth.instance.currentUser!.uid}.jpg');
      await storageref.putData(img);
      setState(() {}); // Refresh to show the new image
    }
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<String?> getUsername() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      return userDoc.data()?['username'] as String?;
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: FutureBuilder<String?>(
          future: getUsername(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(
                color: Colors.white,
              );
            } else if (snapshot.hasError) {
              return const Text(
                'Error loading username',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              );
            } else if (snapshot.hasData) {
              return Text(
                snapshot.data ?? "User Not Found",
                style: const TextStyle(
                  fontFamily: 'Urbanist',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              );
            } else {
              return const Text(
                'User Not Found',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const MenuPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutExpo;

                    final tween = Tween(begin: begin, end: end);
                    final curvedAnimation = CurvedAnimation(
                      parent: animation,
                      curve: curve,
                    );

                    return SlideTransition(
                      position: tween.animate(curvedAnimation),
                      child: child,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: ProfilePageWidget(userID: FirebaseAuth.instance.currentUser!.uid),
    );
  }
}
