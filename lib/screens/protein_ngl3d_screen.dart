import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/protein_service.dart';

class ProteinNGLScreen extends StatelessWidget {
  final String ligandId;
  final ProteinService proteinService = ProteinService();

  ProteinNGLScreen({required this.ligandId, super.key});

  @override
  Widget build(BuildContext context) {
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
        print('WebView Console: ${message.message}');
      });

    return Scaffold(
      appBar: AppBar(title: Text('3D View (NGL): $ligandId')),
      body: FutureBuilder<String?>(
        future: proteinService.fetchLigandSDF(ligandId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('Could not load 3D model.'));
          }

          final encodedSdfContent = jsonEncode(snapshot.data!);

          final htmlContent =
              '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://unpkg.com/ngl@latest/dist/ngl.js"></script>
  <style>
    html, body { height: 100%; margin: 0; padding: 0; overflow: hidden; }
    #viewport { width: 100vw; height: 100vh; }
    #popup {
      position: absolute;
      top: 20px; left: 20px;
      padding: 10px 15px;
      font-family: sans-serif;
      background: rgba(20,20,20,0.85);
      color: white;
      border-radius: 8px;
      z-index: 100;
      display: none;
    }
  </style>
</head>
<body>
  <div id="viewport"></div>
  <div id="popup"></div>
  <script>
    var stage = new NGL.Stage("viewport", {backgroundColor: "white"});
    var sdfData = $encodedSdfContent;
    var blob = new Blob([sdfData], {type: "text/plain"});
    var sdfUrl = URL.createObjectURL(blob);

    stage.loadFile(sdfUrl, {ext: "sdf"}).then(function(comp) {
      comp.addRepresentation("hyperball");
      comp.autoView();

      comp.structure.eachAtom(function(atom) {
        atom.click = function(pickingProxy) {
          var popup = document.getElementById('popup');
          popup.innerHTML = "<strong>" + atom.element + "</strong><br>Atom #" + atom.serial;
          popup.style.display = "block";
          popup.style.left = (pickingProxy.pointer.x + 20) + "px";
          popup.style.top = (pickingProxy.pointer.y + 20) + "px";
        };
      });
    });

    document.getElementById('viewport').onclick = function(e) {
      var popup = document.getElementById('popup');
      popup.style.display = "none";
    };
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
