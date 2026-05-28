import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../services/database_service.dart';
import 'note_detail_page.dart';

class GraphNode {
  final String id;
  final String label;
  final bool isTag;
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  final Map<String, dynamic>? rawMemo;

  GraphNode({
    required this.id,
    required this.label,
    required this.isTag,
    required this.x,
    required this.y,
    this.rawMemo,
  });
}

class GraphEdge {
  final GraphNode source;
  final GraphNode target;
  GraphEdge({required this.source, required this.target});
}

class GraphPage extends StatefulWidget {
  const GraphPage({Key? key}) : super(key: key);

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> with SingleTickerProviderStateMixin {
  List<GraphNode> _nodes = [];
  List<GraphEdge> _edges = [];
  bool _isLoading = true;

  // Viewport offsets
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;
  Offset _referencePan = Offset.zero;

  // Highlight filters
  GraphNode? _highlightedNode;
  
  // Animation ticker for physics
  late AnimationController _physicsController;

  @override
  void initState() {
    super.initState();
    _loadGraphData();

    _physicsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tickSimulation);
  }

  @override
  void dispose() {
    _physicsController.dispose();
    super.dispose();
  }

  Future<void> _loadGraphData() async {
    setState(() => _isLoading = true);
    final memos = await DatabaseService.getMemos();
    
    final List<GraphNode> nodes = [];
    final List<GraphEdge> edges = [];
    final Map<String, GraphNode> tagNodeMap = {};

    final random = math.Random();

    // 1. Create note nodes
    for (var m in memos) {
      final String id = m['id'] ?? '';
      final String title = m['title'] ?? 'Untitled';
      
      // Place nodes in a small circle around center initially to push outward organically
      final double angle = random.nextDouble() * 2.0 * math.pi;
      final double r = 40.0 + random.nextDouble() * 80.0;
      final double x = r * math.cos(angle);
      final double y = r * math.sin(angle);

      final noteNode = GraphNode(
        id: 'note_$id',
        label: title,
        isTag: false,
        x: x,
        y: y,
        rawMemo: m,
      );
      nodes.add(noteNode);

      // 2. Parse tags and link them
      final String tagsStr = m['tags'] as String? ?? '';
      if (tagsStr.isNotEmpty) {
        final tags = tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty);
        for (var t in tags) {
          final tagKey = t.toLowerCase();
          GraphNode? tagNode = tagNodeMap[tagKey];
          if (tagNode == null) {
            final double tagAngle = random.nextDouble() * 2.0 * math.pi;
            final double tagR = 100.0 + random.nextDouble() * 100.0;
            tagNode = GraphNode(
              id: 'tag_$tagKey',
              label: '#$t',
              isTag: true,
              x: tagR * math.cos(tagAngle),
              y: tagR * math.sin(tagAngle),
            );
            tagNodeMap[tagKey] = tagNode;
            nodes.add(tagNode);
          }

          // Edge between Note and Tag
          edges.add(GraphEdge(source: noteNode, target: tagNode));
        }
      }
    }

    // 3. Cluster similar notes (Edge between note nodes sharing same category)
    for (int i = 0; i < memos.length; i++) {
      for (int j = i + 1; j < memos.length; j++) {
        final catA = memos[i]['category'] ?? 'General';
        final catB = memos[j]['category'] ?? 'General';
        if (catA == catB) {
          final nodeA = nodes.firstWhere((n) => n.id == 'note_${memos[i]['id']}');
          final nodeB = nodes.firstWhere((n) => n.id == 'note_${memos[j]['id']}');
          // Add a weak spring edge to bring same categories together
          edges.add(GraphEdge(source: nodeA, target: nodeB));
        }
      }
    }

    setState(() {
      _nodes = nodes;
      _edges = edges;
      _isLoading = false;
      _panOffset = Offset.zero;
      _scale = 1.0;
    });

    // Start simulation running indefinitely
    _physicsController.repeat();
  }

  void _tickSimulation() {
    if (_nodes.isEmpty) return;

    const double gravity = 0.035;

    // 1. Repulsion between ALL node pairs
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        double dx = _nodes[j].x - _nodes[i].x;
        double dy = _nodes[j].y - _nodes[i].y;
        if (dx == 0) dx = 0.1;
        double distSq = dx * dx + dy * dy;
        double dist = math.sqrt(distSq);
        if (dist < 0.1) dist = 0.1;

        // Force inversely proportional to distance squared
        double force = 1400.0 / distSq;
        if (force > 15.0) force = 15.0; // Limit force cap to prevent flying away

        double fx = (dx / dist) * force;
        double fy = (dy / dist) * force;

        _nodes[i].vx -= fx;
        _nodes[i].vy -= fy;
        _nodes[j].vx += fx;
        _nodes[j].vy += fy;
      }
    }

    // 2. Attraction along connected spring edges
    for (var edge in _edges) {
      double dx = edge.target.x - edge.source.x;
      double dy = edge.target.y - edge.source.y;
      double dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 0.1) dist = 0.1;

      // Tag-note link is smaller/tighter; Note-note category links are looser
      bool isCategoryLink = !edge.source.isTag && !edge.target.isTag;
      double desiredLength = isCategoryLink ? 160.0 : 80.0;
      double kSpring = isCategoryLink ? 0.012 : 0.045; // Spring stiffness
      
      double force = kSpring * (dist - desiredLength);

      double fx = (dx / dist) * force;
      double fy = (dy / dist) * force;

      edge.source.vx += fx;
      edge.source.vy += fy;
      edge.target.vx -= fx;
      edge.target.vy -= fy;
    }

    // 3. Apply center gravity and update positions with friction damping
    setState(() {
      for (var node in _nodes) {
        // Soft pull to center (0,0)
        node.vx += (-node.x) * gravity;
        node.vy += (-node.y) * gravity;

        node.x += node.vx;
        node.y += node.vy;

        // Friction factor
        node.vx *= 0.82;
        node.vy *= 0.82;
      }
    });
  }

  void _handleTapUp(TapUpDetails details, Size viewSize) {
    // Convert tap coordinate back to graph space
    final double cx = viewSize.width / 2.0;
    final double cy = viewSize.height / 2.0;
    final double localX = (details.localPosition.dx - cx - _panOffset.dx) / _scale;
    final double localY = (details.localPosition.dy - cy - _panOffset.dy) / _scale;

    GraphNode? tappedNode;
    double minTapDist = 24.0 / _scale;

    for (var node in _nodes) {
      double dist = math.sqrt(math.pow(node.x - localX, 2) + math.pow(node.y - localY, 2));
      if (dist < minTapDist) {
        tappedNode = node;
        minTapDist = dist;
      }
    }

    if (tappedNode != null) {
      if (tappedNode.isTag) {
        // Tag node toggles highlight
        setState(() {
          if (_highlightedNode?.id == tappedNode!.id) {
            _highlightedNode = null;
          } else {
            _highlightedNode = tappedNode;
          }
        });
        HapticFeedback.lightImpact();
      } else {
        // Note node launches reader directly
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailPage(
              memo: tappedNode!.rawMemo!,
              onModified: _loadGraphData,
            ),
          ),
        );
      }
    } else {
      // Tap space to clear highlight
      if (_highlightedNode != null) {
        setState(() {
          _highlightedNode = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppConfig.secondaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sovereign Mind Graph',
          style: GoogleFonts.outfit(color: AppConfig.secondaryColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong_rounded, color: AppConfig.primaryColor),
            tooltip: 'Recenter Layout',
            onPressed: () {
              setState(() {
                _panOffset = Offset.zero;
                _scale = 1.0;
                _highlightedNode = null;
              });
              HapticFeedback.selectionClick();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppConfig.primaryColor),
            tooltip: 'Regrow Nodes',
            onPressed: _loadGraphData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor))
          : LayoutBuilder(
              builder: (context, constraints) {
                final Size viewSize = Size(constraints.maxWidth, constraints.maxHeight);

                return Stack(
                  children: [
                    // Canvas layer
                    GestureDetector(
                      onScaleStart: (details) {
                        _referencePan = details.localFocalPoint - _panOffset;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          _scale = details.scale.clamp(0.4, 3.0);
                          _panOffset = details.localFocalPoint - _referencePan;
                        });
                      },
                      onTapUp: (details) => _handleTapUp(details, viewSize),
                      child: Container(
                        color: Colors.transparent, // Capture taps over entire background
                        width: double.infinity,
                        height: double.infinity,
                        child: CustomPaint(
                          painter: GraphPainter(
                            nodes: _nodes,
                            edges: _edges,
                            scale: _scale,
                            panOffset: _panOffset,
                            highlightNode: _highlightedNode,
                          ),
                        ),
                      ),
                    ),

                    // On-device security seal floating card
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppConfig.cardColor.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppConfig.primaryColor.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hub_rounded, color: AppConfig.primaryColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _highlightedNode != null 
                                    ? 'Isolating cluster for "${_highlightedNode!.label}". Tap canvas to reset.'
                                    : 'Physics-simulated mind mapping. Tap tags to isolate clusters, tap notes to read.',
                                style: GoogleFonts.outfit(fontSize: 10, color: AppConfig.secondaryColor.withOpacity(0.8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final double scale;
  final Offset panOffset;
  final GraphNode? highlightNode;

  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.scale,
    required this.panOffset,
    required this.highlightNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double cy = size.height / 2.0;

    canvas.save();
    // Center viewport, apply pan and zoom scale
    canvas.translate(cx + panOffset.dx, cy + panOffset.dy);
    canvas.scale(scale);

    // Build lookup maps for connections if a node is highlighted
    final Set<String> connectedNodeIds = {};
    if (highlightNode != null) {
      connectedNodeIds.add(highlightNode!.id);
      for (var edge in edges) {
        if (edge.source.id == highlightNode!.id) {
          connectedNodeIds.add(edge.target.id);
        } else if (edge.target.id == highlightNode!.id) {
          connectedNodeIds.add(edge.source.id);
        }
      }
    }

    // 1. Paint Edges
    final edgePaint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (var edge in edges) {
      final double srcX = edge.source.x;
      final double srcY = edge.source.y;
      final double destX = edge.target.x;
      final double destY = edge.target.y;

      // Render edge translucent or highlighted
      if (highlightNode != null) {
        final isHighlightedEdge = (edge.source.id == highlightNode!.id && connectedNodeIds.contains(edge.target.id)) ||
                                  (edge.target.id == highlightNode!.id && connectedNodeIds.contains(edge.source.id));
        if (!isHighlightedEdge) {
          edgePaint.color = Colors.grey.withOpacity(0.04);
        } else {
          edgePaint.color = AppConfig.primaryColor.withOpacity(0.5);
        }
      } else {
        // Differentiate note-note category lines from note-tag association lines
        final isCategoryLink = !edge.source.isTag && !edge.target.isTag;
        edgePaint.color = isCategoryLink 
            ? AppConfig.primaryColor.withOpacity(0.08) 
            : const Color(0xFFe5c3a3).withOpacity(0.3);
      }

      canvas.drawLine(Offset(srcX, srcY), Offset(destX, destY), edgePaint);
    }

    // 2. Paint Nodes
    for (var node in nodes) {
      // Skip or fade if highlighted
      double opacity = 1.0;
      if (highlightNode != null && !connectedNodeIds.contains(node.id)) {
        opacity = 0.15;
      }

      final double radius = node.isTag ? 10.0 : 16.0;

      // Base circle paints
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = (node.isTag ? AppConfig.backgroundColor : AppConfig.cardColor).withOpacity(opacity);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = node.isTag ? 1.5 : 2.0
        ..color = (node.isTag ? const Color(0xFF68d391) : AppConfig.primaryColor).withOpacity(opacity);

      // Node shadow glow (Premium UI!)
      if (opacity > 0.5) {
        final glowPaint = Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..color = (node.isTag ? const Color(0xFF68d391) : AppConfig.primaryColor).withOpacity(0.12);
        canvas.drawCircle(Offset(node.x, node.y), radius + 2, glowPaint);
      }

      // Draw standard shapes
      canvas.drawCircle(Offset(node.x, node.y), radius, fillPaint);
      canvas.drawCircle(Offset(node.x, node.y), radius, strokePaint);

      // 3. Node Labels (Text)
      final textStyle = GoogleFonts.outfit(
        fontSize: node.isTag ? 10 : 11,
        fontWeight: node.isTag ? FontWeight.bold : FontWeight.w600,
        color: (node.isTag ? Colors.green.shade700 : AppConfig.secondaryColor).withOpacity(opacity),
      );

      final textSpan = TextSpan(
        text: node.label,
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      
      // Center text under circle node
      final textOffset = Offset(
        node.x - (textPainter.width / 2.0),
        node.y + radius + 4.0,
      );

      textPainter.paint(canvas, textOffset);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return true; // We always repaint during simulation updates
  }
}
