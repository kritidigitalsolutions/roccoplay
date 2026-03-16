import 'package:flutter/material.dart';
import 'package:roccoplay/modules/dramaDetails/dramaDetailsPage.dart';

import '../../app/theme/app_colors.dart';
import '../../widgets/catagory_widget.dart';

class Top10List extends StatelessWidget {
  final List<String> images;

  const Top10List({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔥 TOP 10 TITLE
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>CategoryGridPage(
                title: "Top 10",
                  items: [
                {
                  "image": "assets/images/sahid_teri_bato.jpg",
                  "title": "Movie 1"
                },
                {
                  "image": "assets/images/sahid_teri_bato.jpg",
                  "title": "Movie 2"
                },
                {
                  "image": "assets/images/sahid_teri_bato.jpg",
                  "title": "Movie 3"
                },
                {
                  "image": "assets/images/asur.webp",
                  "title": "Movie 4"
                },
                {
                  "image": "assets/images/asur.webp",
                  "title": "Movie 5"
                },
              ],
              ),
              ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Top 10",
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        /// 🔥 SLIDER
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length > 10 ? 10 : images.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  print("Clicked index: $index");

                  // Example: Navigate to details page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DramaDetailsPage(
                       isSignedIn: true,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 20),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        bottom: -10,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 150,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 1
                              ..color = Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),

                      /// Poster Image
                      Positioned(
                        left: 35,
                        top: 10,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            images[index],
                            width: 95,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

      ],
    );
  }
}
