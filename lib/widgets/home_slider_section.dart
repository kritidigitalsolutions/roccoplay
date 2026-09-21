import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
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

    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 800;

    double posterWidth = isWeb
        ? (isHorizontal ? 400 : 210)
        : (isHorizontal ? 240 : 135);
    double posterHeight = isWeb
        ? (isHorizontal ? 225 : 315)
        : (isHorizontal ? 135 : 195);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔥 CLICKABLE TITLE
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () {
              Get.toNamed(
                AppRoutes.categoryGrid,
                arguments: {'title': title, 'content': content},
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWeb ? 26 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.white),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        /// 🔥 SLIDER IMAGES
        SizedBox(
          height: posterHeight + (isWeb ? 20 : 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
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
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HoverItem extends StatefulWidget {
  final ContentModel item;
  final double width;
  final double height;
  final bool isSignedIn;
  final bool useBanner;

  const _HoverItem({
    required this.item,
    required this.width,
    required this.height,
    required this.isSignedIn,
    required this.useBanner,
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
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: widget.width,
          height: widget.height,
          margin: const EdgeInsets.only(right: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Get.toNamed(
                AppRoutes.dramaDetails,
                arguments: widget.item,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.cover,
                cacheWidth: (widget.useBanner && widget.item.banner.isNotEmpty) ? 600 : 350,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  "assets/images/farzi.jpg",
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

