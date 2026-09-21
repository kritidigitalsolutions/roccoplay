import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../app/theme/app_colors.dart';

class Top10List extends StatelessWidget {
  final String title;
  final List<ContentModel> content;
  final bool isSignedIn;
  final bool isHorizontal;

  const Top10List({
    super.key,
    this.title = "Top 10",
    required this.content,
    required this.isSignedIn,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();

    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 800;

    double posterWidth = isWeb
        ? (isHorizontal ? 400 : 200)
        : (isHorizontal ? 210 : 110);
    double posterHeight = isWeb
        ? (isHorizontal ? 225 : 300)
        : (isHorizontal ? 120 : 160);
    double sectionHeight = isWeb
        ? (isHorizontal ? 255 : 330)
        : (isHorizontal ? 140 : 180);
    double numberSize = isWeb
        ? (isHorizontal ? 200 : 210)
        : (isHorizontal ? 110 : 110);
    double offsetLeft = isWeb
        ? (isHorizontal ? 85 : 75)
        : (isHorizontal ? 45 : 40);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔥 TOP 10 TITLE
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
                    color: AppColors.white,
                    fontSize: isWeb ? 26 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        /// 🔥 SLIDER
        SizedBox(
          height: sectionHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: content.length > 10 ? 10 : content.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final item = content[index];
              return _Top10HoverItem(
                item: item,
                index: index,
                posterWidth: posterWidth,
                posterHeight: posterHeight,
                numberSize: numberSize,
                offsetLeft: offsetLeft,
                isSignedIn: isSignedIn,
                useBanner: isHorizontal,
                isWeb: isWeb,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Top10HoverItem extends StatefulWidget {
  final ContentModel item;
  final int index;
  final double posterWidth;
  final double posterHeight;
  final double numberSize;
  final double offsetLeft;
  final bool isSignedIn;
  final bool useBanner;
  final bool isWeb;

  const _Top10HoverItem({
    required this.item,
    required this.index,
    required this.posterWidth,
    required this.posterHeight,
    required this.numberSize,
    required this.offsetLeft,
    required this.isSignedIn,
    required this.useBanner,
    required this.isWeb,
  });

  @override
  State<_Top10HoverItem> createState() => _Top10HoverItemState();
}

class _Top10HoverItemState extends State<_Top10HoverItem> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _blinkController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _blinkController.forward();
        }
      });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTwoDigit = (widget.index + 1) >= 10;
    final double effectiveOffset = isTwoDigit
        ? (widget.isWeb ? widget.offsetLeft * 1.6 : widget.offsetLeft * 1.6)
        : widget.offsetLeft;
    final double itemWidth = widget.posterWidth + effectiveOffset;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _blinkController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _blinkController.stop();
        _blinkController.reset();
      },
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: () {
            Get.toNamed(AppRoutes.dramaDetails, arguments: widget.item);
          },
          child: Container(
            width: itemWidth,
            height: widget.posterHeight,
            margin: const EdgeInsets.only(right: 18),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                /// 🔥 Big Rank Digit (1, 2, ... 10)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedBuilder(
                      animation: _blinkController,
                      builder: (context, child) {
                        final glowColor = Color.lerp(
                          Colors.white,
                          AppColors.buttonColor,
                          _blinkController.value,
                        );

                        return Text(
                          '${widget.index + 1}',
                          style: TextStyle(
                            fontSize: widget.numberSize,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            color: _isHovered ? glowColor : Colors.white,
                            letterSpacing: isTwoDigit ? -4 : -2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                              if (_isHovered) ...[
                                Shadow(
                                  color: AppColors.buttonColor.withValues(
                                    alpha: 0.6 * _blinkController.value,
                                  ),
                                  blurRadius: 20 * _blinkController.value,
                                ),
                                Shadow(
                                  color: AppColors.buttonColor.withValues(
                                    alpha: 0.4 * _blinkController.value,
                                  ),
                                  blurRadius: 40 * _blinkController.value,
                                ),
                              ],
                            ],

                          ),
                        );
                      },
                    ),
                  ),
                ),

                /// Poster Image
                Positioned(
                  left: effectiveOffset,
                  top: 0,
                  bottom: 0,
                  width: widget.posterWidth,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      (widget.useBanner && widget.item.banner.isNotEmpty)
                          ? widget.item.banner
                          : widget.item.poster,
                      width: widget.posterWidth,
                      height: widget.posterHeight,
                      fit: BoxFit.cover,
                      cacheWidth: (widget.useBanner && widget.item.banner.isNotEmpty) ? 600 : 350,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        "assets/images/farzi.jpg",
                        width: widget.posterWidth,
                        height: widget.posterHeight,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

