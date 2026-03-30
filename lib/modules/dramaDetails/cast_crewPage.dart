import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import 'dramaDetailsPage.dart';

class CastDetailsPage extends StatelessWidget {
  final String castName;
  final String castImage;

  const CastDetailsPage({
    super.key,
    required this.castName,
    required this.castImage,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 🔽 MAIN SCROLL CONTENT
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔥 25% HEIGHT IMAGE
                Container(
                  height: height * 0.25,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: (castImage.startsWith('http')) 
                        ? NetworkImage(castImage) 
                        : AssetImage(castImage) as ImageProvider,
                  ),
                ),

                const SizedBox(height: 10),

                /// 🔥 CAST NAME
                Center(
                  child: Text(
                    castName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Work History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                
                const Center(
                  child: Text(
                    "More movies/series coming soon",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          /// 🔙 BACK BUTTON (Fixed at top)
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }
}
