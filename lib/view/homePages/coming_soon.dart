import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roccoplay/app/routes/app_routes.dart';
import 'package:roccoplay/app/theme/app_colors.dart';
import 'package:roccoplay/data/models/response_model/content_response_model/content_model.dart';

class ComingSoonSection extends StatelessWidget {
  final List<ContentModel> content;
  final bool isSignedIn;

  const ComingSoonSection({
    super.key,
    required this.content,
    required this.isSignedIn,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final bool isWeb = availableWidth > 800;

        double cardWidth;
        double cardHeight;

        if (isWeb) {
          cardWidth = (availableWidth / 5.8).clamp(180.0, 240.0);
        } else {
          if (content.length == 1) {
            cardWidth = (availableWidth * 0.58).clamp(180.0, 260.0);
          } else {
            // Shows 2 full cards and ~35% peek of the 3rd card
            cardWidth = ((availableWidth - 32 - (2 * 12)) / 2.35).clamp(135.0, 180.0);
          }
        }
        cardHeight = cardWidth * 1.45;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 CLICKABLE TITLE (Coming Soon >)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      "Coming Soon",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWeb ? 24 : 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 13,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// 🔥 RESPONSIVE CAROUSEL
            SizedBox(
              height: cardHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: content.length,
                itemBuilder: (context, index) {
                  final item = content[index];
                  return Container(
                    width: cardWidth,
                    height: cardHeight,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Get.toNamed(AppRoutes.dramaDetails, arguments: item);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            /// Poster Image
                            Image.network(
                              item.poster,
                              width: cardWidth,
                              height: cardHeight,
                              fit: BoxFit.cover,
                              cacheWidth: 350,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: cardWidth,
                                height: cardHeight,
                                color: Colors.grey[900],
                                child: const Icon(Icons.broken_image, color: Colors.white54, size: 36),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: cardWidth,
                                  height: cardHeight,
                                  color: Colors.grey[900],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.buttonColor,
                                    ),
                                  ),
                                );
                              },
                            ),

                            /// Gradient Scrim Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.2),
                                    Colors.black.withOpacity(0.88),
                                  ],
                                  stops: const [0.4, 0.68, 1.0],
                                ),
                              ),
                            ),

                            /// Date Badge & Title Overlay
                            Positioned(
                              bottom: 8,
                              left: 9,
                              right: 9,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  /// RoccoPlay Dark + Pink Date Pill Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.buttonColor.withOpacity(0.22),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.buttonColor.withOpacity(0.55),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 10,
                                          color: AppColors.buttonColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(item.releaseDate),
                                          style: const TextStyle(
                                            color: AppColors.buttonColor,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isWeb ? 13 : 11.5,
                                      fontWeight: FontWeight.bold,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black87,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// Subtle Border
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Coming Soon";
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        "Jan", "Feb", "March", "April", "May", "June",
        "July", "Aug", "Sept", "Oct", "Nov", "Dec"
      ];
      return "${date.day} ${months[date.month - 1]}";
    } catch (e) {
      return "Coming Soon";
    }
  }
}

