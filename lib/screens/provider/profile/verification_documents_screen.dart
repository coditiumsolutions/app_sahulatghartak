import 'package:flutter/material.dart';
import '../../../widgets/frosted_icon_button.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/provider_document_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/provider/document_capture_sheet.dart';
import '../../../widgets/provider/document_image_slot.dart';
import '../../../widgets/provider/provider_tab_header.dart';

/// Lets a provider view their currently uploaded verification documents
/// (profile photo, CNIC front/back) and replace any of them. Reachable from
/// the Provider Profile page at any time - not just during registration.
class VerificationDocumentsScreen extends StatefulWidget {
  static const routeName = '/provider/profile/verification-documents';
  const VerificationDocumentsScreen({super.key});

  @override
  State<VerificationDocumentsScreen> createState() =>
      _VerificationDocumentsScreenState();
}

class _VerificationDocumentsScreenState
    extends State<VerificationDocumentsScreen> {
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

  Future<void> _save() async {
    if (_providerUid == null) return;
    final provider = context.read<ProviderDocumentProvider>();
    final success = await provider.saveChanges(_providerUid!);

    if (!mounted) return;

    if (success) {
      await showMessageDialog(
        context,
        title: 'Documents Updated',
        message: 'Your documents were updated successfully.',
        type: MessageDialogType.success,
      );
    } else {
      await showMessageDialog(
        context,
        title: 'Update Failed',
        message: provider.error ?? 'Failed to update documents',
        type: MessageDialogType.error,
      );
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
        leading: FrostedBackButton(onPressed: () => Navigator.of(context).maybePop(),
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
                          decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(provider.loadError!,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 13))),
                            ],
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (provider.isVerified
                                  ? Colors.green
                                  : Colors.orange)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: (provider.isVerified
                                      ? Colors.green
                                      : Colors.orange)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                                provider.isVerified
                                    ? Icons.verified
                                    : Icons.hourglass_top,
                                color: provider.isVerified
                                    ? Colors.green
                                    : Colors.orange,
                                size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                provider.isVerified
                                    ? 'Your documents are verified.'
                                    : 'Your documents are pending verification.',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (provider.verificationRemarks != null &&
                          provider.verificationRemarks!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                              'Remarks: ${provider.verificationRemarks}',
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 13)),
                        ),
                      ],
                      const Text('Profile Photo',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      DocumentImageSlot(
                        file: provider.profilePhoto,
                        networkUrl: provider.profilePhotoUrl,
                        placeholderIcon: Icons.person_outline,
                        label: 'Add profile photo',
                        onTap: () => showDocumentCaptureSheet(context,
                            slot: ProviderDocumentSlot.profilePhoto),
                        onRemove: () => context
                            .read<ProviderDocumentProvider>()
                            .removeImage(ProviderDocumentSlot.profilePhoto),
                      ),
                      const SizedBox(height: 20),
                      const Text('CNIC Front',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      DocumentImageSlot(
                        file: provider.cnicFront,
                        networkUrl: provider.cnicFrontUrl,
                        placeholderIcon: Icons.credit_card,
                        label: 'Add CNIC front image',
                        locked: provider.isVerified,
                        onTap: () => showDocumentCaptureSheet(context,
                            slot: ProviderDocumentSlot.cnicFront),
                        onRemove: () => context
                            .read<ProviderDocumentProvider>()
                            .removeImage(ProviderDocumentSlot.cnicFront),
                      ),
                      const SizedBox(height: 20),
                      const Text('CNIC Back',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      DocumentImageSlot(
                        file: provider.cnicBack,
                        networkUrl: provider.cnicBackUrl,
                        placeholderIcon: Icons.credit_card,
                        label: 'Add CNIC back image',
                        locked: provider.isVerified,
                        onTap: () => showDocumentCaptureSheet(context,
                            slot: ProviderDocumentSlot.cnicBack),
                        onRemove: () => context
                            .read<ProviderDocumentProvider>()
                            .removeImage(ProviderDocumentSlot.cnicBack),
                      ),
                      if (provider.isVerified) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Your CNIC is locked after verification. Contact support if it needs to change.',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text('Police Verification (optional)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      DocumentImageSlot(
                        file: provider.policeVerification,
                        networkUrl: provider.policeVerificationUrl,
                        placeholderIcon: Icons.local_police_outlined,
                        label: 'Add police verification certificate',
                        locked: provider.isVerified,
                        onTap: () => showDocumentCaptureSheet(context,
                            slot: ProviderDocumentSlot.policeVerification),
                        onRemove: () => context
                            .read<ProviderDocumentProvider>()
                            .removeImage(
                                ProviderDocumentSlot.policeVerification),
                      ),
                      if (provider.isVerified) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Your Police Verification document is locked after verification. Contact support if it needs to change.',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 28),
                      if (provider.isUploading) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: provider.uploadProgress > 0
                                ? provider.uploadProgress
                                : null,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFF5F5F7),
                            valueColor:
                                const AlwaysStoppedAnimation(providerBrandBlue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uploading... ${(provider.uploadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                      ],
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: kProminentFilledButtonStyle(providerBrandBlue),
                          onPressed: provider.canUpload &&
                                  provider.hasChanges &&
                                  !provider.isUploading
                              ? _save
                              : null,
                          child: provider.isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Save Changes'),
                        ),
                      ),
                      if (!provider.canUpload)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Profile photo, CNIC front and CNIC back are all required.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        )
                      else if (!provider.hasChanges)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Replace a photo above to save changes.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
