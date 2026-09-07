import 'dart:typed_data';

class File {
  final String path;
  File(this.path);

  bool existsSync() => false;
  Uint8List readAsBytesSync() => Uint8List(0);
  Future<void> writeAsBytes(List<int> bytes) async {}
  void deleteSync() {}
}

class Directory {
  final String path;
  Directory(this.path);
}
