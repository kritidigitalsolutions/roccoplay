import 'package:flutter/material.dart';
import 'package:roccoplay/data/providers/privacy_provider.dart';
import '../../app/theme/app_colors.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {

  List helpList = [];
  bool isLoading = true;

  /// track which item is open
  int? openIndex;

  @override
  void initState() {
    super.initState();
    fetchHelp();
  }

  void fetchHelp() async {
    final data = await PrivacyService.getHelpData();
    print("FINAL DATA: $data");

    setState(() {
      helpList = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Help & Support",
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text(
            "How can we help you?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),

          const SizedBox(height: 20),

          /// 🔥 Dynamic List
          ...List.generate(helpList.length, (index) {
            final item = helpList[index];
            final isOpen = openIndex == index;

            return Column(
              children: [

                /// TOP TILE (same UI)
                _helpItem(
                  icon: Icons.help_outline,
                  title: item['category'] ?? "",
                  subtitle: "Tap to view details",
                  isOpen: isOpen,
                  onTap: () {
                    setState(() {
                      openIndex = isOpen ? null : index;
                    });
                  },
                ),

                /// 🔥 SLIDE OPEN PART
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isOpen ? null : 0,
                  curve: Curves.easeInOut,
                  child: isOpen
                      ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// QUESTION
                        Text(
                          item['question'] ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        /// ANSWER
                        Text(
                          item['answer'] ?? "",
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  )
                      : const SizedBox(),
                ),
              ],
            );
          }),

          const SizedBox(height: 30),
          const Divider(color: Colors.white24),

          const SizedBox(height: 20),

          const Text(
            "Need more help?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Email: support@roccoplay.com",
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 5),

          const Text(
            "Response time: within 24 hours",
            style: TextStyle(color: Colors.white54),
          ),

          const SizedBox(height: 30),

          const Center(
            child: Text(
              "© 2026 RoccoPlay",
              style: TextStyle(color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  /// SAME UI TILE
  Widget _helpItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isOpen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.buttonColor),

        /// 🔥 CATEGORY SHOW
        title: Text(
          title,
          style: const TextStyle(color: AppColors.white),
        ),

        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.white),
        ),

        trailing: Icon(
          isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: AppColors.white,
        ),

        onTap: onTap,
      ),
    );
  }
}
