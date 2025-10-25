import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/protein_service.dart';
import '../services/share_service.dart';

class Protein3DScreen extends StatelessWidget {
  final String ligandId;
  final ProteinService proteinService = ProteinService();

  Protein3DScreen({required this.ligandId, super.key});

  @override
  Widget build(BuildContext context) {
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
        print('WebView Console: ${message.message}');
      });

    Future<void> captureAndShare() async {
      try {
        final result = await controller.runJavaScriptReturningResult(
          'capturePng()',
        );
        if (result is String && result.isNotEmpty) {
          final String dataUrl = result.startsWith('"')
              ? jsonDecode(result)
              : result;
          await ShareService().shareDataUrl(
            dataUrl,
            fileName: '$ligandId-3dmol.png',
            subject: '3D Model (3Dmol): $ligandId',
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to capture image: $e')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('3D View: $ligandId'),
        actions: [
          IconButton(
            onPressed: captureAndShare,
            icon: const Icon(Icons.share),
            tooltip: 'Share image',
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: proteinService.fetchLigandSDF(ligandId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            // Show warning popup
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Warning'),
                  content: const Text('Could not load 3D model.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            });
            return const SizedBox.shrink();
          }
          final encodedSdfContent = jsonEncode(snapshot.data!);

          final htmlContent =
              r'''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://3dmol.org/build/3Dmol-min.js"></script>
  <style>
    html, body { height: 100%; margin: 0; padding: 0; overflow: hidden; }
    #viewer { width: 100vw; height: 100vh; position: relative; }
    #popup {
      display: block;
      position: absolute;
      top: 20px; left: 20px;
      padding: 10px 15px;
      font-family: sans-serif;
      pointer-events: none;
      z-index: 100;
    }
    .color {
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      border-radius: 8px;
      color: white;
      background-color: rgba(20, 20, 20, 0.85);
    }

    .color::after {
      content: '';
      position: absolute;
      top: 100%;
      left: 50%;
      margin-left: -8px;
      width: 0;
      height: 0;
      border-left: 8px solid transparent;
      border-right: 8px solid transparent;
      border-top: 8px solid rgba(20, 20, 20, 0.85);
    }

    @keyframes appear {
      0% {opacity: 0;}
      100% {opacity: 1;}
    }
  </style>
</head>
<body>
  <div id="viewer">
    <div id="popup"></div>
  </div>

  <script>
    window.capturePng = function() { try {
      if (typeof window.viewer !== 'undefined' && window.viewer) {
        return window.viewer.pngURI();
      }
      return '';
    } catch (e) { return ''; } };
    if (typeof $3Dmol === 'undefined') {
        document.body.innerHTML = `<div style="color: red; padding: 10px;">Error: 3Dmol.js library failed to load. Check internet connection.</div>`;
    } else {
        try {
          const atomicNumbers = { 'H': 1, 'He': 2, 'Li': 3, 'Be': 4, 'B': 5, 'C': 6, 'N': 7, 'O': 8, 'F': 9, 'Ne': 10, 'Na': 11, 'Mg': 12, 'Al': 13, 'Si': 14, 'P': 15, 'S': 16, 'Cl': 17, 'Ar': 18, 'K': 19, 'Ca': 20, 'Br': 35, 'I': 53 };
          window.viewer = $3Dmol.createViewer("viewer", { backgroundColor: "white" });
          let sdfData = ''' +
              encodedSdfContent +
              r''';
          window.viewer.addModel(sdfData, "sdf");
          window.viewer.setStyle({}, {
            stick: {colorscheme: "Jmol"}, 
            sphere: {scale: 0.3, colorscheme: "Jmol"},
            clickable: true,
            hoverable: true
          });

          window.viewer.setClickable({}, true, function(atom, viewer, event, container) {
            let popup = document.getElementById('popup');
            if (atom) {
              let symbol = atom.elem;
              let atomicNum = atomicNumbers[symbol] || 'N/A';
              popup.innerHTML = '<strong>' + symbol + '</strong><br>Atom #' + atomicNum;
              let screenPos = viewer.modelToScreen(atom);
              popup.style.left = (screenPos.x - 45) + 'px';
              popup.style.top = (screenPos.y - 80) + 'px';
              popup.classList.add('color');
              popup.style.animation = 'appear 0.5s ease';
              popup.addEventListener('animationend', () => {
                popup.style.animation = 'none';
              });
            }
          });
          document.getElementById('viewer').addEventListener('click', function(event) {
            console.log('Clicked on empty space');
            let popup = document.getElementById('popup');
            setTimeout(() => {
              if (!event.target.closest('.popup')) {
                popup.classList.remove('color');
              }
            }, 10);
          });
          window.viewer.zoomTo();
          window.viewer.render();
        } catch (e) {
          document.body.innerHTML = `<div style="color: red; padding: 10px;">Error: \${e.message}</div>`;
        }
    }
  </script>
</body>
</html>
''';

          controller.loadHtmlString(htmlContent);
          return WebViewWidget(controller: controller);
        },
      ),
    );
  }
}
