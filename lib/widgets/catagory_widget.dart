import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../data/models/response_model/content_response_model/content_model.dart';
import '../view/dramaDetails/dramaDetailsPage.dart';

class CategoryGridPage extends StatelessWidget {
  final String title;
  final List<ContentModel> content;
  final bool isSignedIn;

  const CategoryGridPage({
    super.key,
    required this.title,
    required this.content,
    required this.isSignedIn,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 800;

    int crossAxisCount = screenWidth > 1200
        ? 7
        : screenWidth > 800
            ? 5
            : 3;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔙 BACK + TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWeb ? 26 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// 🔥 GRID IMAGES
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: content.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final item = content[index];
                  return _CategoryHoverItem(
                    item: item,
                    isSignedIn: isSignedIn,
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

class _CategoryHoverItem extends StatefulWidget {
  final ContentModel item;
  final bool isSignedIn;

  const _CategoryHoverItem({
    required this.item,
    required this.isSignedIn,
  });

  @override
  State<_CategoryHoverItem> createState() => _CategoryHoverItemState();
}

class _CategoryHoverItemState extends State<_CategoryHoverItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
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
            child: Image.network(
              widget.item.poster,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                "assets/images/farzi.jpg",
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
