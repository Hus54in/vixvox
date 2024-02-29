import 'package:flutter/material.dart';

class SignUpModel  {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textvalidator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? emailController;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? passwordController;
  late bool passwordVisibemailController;
  String? Function(BuildContext, String?)? passwordControllervalidator;
  bool passwordVisibility = false;
  // State field(s) for CheckboxListTile widget.


  FocusNode? ConfirmPasswordFocusNode;
  TextEditingController? confirmpasswordController;
  late bool confirmpasswordVisibemailController;
  String? Function(BuildContext, String?)? confirmpasswordControllervalidator;
  bool? checkboxListTileValue;
  
  bool confirmpasswordVisibility = false;

  /// Initialization and disposal methods.
FocusNode? usernameFocusNode;
  TextEditingController? usernameController;



  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
    confirmpasswordVisibility = false;

  }

  @override
  void dispose() {
    unfocusNode.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    emailController?.dispose();

    textFieldFocusNode3?.dispose();
    passwordController?.dispose();

    ConfirmPasswordFocusNode?.dispose();
    confirmpasswordController?.dispose();

    usernameFocusNode?.dispose();
    usernameController?.dispose();
  }

 
}

