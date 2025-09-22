import 'package:share_plus/share_plus.dart';
import '../models/protein.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();


  Future<void> shareProtein(Protein protein) async {
    try {
      
      final String shareText = '''
Check out this protein: ${protein.name}

${protein.complete_name}
Formula: ${protein.formula}
Atom Count: ${protein.atomCount}

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

  Future<void> shareProteinWithText(Protein protein, String customText) async {
    try {
      
      final String shareText = '''
$customText

Protein: ${protein.name}
${protein.complete_name}

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
