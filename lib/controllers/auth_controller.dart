import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tiktok_clone/constants.dart';
import 'package:tiktok_clone/models/user.dart' as model;

class AuthController extends GetxController {

  static AuthController instance = Get.find();

  Rx<File?>? _pickedIamge;

  File? get profilePhoto => _pickedIamge?.value;

  //==============PICK IMAGE=============================================
  void pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if(pickedImage != null) {
      cropImage(pickedImage.path);
      Get.snackbar("Photo de profile", "Photo de profile selectionné avec sucès");
    }

    _pickedIamge = Rx<File?> (File(pickedImage!.path));
  }
  //==============CROP IMAGE=============================================
   void cropImage(filePath) async {
    File? croppedImage = await ImageCropper().cropImage(
      sourcePath: filePath,
    );
    if (croppedImage != null) {
      _pickedIamge = Rx<File?> (File(croppedImage.path));
    }
  }
  //==============UPLOAD TO FIREBASE STORAGE=============================
  Future<String> _uploadToStorage(File image) async {
    Reference ref = firebaseStorage
        .ref()
        .child('profilPics')
        .child(firebaseAuth.currentUser!.uid);

    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snap = await uploadTask;
    String downloadUrl = await snap.ref.getDownloadURL();
    return downloadUrl;
  }

  //==============REGISTER USER==========================================
  void registerUser(
      String username, String email, String password, File? image) async {
    try {
      if (username.isNotEmpty &&
          email.isNotEmpty &&
          password.isNotEmpty &&
          image != null) {
        UserCredential cred =
            (await firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ));
        String downloadUrl = await _uploadToStorage(image);
        model.User user = model.User(
          name: username,
          profilePhoto: downloadUrl,
          email: email,
          uid: cred.user!.uid,
        );
        await fireStore
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toJson());
      } else {
        Get.snackbar(
          "Erreur création compte",
          "Veuillez completer toute les champs",
        );
      }
    } catch (e) {
      Get.snackbar(
        "Erreur création compte",
        e.toString(),
      );
    }
  }
}
