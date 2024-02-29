
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vixvox/login/Sign_up.dart';
import 'package:vixvox/login/forgotpassword.dart';

import 'login_model.dart';
export 'login_model.dart';

class LoginWidget extends StatefulWidget {

  const LoginWidget({super.key});
  
  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  String _error = '';

  String verified = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());


    _model.emailAddressFocusNode ??= FocusNode();

  
    _model.passwordFocusNode ??= FocusNode();
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
        backgroundColor: Colors.white,
        body: SafeArea(
          top: true,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                flex: 8,
                child: Container(
                  width: 100,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  alignment: const AlignmentDirectional(0, -1),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 140,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              topLeft: Radius.circular(0),
                              topRight: Radius.circular(0),
                            ),
                          ),
                          alignment: const AlignmentDirectional(-1, 0),
                          child: Padding(
                            padding:
                                const EdgeInsetsDirectional.fromSTEB(32, 0, 0, 0),
                            child: Text(
                              'brand.ai',
                              style: GoogleFonts.plusJakartaSans(
                                textStyle: const TextStyle(
                                  color: Color(0xFF101213),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(0, 0),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: Color(0xFF101213),
                                    fontSize: 36,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0, 12, 0, 24),
                                  child: Text(
                                    'Let\'s get started by filling out the form below.',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Color(0xFF57636C),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (verified.isNotEmpty)
                                   Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  verified,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0, 0, 0, 16),
                                  child: SizedBox(
                                    width: 370,
                                    child: TextFormField(
                                      controller: _model.emailAddressController,
                                      focusNode: _model.emailAddressFocusNode,
                                       onTap: () {
    FocusScope.of(context).requestFocus(_model.emailAddressFocusNode);
  },
                                      autofocus: false,
                                      autofillHints: const [AutofillHints.email],
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        labelStyle: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: Color(0xFF57636C),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Color(0xFFF1F4F8),
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Color(0xFF4B39EF),
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE0E3E7),
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE0E3E7),
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF1F4F8),
                                      ),
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF101213),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                     

                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0, 0, 0, 16),
                                  child: SizedBox(
                                    width: 370,
                                    child: TextFormField(
                                      controller: _model.passwordController,
                                      focusNode: _model.passwordFocusNode,
                                      onTap: () {
    FocusScope.of(context).requestFocus(_model.passwordFocusNode);
  },
                                      autofocus: false,
                                      autofillHints: const [AutofillHints.password],
                                      
                                      obscureText: !_model.passwordVisibility,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: Color(0xFF57636C),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Color(0xFFF1F4F8),
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Color(0xFF4B39EF),
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE0E3E7),
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE0E3E7),
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF1F4F8),
                                        suffixIcon: InkWell(
                                          onTap: () => setState(
                                            () => _model.passwordVisibility =
                                                !_model.passwordVisibility,
                                          ),
                                          focusNode:
                                              FocusNode(skipTraversal: true),
                                          child: Icon(
                                            _model.passwordVisibility
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: const Color(0xFF57636C),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF101213),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      
                                    ),
                                  ),
                                ),
                                 if (_error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  _error,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 16, 16, 16),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      signin();
                                    },
                                    child: const Text('Login'),
                                  ),
                                ),
                                
                                if (verified.isNotEmpty)
                                 Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 16, 16, 16),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      FirebaseAuth.instance.currentUser?.sendEmailVerification();
                                    },
                                    child: const Text('Resend Verification Email'),
                                  ),
                                ), ]
                              ),
                                RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          text: 'Don\'t have an account? ',
                                        ),
                                        TextSpan(
                                          text: ' Sign Up here',
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            color: Color(0xFF4B39EF),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpWidget(),
                            ),
                          );
                                            },
                                        ),
                                      ],
                                    ), textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor),
                                  ),
                                Padding(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                child:
                               RichText(
                                    text: TextSpan(
                                          text: 'Forgot Password?',
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            color: Color(0xFF4B39EF),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordWidget(),
                            ),
                          );}))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: 100,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        image: const DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1514924013411-cbf25faa35bb?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1380&q=80',
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future signin() async {

   await FirebaseAuth.instance.currentUser?.reload();
        showDialog(context: context, barrierDismissible: false,builder: (context)=> const Center(child: CircularProgressIndicator()));
    try{
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: _model.emailAddressController.text.trim(), password: _model.passwordController.text.trim());  
    }
    on FirebaseAuthException catch(e){
      if (e.code == "INVALID_LOGIN_CREDENTIALS") {
          setState(() {
            _error = 'Wrong email or password.';
          });
      }
      

  }
  Navigator.pop(context); // Close the dialog
  if (!FirebaseAuth.instance.currentUser!.emailVerified) {
        setState(() {

        verified = "Please verify your email";
        
      });
  }
  
  }
  LoginModel createModel(BuildContext context, LoginModel Function() param1) {
    // Your code here
    return LoginModel(); // Replace with your implementation
  }
}
