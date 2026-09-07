import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../app/theme/app_colors.dart';
import '../dramaDetails/dramaDetailsPage.dart';

class Top10List extends StatelessWidget {
  final List<ContentModel> content;
  final bool isSignedIn;
  final bool isHorizontal;

  const Top10List({
    super.key,
    required this.content,
    required this.isSignedIn,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();

    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 800;

    double posterWidth = isWeb ? (isHorizontal ? 420 : 200) : 95;
    double posterHeight = isWeb ? (isHorizontal ? 240 : 300) : 140;
    double sectionHeight = isWeb ? (isHorizontal ? 300 : 350) : 170;
    double numberSize = isWeb ? (isHorizontal ? 260 : 280) : 150;
    double offsetLeft = isWeb ? (isHorizontal ? 120 : 110) : 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔥 TOP 10 TITLE
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () {
              // Get.to(() => CategoryGridPage(
              //   title: "Top 10",
              //   content: content,
              //   isSignedIn: isSignedIn, items: [],
              // ));
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Top 10",
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
                useBanner: isWeb && isHorizontal,
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

  const _Top10HoverItem({
    required this.item,
    required this.index,
    required this.posterWidth,
    required this.posterHeight,
    required this.numberSize,
    required this.offsetLeft,
    required this.isSignedIn,
    required this.useBanner,
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
            width: widget.posterWidth + widget.offsetLeft,
            margin: const EdgeInsets.only(right: 20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                /// 🔥 Binking Glow Digit
                Positioned(
                  left: 0,
                  bottom: -15,
                  child: AnimatedBuilder(
                    animation: _blinkController,
                    builder: (context, child) {
                      final glowColor = Color.lerp(
                        Colors.white24,
                        AppColors.buttonColor.withOpacity(0.8),
                        _blinkController.value,
                      );

                      return Text(
                        '${widget.index + 1}',
                        style: TextStyle(
                          fontSize: widget.numberSize,
                          fontWeight: FontWeight.w900,
                          height: 0.9,
                          color: _isHovered ? glowColor : Colors.white,
                          shadows: _isHovered
                              ? [
                                  Shadow(
                                    color: AppColors.buttonColor.withOpacity(
                                      0.5 * _blinkController.value,
                                    ),
                                    blurRadius: 20 * _blinkController.value,
                                  ),
                                  Shadow(
                                    color: AppColors.buttonColor.withOpacity(
                                      0.3 * _blinkController.value,
                                    ),
                                    blurRadius: 40 * _blinkController.value,
                                  ),
                                ]
                              : [],
                        ),
                      );
                    },
                  ),
                ),

                /// Poster Image
                Positioned(
                  left: widget.offsetLeft,
                  top: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.useBanner ? widget.item.banner : widget.item.poster,
                      width: widget.posterWidth,
                      height: widget.posterHeight,
                      fit: BoxFit.cover,
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
