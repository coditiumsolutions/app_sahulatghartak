import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/provider_document_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/provider/document_image_slot.dart';
import '../../../widgets/provider/provider_tab_header.dart';

/// Lets a provider view their currently uploaded verification documents
/// (profile photo, CNIC front/back) and replace any of them. Reachable from
/// the Provider Profile page at any time - not just during registration.
class VerificationDocumentsScreen extends StatefulWidget {
  static const routeName = '/provider/profile/verification-documents';
  const VerificationDocumentsScreen({super.key});

  @override
  State<VerificationDocumentsScreen> createState() => _VerificationDocumentsScreenState();
}

class _VerificationDocumentsScreenState extends State<VerificationDocumentsScreen> {
  int? _providerUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    _providerUid = providerUid;
    final provider = context.read<ProviderDocumentProvider>();
    // This provider is a shared singleton, and may still hold state from an
    // unrelated flow (e.g. a leftover local pick from registration) - start clean.
    provider.reset();
    if (providerUid != null) {
      provider.loadDocuments(providerUid);
    }
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
              leading: const Icon(Icons.photo_camera_outlined, color: providerBrandBlue),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: providerBrandBlue),
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

  Future<void> _save() async {
    if (_providerUid == null) return;
    final provider = context.read<ProviderDocumentProvider>();
    final success = await provider.upload(_providerUid!);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documents updated successfully.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to update documents')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderDocumentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: 'My Documents',
        subtitle: provider.isVerified ? 'Verified' : 'Pending verification',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _providerUid == null
          ? const Center(child: Text('Provider profile not found.'))
          : provider.isLoadingExisting
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (provider.loadError != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text(provider.loadError!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                            ],
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (provider.isVerified ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: (provider.isVerified ? Colors.green : Colors.orange).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(provider.isVerified ? Icons.verified : Icons.hourglass_top, color: provider.isVerified ? Colors.green : Colors.orange, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                provider.isVerified ? 'Your documents are verified.' : 'Your documents are pending verification.',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (provider.verificationRemarks != null && provider.verificationRemarks!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text('Remarks: ${provider.verificationRemarks}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        ),
                      ],
                      const Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      DocumentImageSlot(
                        file: provider.profilePhoto,
                        networkUrl: provider.profilePhotoUrl,
                        placeholderIcon: Icons.person_outline,
                        label: 'Add profile photo',
                        onTap: () => _pickImage(ProviderDocumentSlot.profilePhoto),
                        onRemove: () => context.read<ProviderDocumentProvider>().removeImage(ProviderDocumentSlot.profilePhoto),
                      ),
                      const SizedBox(height: 20),
                      const Text('CNIC Front', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      DocumentImageSlot(
                        file: provider.cnicFront,
                        networkUrl: provider.cnicFrontUrl,
                        placeholderIcon: Icons.credit_card,
                        label: 'Add CNIC front image',
                        onTap: () => _pickImage(ProviderDocumentSlot.cnicFront),
                        onRemove: () => context.read<ProviderDocumentProvider>().removeImage(ProviderDocumentSlot.cnicFront),
                      ),
                      const SizedBox(height: 20),
                      const Text('CNIC Back', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      DocumentImageSlot(
                        file: provider.cnicBack,
                        networkUrl: provider.cnicBackUrl,
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
                            valueColor: const AlwaysStoppedAnimation(providerBrandBlue),
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
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: kProminentFilledButtonStyle(providerBrandBlue),
                          onPressed: provider.canUpload && !provider.isUploading ? _save : null,
                          child: provider.isUploading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save Changes'),
                        ),
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
                ),
    );
  }
}
