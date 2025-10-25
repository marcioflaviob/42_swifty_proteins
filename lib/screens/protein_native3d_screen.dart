import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../services/protein_service.dart';
import '../services/share_service.dart';

class ProteinNative3DScreen extends StatefulWidget {
  final String ligandId;
  const ProteinNative3DScreen({super.key, required this.ligandId});

  @override
  State<ProteinNative3DScreen> createState() => _ProteinNative3DScreenState();
}

class _ProteinNative3DScreenState extends State<ProteinNative3DScreen> {
  final ProteinService _proteinService = ProteinService();
  Molecule? _molecule;
  String? _error;
  double _yaw = 0;
  double _pitch = 0;
  double _scale = 1.0;
  double _baseScale = 1.0;
  final GlobalKey _captureKey = GlobalKey();
  int? _selectedAtomIdx;
  Offset? _selectedScreenPos;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sdf = await _proteinService.fetchLigandSDF(widget.ligandId);
      if (!mounted) return;
      if (sdf == null || sdf.isEmpty) {
        setState(() => _error = 'Could not load 3D model.');
        return;
      }
      final mol = SdfParser.parse(sdf);
      setState(() => _molecule = mol);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error: $e');
    }
  }

  Future<void> _shareImage() async {
    if (_molecule == null) return;
    try {
      // Capture current view
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List bytes = byteData.buffer.asUint8List();
      await ShareService().shareImageBytes(
        bytes,
        fileName: '${widget.ligandId}.png',
        subject: '3D Model: ${widget.ligandId}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share image: $e')));
    }
  }

  Future<void> _saveToGallery() async {
    if (_molecule == null) return;
    try {
      // Capture current view
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List bytes = byteData.buffer.asUint8List();
      await ShareService().saveToGallery(
        bytes,
        fileName: '${widget.ligandId}.png',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to gallery!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save image: $e')));
    }
  }

  void _showShareMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: const Text('Save to Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _saveToGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _shareImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('3D View (Native): ${widget.ligandId}'),
        actions: [
          IconButton(
            onPressed: _molecule == null ? null : _showShareMenu,
            icon: const Icon(Icons.more_vert),
            tooltip: 'Share or Save',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_molecule == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: GestureDetector(
            onDoubleTap: () {
              setState(() {
                _scale = (_scale * 1.25).clamp(0.3, 8.0);
              });
            },
            onScaleStart: (details) {
              if (details.pointerCount == 2) {
                _baseScale = _scale;
              }
            },
            onScaleUpdate: (details) {
              setState(() {
                if (details.pointerCount == 2) {
                  _scale = (_baseScale * details.scale).clamp(0.3, 8.0);
                } else {
                  _yaw += details.focalPointDelta.dx * 0.01;
                  _pitch += details.focalPointDelta.dy * 0.01;
                  _pitch = _pitch.clamp(-math.pi / 2, math.pi / 2);
                }
              });
            },
            onTapDown: (TapDownDetails tap) {
              if (_lastSize == null) return;
              final pts = MoleculePainter.projectPoints(
                _molecule!,
                _lastSize!,
                _yaw,
                _pitch,
                _scale,
              );
              final pos = tap.localPosition;
              int? bestIdx;
              double bestDist2 = 1e9;
              for (int i = 0; i < pts.length; i++) {
                final d2 = (Offset(pts[i].x, pts[i].y) - pos).distanceSquared;
                if (d2 < bestDist2) {
                  bestDist2 = d2;
                  bestIdx = i;
                }
              }
              if (bestIdx != null) {
                final idx = bestIdx;
                final r =
                    (MoleculePainter.elementRadii[pts[idx].element] ?? 0.3) *
                    12.0 *
                    pts[idx].persp;
                final thresh2 = (r * 1.6) * (r * 1.6);
                if (bestDist2 <= thresh2) {
                  setState(() {
                    _selectedAtomIdx = idx;
                    _selectedScreenPos = Offset(pts[idx].x, pts[idx].y);
                  });
                } else {
                  setState(() {
                    _selectedAtomIdx = null;
                    _selectedScreenPos = null;
                  });
                }
              }
            },
            child: RepaintBoundary(
              key: _captureKey,
              child: Stack(
                children: [
                  Container(
                    color: Colors.white,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: CustomPaint(
                      painter: MoleculePainter(
                        molecule: _molecule!,
                        yaw: _yaw,
                        pitch: _pitch,
                        scale: _scale,
                        selectedAtomIdx: _selectedAtomIdx,
                      ),
                    ),
                  ),
                  if (_selectedAtomIdx != null && _selectedScreenPos != null)
                    Positioned(
                      left: (_selectedScreenPos!.dx + 10).clamp(
                        0,
                        constraints.maxWidth - 160,
                      ),
                      top: (_selectedScreenPos!.dy - 40).clamp(
                        0,
                        constraints.maxHeight - 60,
                      ),
                      child: _AtomTooltip(
                        atom: _molecule!.atoms[_selectedAtomIdx!],
                        index: _selectedAtomIdx! + 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class Atom {
  final double x, y, z;
  final String element;
  Atom(this.x, this.y, this.z, this.element);
}

class Bond {
  final int a1, a2;
  final int order;
  Bond(this.a1, this.a2, this.order);
}

class Molecule {
  final List<Atom> atoms;
  final List<Bond> bonds;
  Molecule(this.atoms, this.bonds);

  Rect3 get bounds {
    if (atoms.isEmpty) return const Rect3(0, 0, 0, 0, 0, 0);
    double minX = atoms.first.x, maxX = atoms.first.x;
    double minY = atoms.first.y, maxY = atoms.first.y;
    double minZ = atoms.first.z, maxZ = atoms.first.z;
    for (final a in atoms) {
      if (a.x < minX) minX = a.x;
      if (a.x > maxX) maxX = a.x;
      if (a.y < minY) minY = a.y;
      if (a.y > maxY) maxY = a.y;
      if (a.z < minZ) minZ = a.z;
      if (a.z > maxZ) maxZ = a.z;
    }
    return Rect3(minX, minY, minZ, maxX, maxY, maxZ);
  }
}

class Rect3 {
  final double minX, minY, minZ, maxX, maxY, maxZ;
  const Rect3(this.minX, this.minY, this.minZ, this.maxX, this.maxY, this.maxZ);
}

class SdfParser {
  static Molecule parse(String sdf) {
    final lines = sdf.split(RegExp(r'\r?\n'));
    if (lines.length < 5) {
      return Molecule(const [], const []);
    }
    final counts = lines[3];
    int natoms = _safeInt(counts.substring(0, 3));
    int nbonds = _safeInt(counts.substring(3, 6));

    final atoms = <Atom>[];
    for (int i = 0; i < natoms; i++) {
      final l = lines[4 + i];
      double x = _safeDouble(l.substring(0, 10));
      double y = _safeDouble(l.substring(10, 20));
      double z = _safeDouble(l.substring(20, 30));
      String element = l.length >= 34 ? l.substring(31, 34).trim() : 'C';
      atoms.add(Atom(x, y, z, element));
    }
    final bonds = <Bond>[];
    for (int i = 0; i < nbonds; i++) {
      final l = lines[4 + natoms + i];
      int a1 = _safeInt(l.substring(0, 3)) - 1;
      int a2 = _safeInt(l.substring(3, 6)) - 1;
      int order = _safeInt(l.substring(6, 9));
      if (a1 >= 0 && a2 >= 0 && a1 < atoms.length && a2 < atoms.length) {
        bonds.add(Bond(a1, a2, order));
      }
    }
    return Molecule(atoms, bonds);
  }

  static int _safeInt(String s) {
    return int.tryParse(s.trim()) ?? 0;
  }

  static double _safeDouble(String s) {
    return double.tryParse(s.trim()) ?? 0.0;
  }
}

class MoleculePainter extends CustomPainter {
  final Molecule molecule;
  final double yaw;
  final double pitch;
  final double scale;
  final int? selectedAtomIdx;

  MoleculePainter({
    required this.molecule,
    required this.yaw,
    required this.pitch,
    required this.scale,
    this.selectedAtomIdx,
  });

  static const Map<String, Color> elementColors = {
    'H': Color(0xFFEEEEEE),
    'C': Color(0xFF444444),
    'N': Color(0xFF3050F8),
    'O': Color(0xFFFF0D0D),
    'F': Color(0xFF90E050),
    'Cl': Color(0xFF1FF01F),
    'Br': Color(0xFFA62929),
    'I': Color(0xFF940094),
    'S': Color(0xFFFFFF30),
    'P': Color(0xFFFF8000),
  };

  static const Map<String, double> elementRadii = {
    'H': 0.20,
    'C': 0.30,
    'N': 0.30,
    'O': 0.30,
    'F': 0.30,
    'Cl': 0.35,
    'Br': 0.40,
    'I': 0.45,
    'S': 0.35,
    'P': 0.35,
  };

  static List<_Pt> projectPoints(
    Molecule molecule,
    Size size,
    double yaw,
    double pitch,
    double scale,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final bounds = molecule.bounds;
    final dx = bounds.maxX - bounds.minX;
    final dy = bounds.maxY - bounds.minY;
    final dz = bounds.maxZ - bounds.minZ;
    final maxDim = [
      dx.abs(),
      dy.abs(),
      dz.abs(),
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    final baseScale = (math.min(size.width, size.height) * 0.45) / maxDim;
    final camDist = maxDim * 3.0;

    final sinY = math.sin(yaw), cosY = math.cos(yaw);
    final sinX = math.sin(pitch), cosX = math.cos(pitch);

    final cx = (bounds.minX + bounds.maxX) / 2;
    final cy = (bounds.minY + bounds.maxY) / 2;
    final cz = (bounds.minZ + bounds.maxZ) / 2;

    final pts = <_Pt>[];
    for (final a in molecule.atoms) {
      double x = a.x - cx;
      double y = a.y - cy;
      double z = a.z - cz;

      double x1 = x * cosY + z * sinY;
      double z1 = -x * sinY + z * cosY;
      double y2 = y * cosX - z1 * sinX;
      double z2 = y * sinX + z1 * cosX;

      final denom = (camDist - z2).clamp(0.1, double.infinity);
      final persp = ((camDist / denom) * scale).clamp(0.01, 100.0);
      final px = center.dx + x1 * baseScale * persp;
      final py = center.dy - y2 * baseScale * persp;
      pts.add(_Pt(px, py, z2, a.element, persp));
    }
    return pts;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pts = projectPoints(molecule, size, yaw, pitch, scale);

    final order = List<int>.generate(pts.length, (i) => i);
    order.sort((i, j) => pts[i].z.compareTo(pts[j].z));

    for (final b in molecule.bonds) {
      final p1 = pts[b.a1];
      final p2 = pts[b.a2];
      final aColor = elementColors[p1.element] ?? const Color(0xFF888888);
      final bColor = elementColors[p2.element] ?? const Color(0xFF888888);
      final avgPersp = (p1.persp + p2.persp) * 0.5;
      final baseThickness = (2.2 * avgPersp).clamp(0.5, 20.0); // responsive to depth

      final dxs = p2.x - p1.x;
      final dys = p2.y - p1.y;
      final len = math.max(1.0, math.sqrt(dxs * dxs + dys * dys));
      final nx = -dys / len;
      final ny = dxs / len;
      final spacing = baseThickness * 1.2;

      final offsets = <double>[];
      if (b.order <= 1) {
        offsets.add(0);
      } else if (b.order == 2) {
        offsets.addAll([-spacing * 0.5, spacing * 0.5]);
      } else {
        offsets.addAll([0, -spacing, spacing]);
      }

      for (final off in offsets) {
        final o = Offset(nx * off, ny * off);
        final aPt = Offset(p1.x, p1.y) + o;
        final bPt = Offset(p2.x, p2.y) + o;
        final mid = Offset((aPt.dx + bPt.dx) * 0.5, (aPt.dy + bPt.dy) * 0.5);
        final opacityFactor = (0.85 * (0.8 + 0.2 * avgPersp)).clamp(0.0, 1.0);
        final paintA = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = baseThickness.clamp(0.5, 20.0)
          ..color = aColor.withOpacity(opacityFactor);
        final paintB = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = baseThickness.clamp(0.5, 20.0)
          ..color = bColor.withOpacity(opacityFactor);

        canvas.drawLine(aPt, mid, paintA);
        canvas.drawLine(mid, bPt, paintB);
      }
    }

    for (final idx in order) {
      final p = pts[idx];
      final element = p.element;
      final color = elementColors[element] ?? const Color(0xFF888888);
      final baseR = (elementRadii[element] ?? 0.3) * 8.0;
      final radius = (baseR * p.persp).clamp(0.1, 1000.0);
      final centerPt = Offset(p.x, p.y);

      final atomPaint = Paint()..color = color;
      canvas.drawCircle(centerPt, radius, atomPaint);

      final lightDir = Offset(-0.6, -0.8);
      final lightOffset = Offset(
        lightDir.dx * radius * 0.4,
        lightDir.dy * radius * 0.4,
      );
      final highlightRadius = (radius * 0.55).clamp(0.1, 1000.0);
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.18)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
      canvas.drawCircle(centerPt + lightOffset, highlightRadius, highlightPaint);

      final outlineWidth = math.max(1.0, radius * 0.08).clamp(1.0, 20.0);
      canvas.drawCircle(
        centerPt,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineWidth
          ..color = Colors.black.withOpacity(0.15),
      );

      if (selectedAtomIdx != null &&
          pts[selectedAtomIdx!].x == p.x &&
          pts[selectedAtomIdx!].y == p.y) {
        final selectionRadius = (radius * 1.25).clamp(0.1, 1000.0);
        final selectionWidth = math.max(2.0, radius * 0.12).clamp(2.0, 20.0);
        canvas.drawCircle(
          centerPt,
          selectionRadius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = selectionWidth
            ..color = Colors.amber.withOpacity(0.8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MoleculePainter oldDelegate) {
    return oldDelegate.molecule != molecule ||
        oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.scale != scale;
  }
}

class _Pt {
  final double x, y, z;
  final String element;
  final double persp;
  _Pt(this.x, this.y, this.z, this.element, this.persp);
}

class _AtomTooltip extends StatelessWidget {
  final Atom atom;
  final int index;
  const _AtomTooltip({required this.atom, required this.index});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              atom.element,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text('#$index', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
