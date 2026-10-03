import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../view_model/content_controller/content_controller.dart';
import 'cast_crewPage.dart';

class TopArtistsPage extends StatelessWidget {
  const TopArtistsPage({super.key});

  List<Cast> _getRealArtists() {
    if (!Get.isRegistered<ContentController>()) return [];
    final contentController = Get.find<ContentController>();
    final Map<String, Cast> uniqueArtists = {};

    for (final content in contentController.allContent) {
      if (content.cast != null) {
        for (final castMember in content.cast!) {
          final name = castMember.name.trim();
          if (name.isNotEmpty) {
            uniqueArtists.putIfAbsent(name.toLowerCase(), () => castMember);
          }
        }
      }
    }

    return uniqueArtists.values.toList();
  }

  Widget _buildArtistImage(String path) {
    final cleanPath = path.trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/user.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.person, color: Colors.white54, size: 32),
          ),
        ),
      );
    } else if (cleanPath.isNotEmpty && cleanPath.startsWith('assets/')) {
      return Image.asset(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.person, color: Colors.white54, size: 32),
        ),
      );
    }
    return Image.asset(
      'assets/images/user.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.person, color: Colors.white54, size: 32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final artists = _getRealArtists();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔹 Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Top Artists",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// 🔹 Grid Artists
            Expanded(
              child: artists.isEmpty
                  ? const Center(
                      child: Text(
                        "No Artists Found",
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: artists.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        final artist = artists[index];
                        final name = artist.name.trim();
                        final image = artist.image.trim();

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CastDetailsPage(
                                  castName: name,
                                  castImage: image,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildArtistImage(image),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
