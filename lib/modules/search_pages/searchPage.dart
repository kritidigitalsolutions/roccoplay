import 'package:flutter/material.dart';
import 'package:roccoplay/widgets/catagory_widget.dart';
import 'package:roccoplay/modules/popUp/search_with_mic.dart';

import '../../app/theme/app_colors.dart';
import '../dramaDetails/cast_crewPage.dart';
import '../dramaDetails/dramaDetailsPage.dart';
import '../dramaDetails/topArtistpage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  final List<String> seriesImages = [
    "assets/images/taskaree.jpg",
    "assets/images/farzi.jpg",
    "assets/images/khaki.webp",
    "assets/images/kota_factory.jpg",
    "assets/images/asur.webp",
  ];

  final List<String> artistImages = [
    "assets/images/Shahid_Kapoor.jpg",
    "assets/images/srk.jpeg",
    "assets/images/alia.jpeg",
    "assets/images/katarina.jpeg",
    "assets/images/salman.jpeg",
    "assets/images/ranvir.jpg",
  ];
  final List<Map<String, String>> cast = [
    {'name': 'Shahid Kapoor', 'image': 'assets/images/Shahid_Kapoor.jpg'},
    {'name': 'Saru khan', 'image': 'assets/images/srk.jpeg'},
    {'name': 'Alia bhatta', 'image': 'assets/images/alia.jpeg'},
    {'name': 'Katarina', 'image': 'assets/images/katarina.jpeg'},
    {'name': 'Salman', 'image': 'assets/images/salman.jpeg'},
    {'name': 'Ranvir', 'image': 'assets/images/ranvir.jpg'},
  ];

  final List<Map<String, String>> trandSearch = [
    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
    {"image": "assets/images/asur.webp", "title": "Movie 2"},
    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
    {"image": "assets/images/asur.webp", "title": "Movie 4"},
    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 5"},
  ];

  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search for movies, shows & more",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[900],
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VoiceListeningPage(),
                      ),
                    );

                    if (result != null && result is String) {
                      _controller.text = result;
                      setState(() {});
                    }
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// SERIES SLIDER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: InkWell(
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => CategoryGridPage(
                //       title: "Top Series",
                //       items: trandSearch, content: [], isSignedIn: null,
                //     ),
                //   ),
                // );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Top series",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: seriesImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) =>
                      //         DramaDetailsPage(isSignedIn: true),
                      //   ),
                      // );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        seriesImages[index],
                        width: 170,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 25),

          /// TOP ARTISTS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=> TopArtistsPage()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Top Artists",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: artistImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CastDetailsPage(
                          castName: cast[index]['name']!,
                          castImage: cast[index]['image']!,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(cast[index]['image']!),
                              fit: BoxFit.cover,
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
