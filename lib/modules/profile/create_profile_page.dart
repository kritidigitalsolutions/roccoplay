import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() =>
      _CreateProfilePageState();
}

class _CreateProfilePageState
    extends State<CreateProfilePage> {
  final TextEditingController nameController =
  TextEditingController();

  bool isChildren = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 30),

            /// Profile Image
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person,
                  size: 50, color: Colors.white),
            ),

            TextButton(
              onPressed: () {},
              child: const Text(
                "Change Avatar",
                style: TextStyle(
                    color: AppColors.buttonColor),
              ),
            ),

            const SizedBox(height: 20),

            /// Name Field
            TextField(
              controller: nameController,
              style:
              const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: "Name",
                hintStyle:
                const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),

            const SizedBox(height: 15),

            /// Children Toggle
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Children",
                  style: TextStyle(
                      color: AppColors.white),
                ),
                Switch(
                  value: isChildren,
                  onChanged: (value) {
                    setState(() {
                      isChildren = value;
                    });
                  },
                )
              ],
            ),

            // const Spacer(),
            const SizedBox(height: 20),

            /// Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.grey),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                        "Cancel",
                      style: TextStyle(
                      color: AppColors.white,
                    ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                        AppColors.buttonColor),
                    onPressed: () {
                      Navigator.pop(
                          context, nameController.text);
                    },
                    child: const Text(
                      "Save",
                    style: TextStyle(
                      color: AppColors.white,
                    ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
