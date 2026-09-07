import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) 'package:roccoplay/utils/io_stub.dart' as io;

class CreateProfileController extends GetxController {
  var selectedImage = Rxn<XFile>();
  var imageBytes = Rxn<Uint8List>();

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedImage.value = pickedFile;
      if (kIsWeb) {
        imageBytes.value = await pickedFile.readAsBytes();
      }
    }
  }
}
