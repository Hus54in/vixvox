import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<String?> getImageUrl() async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile/${FirebaseAuth.instance.currentUser!.uid}.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting image URL: $e');
      return null;
    }
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: Colors.black,
          endDrawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    _signOut();
                    Navigator.pop(context); // Close the drawer
                  },
                ),
              ],
            ),
          ),
          body: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
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
                          backgroundImage: NetworkImage(
                              'https://avatar.iran.liara.run/username?username=${user.displayName}'),
                        );
                      }
                    },
                  ),
                  Positioned(
                    bottom: -13,
                    left: 60,
                    child: IconButton(
                      onPressed: selectImage,
                      icon: const Icon(Icons.edit),
                      iconSize: 30,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20), // Add space between avatar and user name
              Expanded(
                child: Text(
                  user.displayName ?? "User Name Not Found",
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  scaffoldKey.currentState!.openEndDrawer();
                },
                icon: const Icon(Icons.menu, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
