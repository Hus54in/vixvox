

import 'package:flutter/material.dart';

class LoginModel {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // State field(s) for emailAddress widget.
  FocusNode? emailAddressFocusNode;
  final emailAddressController = TextEditingController();
  String? Function(BuildContext, String?)? emailAddressControllerValidator;
  // State field(s) for password widget.
  FocusNode? passwordFocusNode;
  final passwordController = TextEditingController();
  late bool passwordVisibility = false;
  String? Function(BuildContext, String?)? passwordControllerValidator;

  /// Initialization and disposal methods.

  

  @override
  void dispose() {
    unfocusNode.dispose();
    emailAddressFocusNode?.dispose();
    emailAddressController.dispose();

    passwordFocusNode?.dispose();
    passwordController.dispose();
  }

  /// Action blocks are added here.

  /// Additional helper methods are added here.
}
