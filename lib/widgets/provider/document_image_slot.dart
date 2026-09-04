import 'dart:io';

import 'package:flutter/material.dart';

/// A tappable image preview box used for picking/replacing a provider
/// verification document (profile photo, CNIC front/back). Shows, in order
/// of precedence: a freshly picked local [file], an existing [networkUrl],
/// or a placeholder prompting the user to add one.
class DocumentImageSlot extends StatelessWidget {
  final File? file;
  final String? networkUrl;
  final IconData placeholderIcon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const DocumentImageSlot({
    super.key,
    required this.file,
    this.networkUrl,
    required this.placeholderIcon,
    required this.label,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocalFile = file != null;
    final hasNetworkImage = !hasLocalFile && networkUrl != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasLocalFile
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(file!, fit: BoxFit.cover),
                  if (onRemove != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onRemove,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : hasNetworkImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        networkUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.broken_image_outlined,
                                color: Colors.black38, size: 28),
                            SizedBox(height: 6),
                            Text('Could not load image',
                                style: TextStyle(
                                    color: Colors.black45, fontSize: 12)),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.black45,
                          child: const Text(
                            'Tap to change',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(placeholderIcon, color: Colors.black38, size: 32),
                      const SizedBox(height: 8),
                      Text(label,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13)),
                    ],
                  ),
      ),
    );
  }
}
