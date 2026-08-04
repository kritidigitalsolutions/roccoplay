import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static Future<void> shareContent({
    required String title,
    required String slug,
    required String imageUrl,
  }) async {
    try {
      final String shareText = "Check out $title on RoccoPlay App 🎬🔥\n\n"
          "Watch here: https://roccoplay.in/content/$slug";

      if (imageUrl.isNotEmpty) {
        // Download image to temporary directory
        final response = await http.get(Uri.parse(imageUrl));
        final bytes = response.bodyBytes;

        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/share_image.png';
        final file = File(path);
        await file.writeAsBytes(bytes);

        // Share file with text
        await Share.shareXFiles(
          [XFile(path)],
          text: shareText,
        );
      } else {
        // Fallback to text only if no image
        await Share.share(shareText);
      }
    } catch (e) {
      print("Error sharing content: $e");
      // Fallback to text only on error
      await Share.share("Check out $title on RoccoPlay App 🎬🔥\n\n"
          "Watch here: https://roccoplay.in/content/$slug");
    }
  }
}
