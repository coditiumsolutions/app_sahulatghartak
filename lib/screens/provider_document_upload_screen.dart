import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/provider_document_provider.dart';
import '../utils/constants.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/provider/document_image_slot.dart';
import 'provider_dashboard_screen.dart';

class ProviderDocumentUploadArgs {
  final int providerUid;
  const ProviderDocumentUploadArgs({required this.providerUid});
}

class ProviderDocumentUploadScreen extends StatefulWidget {
  static const routeName = '/provider-document-upload';
  const ProviderDocumentUploadScreen({Key? key}) : super(key: key);

  @override
  State<ProviderDocumentUploadScreen> createState() => _ProviderDocumentUploadScreenState();
}

class _ProviderDocumentUploadScreenState extends State<ProviderDocumentUploadScreen> {
  ProviderDocumentUploadArgs? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??= ModalRoute.of(context)!.settings.arguments as ProviderDocumentUploadArgs;
  }

  Future<void> _pickImage(ProviderDocumentSlot slot) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Text('Select Image Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: kPrimaryColor),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: kPrimaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final provider = context.read<ProviderDocumentProvider>();
    await provider.pickImage(slot, source);

    if (!mounted) return;
    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  Future<void> _upload() async {
    final provider = context.read<ProviderDocumentProvider>();
    final success = await provider.upload(_args!.providerUid);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documents uploaded successfully.')));
      Navigator.of(context).pushNamedAndRemoveUntil(ProviderDashboardScreen.routeName, (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to upload documents')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderDocumentProvider>();

    return AuthCardScaffold(
      title: 'Verify Your Identity',
      subtitle: 'Upload your profile photo and CNIC to complete registration',
      avatarIcon: Icons.badge_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          authFieldLabel('Profile Photo'),
          DocumentImageSlot(
            file: provider.profilePhoto,
            placeholderIcon: Icons.person_outline,
            label: 'Add profile photo',
            onTap: () => _pickImage(ProviderDocumentSlot.profilePhoto),
            onRemove: () => context.read<ProviderDocumentProvider>().removeImage(ProviderDocumentSlot.profilePhoto),
          ),
          const SizedBox(height: 20),
          authFieldLabel('CNIC Front'),
          DocumentImageSlot(
            file: provider.cnicFront,
            placeholderIcon: Icons.credit_card,
            label: 'Add CNIC front image',
            onTap: () => _pickImage(ProviderDocumentSlot.cnicFront),
            onRemove: () => context.read<ProviderDocumentProvider>().removeImage(ProviderDocumentSlot.cnicFront),
          ),
          const SizedBox(height: 20),
          authFieldLabel('CNIC Back'),
          DocumentImageSlot(
            file: provider.cnicBack,
            placeholderIcon: Icons.credit_card,
            label: 'Add CNIC back image',
            onTap: () => _pickImage(ProviderDocumentSlot.cnicBack),
            onRemove: () => context.read<ProviderDocumentProvider>().removeImage(ProviderDocumentSlot.cnicBack),
          ),
          const SizedBox(height: 28),
          if (provider.isUploading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: provider.uploadProgress > 0 ? provider.uploadProgress : null,
                minHeight: 8,
                backgroundColor: const Color(0xFFF5F5F7),
                valueColor: const AlwaysStoppedAnimation(kPrimaryColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploading... ${(provider.uploadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],
          AuthPrimaryButton(
            label: 'Upload & Continue',
            isLoading: provider.isUploading,
            onPressed: provider.canUpload ? _upload : null,
          ),
          if (!provider.canUpload)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Profile photo, CNIC front and CNIC back are all required.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
