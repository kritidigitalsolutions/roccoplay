import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../app/theme/app_colors.dart';
import '../data/models/response_model/content_response_model/content_model.dart';

class HomeSliderSection extends StatelessWidget {
  final String title;
  final List<ContentModel> content;
  final bool isSignedIn;
  final bool isHorizontal;

  const HomeSliderSection({
    super.key,
    required this.title,
    required this.content,
    required this.isSignedIn,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final bool isWeb = availableWidth > 800;

        double posterWidth;
        double posterHeight;

        if (isHorizontal) {
          // 16:9 Banner Aspect Ratio (approx 1.78 : 1)
          if (isWeb) {
            posterWidth = (availableWidth / 3.4).clamp(300.0, 440.0);
          } else {
            if (content.length == 1) {
              posterWidth = (availableWidth - 32).clamp(240.0, 420.0);
            } else {
              // Shows 1 full card and ~32% peek of the second card
              posterWidth = ((availableWidth - 32 - 12) / 1.32).clamp(220.0, 320.0);
            }
          }
          posterHeight = posterWidth / 1.777;
        } else {
          // 2:3 Vertical Poster Aspect Ratio (approx 1 : 1.45)
          if (isWeb) {
            posterWidth = (availableWidth / 5.8).clamp(180.0, 240.0);
          } else {
            if (content.length == 1) {
              posterWidth = (availableWidth * 0.58).clamp(180.0, 260.0);
            } else {
              // Shows 2 full cards and ~35% peek of the third card
              posterWidth = ((availableWidth - 32 - (2 * 12)) / 2.35).clamp(135.0, 180.0);
            }
          }
          posterHeight = posterWidth * 1.45;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 CLICKABLE TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  Get.toNamed(
                    AppRoutes.categoryGrid,
                    arguments: {'title': title, 'content': content},
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
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
                      size: 13,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 🔥 SLIDER IMAGES (Responsive Carousel)
            SizedBox(
              height: posterHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: content.length,
                itemBuilder: (context, index) {
                  final item = content[index];
                  return _HoverItem(
                    item: item,
                    width: posterWidth,
                    height: posterHeight,
                    isSignedIn: isSignedIn,
                    useBanner: isHorizontal,
                    isWeb: isWeb,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HoverItem extends StatefulWidget {
  final ContentModel item;
  final double width;
  final double height;
  final bool isSignedIn;
  final bool useBanner;
  final bool isWeb;

  const _HoverItem({
    required this.item,
    required this.width,
    required this.height,
    required this.isSignedIn,
    required this.useBanner,
    required this.isWeb,
  });

  @override
  State<_HoverItem> createState() => _HoverItemState();
}

class _HoverItemState extends State<_HoverItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (widget.useBanner && widget.item.banner.isNotEmpty)
        ? widget.item.banner
        : (widget.item.poster.isNotEmpty
            ? widget.item.poster
            : widget.item.banner);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: widget.width,
          height: widget.height,
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
              Get.toNamed(
                AppRoutes.dramaDetails,
                arguments: widget.item,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  /// 1. Poster / Banner Image
                  Image.network(
                    imageUrl,
                    width: widget.width,
                    height: widget.height,
                    fit: BoxFit.cover,
                    cacheWidth: (widget.useBanner && widget.item.banner.isNotEmpty)
                        ? 600
                        : 350,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      "assets/images/farzi.jpg",
                      width: widget.width,
                      height: widget.height,
                      fit: BoxFit.cover,
                    ),
                  ),

                  /// 2. Gradient Scrim Overlay for contrast
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
                        stops: const [0.45, 0.72, 1.0],
                      ),
                    ),
                  ),

                  /// 3. Card Title and Metadata
                  Positioned(
                    bottom: 8,
                    left: 9,
                    right: 9,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.isWeb ? 13 : 11.5,
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
                        if (widget.item.category.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.item.category.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.buttonColor.withOpacity(0.9),
                              fontSize: widget.isWeb ? 11 : 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  /// 4. Subtle Border
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
        ),
      ),
    );
  }
}

