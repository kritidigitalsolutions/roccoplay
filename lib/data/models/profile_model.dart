class Profile {
  String name;
  String avatar;
  bool isChildren;

  Profile({
    required this.name,
    required this.avatar,
    this.isChildren = false,
  });
}
