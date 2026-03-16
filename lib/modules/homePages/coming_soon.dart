import 'package:flutter/material.dart';
import 'package:roccoplay/app/theme/app_colors.dart';

class ComingSoonSection extends StatelessWidget {
  final List<Map<String, String>> items;

  const ComingSoonSection({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔥 CLICKABLE TITLE (Coming Soon >)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () {
              // Navigator.push(
              //   context, MaterialPageRoute(builder:
              //     (context)=> detail_comingsoonPage()
              // ),
              // );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Coming Soon",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 15),

        /// 🔥 SLIDER
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Container(
                width: 170,
                margin: const EdgeInsets.only(right: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    print("image is Clicked");
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => ComingSoonDetailsPage(
                    //       image: items[index]["image"]!,
                    //       date: items[index]["date"]!,
                    //     ),
                    //   ),
                    // );
                  },
                  child: Stack(
                    children: [
                      /// Poster Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          items[index]["image"]!,
                          height: 250,
                          width: 170,
                          fit: BoxFit.cover,
                        ),
                      ),

                      /// 🔥 FULL WIDTH DATE LABEL
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              items[index]["date"]!,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
