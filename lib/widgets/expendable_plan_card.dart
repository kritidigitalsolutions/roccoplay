import 'package:flutter/material.dart';
import 'package:roccoplay/app/theme/app_colors.dart';

class ExpandablePlanCard extends StatefulWidget {
  final String title;
  final String price;
  final String duration;
  final bool isHighlighted;

  const ExpandablePlanCard({
    Key? key,
    required this.title,
    required this.price,
    required this.duration,
    this.isHighlighted = false,
  }) : super(key: key);

  @override
  State<ExpandablePlanCard> createState() => _ExpandablePlanCardState();
}

class _ExpandablePlanCardState extends State<ExpandablePlanCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: widget.isHighlighted
            ? Border.all(color: AppColors.buttonColor, width: 2)
            : null,
        gradient: isExpanded
            ? LinearGradient(
          colors: [
            AppColors.buttonColor.withOpacity(0.8),
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isExpanded ? null : Colors.grey[900],
      ),
      child: Column(
        children: [

          /// 🔥 Top Section
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Row(
                    children: [
                      Text(
                        "${widget.price}${widget.duration}",
                        style: TextStyle(
                          color: AppColors.buttonColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white,
                      )
                    ],
                  )
                ],
              ),
            ),
          ),

          /// 🔥 Expanded Section
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  /// Feature Row (4 boxes in one row)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      featureBox(Icons.lock, "All content access"),
                      // featureBox(Icons.devices, "watch on Any device"),
                      featureBox(Icons.block, "Ad-free Streaming"),
                      featureBox(Icons.sd, "SD Quality playback"),
                    ],
                  ),

                  SizedBox(height: 20),

                  /// Bullet Points
                  Column(
                    children: [

                      bulletText(
                        "Access to 3 Devices 5 Profiles",
                        alignment: MainAxisAlignment.start,
                      ),

                      bulletText(
                        "Cashback offers available",
                        alignment: MainAxisAlignment.center,
                      ),

                      bulletText(
                        "Watch in India + 236 Countries",
                        alignment: MainAxisAlignment.end,
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 🔹 Feature Icon Box
  Widget featureBox(IconData icon, String text) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(height: 6),
            Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 11),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  /// 🔹 Bullet Text
  Widget bulletText(String text,
      {MainAxisAlignment alignment = MainAxisAlignment.start}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start, // 🔥 important
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6), // 🔥 adjust bullet top
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
