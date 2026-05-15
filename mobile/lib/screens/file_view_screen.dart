import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FileViewScreen extends StatelessWidget {
  final String title;
  final String url;

  const FileViewScreen({super.key, required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: url,
            placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 50),
                SizedBox(height: 10),
                Text("Failed to load image", style: TextStyle(color: Colors.white)),
              ],
            ),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
