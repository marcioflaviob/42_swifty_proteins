import 'package:share_plus/share_plus.dart';
import '../models/protein.dart';
import 'deep_link_service.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  final DeepLinkService _deepLinkService = DeepLinkService();

  /// Share a protein with a deep link
  Future<void> shareProtein(Protein protein) async {
    try {
      final String deepLink = _deepLinkService.generateProteinLink(protein.name);
      
      final String shareText = '''
Check out this protein: ${protein.name}

${protein.complete_name}
Formula: ${protein.formula}
Atom Count: ${protein.atomCount}

Open in Swifty Proteins: $deepLink

Download Swifty Proteins to explore protein structures in 3D!
''';

      await Share.share(
        shareText,
        subject: 'Protein: ${protein.name}',
      );
    } catch (e) {
      throw Exception('Failed to share protein: $e');
    }
  }

  /// Share a protein with custom text
  Future<void> shareProteinWithText(Protein protein, String customText) async {
    try {
      final String deepLink = _deepLinkService.generateProteinLink(protein.name);
      
      final String shareText = '''
$customText

Protein: ${protein.name}
${protein.complete_name}

Open in Swifty Proteins: $deepLink
''';

      await Share.share(
        shareText,
        subject: 'Protein: ${protein.name}',
      );
    } catch (e) {
      throw Exception('Failed to share protein: $e');
    }
  }
}
