import 'package:flutter/material.dart';

import 'dramaDetailsPage.dart';

class CastDetailsPage extends StatelessWidget {
  final String castName;
  final String castImage;

  CastDetailsPage({
    super.key,
    required this.castName,
    required this.castImage,
  });

  final List<String> moviesList = [
    "assets/images/sahid_teri_bato.jpg",
    "assets/images/sahid_deva.jpg",
    "assets/images/kahid_bloody.webp",
  ];

  final List<String> seriesList = [
    "assets/images/asur2.jpeg",
    "assets/images/farzi.jpg",
    "assets/images/asur.webp",
  ];
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final bool isSignedIn;

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
                    backgroundImage: AssetImage(castImage),
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

                /// 🎬 MOVIES TITLE
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Movies",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// 🎬 MOVIES SLIDER
                SizedBox(
                  height: 170,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: moviesList.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DramaDetailsPage(
                                isSignedIn: true, // 🔥 or pass real login status
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              moviesList[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),


                const SizedBox(height: 25),

                /// 📺 SERIES TITLE
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Series",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// 📺 SERIES SLIDER
                SizedBox(
                  height: 170,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: seriesList.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DramaDetailsPage(
                                isSignedIn: true, // 🔥 pass login state here
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              seriesList[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
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
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
