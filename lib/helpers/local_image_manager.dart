import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LocalImageManager {
  static Future<Directory> get _imageDirectory async {
    final docDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(docDir.path, "product_images"));

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    return imageDir;
  }

  static Future<String> saveImage(File pickedFile) async {
    try {
      final directory = await _imageDirectory;
      final extension = p.extension(pickedFile.path);
      final uniqueName =
          '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}$extension';
      final targetPath = p.join(directory.path, uniqueName);
      final savedFile = await pickedFile.copy(targetPath);

      return savedFile.path;
    } catch (e) {
      throw Exception("Error saving image: $e");
    }
  }

  static Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception("Error deleting image: $e");
    }
  }
}
