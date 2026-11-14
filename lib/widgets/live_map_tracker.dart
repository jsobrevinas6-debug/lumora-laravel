import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

class LiveMapTracker extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onDriverCall;
  final VoidCallback? onDriverMessage;
  final double height;

  const LiveMapTracker({
    super.key,
    required this.order,
    this.onDriverCall,
    this.onDriverMessage,
    this.height = 360,
  });

  @override
  State<LiveMapTracker> createState() => _LiveMapTrackerState();
}

class _LiveMapTrackerState extends State<LiveMapTracker>
    with TickerProviderStateMixin {
  late TransformationController _transformController;
  late AnimationController _truckAnimController;
  late AnimationController _radarPulseController;

  double _simSpeed = 1.0;
  bool _isPlaying = true;
  double _currentProgress = 0.62;

  // Path coordinates representing C-5 / Kalayaan into Bonifacio Global City (BGC)
  final List<Offset> _routeWaypoints = const [
    Offset(60, 75),    // Lumora Logistics Hub (Pasig / C-5)
    Offset(110, 85),   // C-5 North Entrance
    Offset(160, 115),  // C-5 Southbound Expressway
    Offset(210, 160),  // Kalayaan Flyover Junction
    Offset(250, 195),  // 32nd Street BGC Gate
    Offset(290, 215),  // 5th Avenue & 28th St
    Offset(335, 235),  // Bonifacio High Street
    Offset(375, 255),  // 26th Street & 11th Ave
    Offset(410, 260),  // Destination (Two Serendra, BGC)
  ];

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();

    _truckAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );

    _radarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Start with order's existing progress or default 0.62
    final webStatus = widget.order.normalizedWebStatus;
    _currentProgress = webStatus == 'delivered' ? 1.0 : widget.order.progress;
    _truckAnimController.value = _currentProgress;

    _truckAnimController.addListener(() {
      setState(() {
        _currentProgress = _truckAnimController.value;
      });
    });

    if (webStatus != 'delivered' && webStatus != 'cancelled') {
      _truckAnimController.repeat();
    } else {
      _isPlaying = false;
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    _truckAnimController.dispose();
    _radarPulseController.dispose();
    super.dispose();
  }

  void _resetMapCamera() {
    HapticService.selection();
    setState(() {
      _transformController.value = Matrix4.identity();
    });
  }

  void _togglePlayPause() {
    HapticService.selection();
    setState(() {
      if (_isPlaying) {
        _truckAnimController.stop();
        _isPlaying = false;
      } else {
        _truckAnimController.repeat();
        _isPlaying = true;
      }
    });
  }

  void _cycleSimulationSpeed() {
    HapticService.selection();
    setState(() {
      if (_simSpeed == 1.0) {
        _simSpeed = 2.0;
        _truckAnimController.duration = const Duration(seconds: 11);
      } else if (_simSpeed == 2.0) {
        _simSpeed = 4.0;
        _truckAnimController.duration = const Duration(seconds: 5);
      } else {
        _simSpeed = 1.0;
        _truckAnimController.duration = const Duration(seconds: 22);
      }
      if (_isPlaying) {
        _truckAnimController.repeat();
      }
    });
  }

  // Calculate current point and angle along waypoint spline
  MapPointHeading _calculatePositionAndHeading(double t) {
    if (_routeWaypoints.isEmpty) {
      return MapPointHeading(position: Offset.zero, heading: 0);
    }
    final totalSegments = _routeWaypoints.length - 1;
    final progress = t.clamp(0.0, 1.0);
    final scaledProgress = progress * totalSegments;
    final segIndex = scaledProgress.floor().clamp(0, totalSegments - 1);
    final segT = scaledProgress - segIndex;

    final p0 = _routeWaypoints[segIndex];
    final p1 = _routeWaypoints[segIndex + 1];

    final currentPos = Offset(
      ui.lerpDouble(p0.dx, p1.dx, segT)!,
      ui.lerpDouble(p0.dy, p1.dy, segT)!,
    );

    final dx = p1.dx - p0.dx;
    final dy = p1.dy - p0.dy;
    final heading = math.atan2(dy, dx);

    return MapPointHeading(position: currentPos, heading: heading);
  }

  @override
  Widget build(BuildContext context) {
    final truckData = _calculatePositionAndHeading(_currentProgress);
    final remainingKm = ((1.0 - _currentProgress) * 3.8).clamp(0.2, 3.8);
    final remainingMins = (remainingKm * 3.5).round().clamp(2, 25);
    final webStatus = widget.order.normalizedWebStatus;
    final isDelivered = _currentProgress >= 0.98 || webStatus == 'delivered';
    final shortDest = widget.order.deliveryAddress.split(',').take(2).join(',').trim();

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.plum.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Natural Gesture Zoom & Pan Map Canvas (Automatic Pinch-to-Zoom)
          InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.75,
            maxScale: 3.5,
            boundaryMargin: const EdgeInsets.all(160),
            clipBehavior: Clip.none,
            child: SizedBox(
              width: 500,
              height: 380,
              child: CustomPaint(
                painter: _GoogleMapCanvasPainter(
                  waypoints: _routeWaypoints,
                  progress: _currentProgress,
                ),
                child: Stack(
                  children: [
                    // Origin Marker (Lumora Logistics Hub)
                    Positioned(
                      left: _routeWaypoints.first.dx - 18,
                      top: _routeWaypoints.first.dy - 36,
                      child: _buildLocationPin(
                        label: 'LUMORA HUB',
                        subLabel: widget.order.computedSortingHub,
                        icon: Icons.warehouse_rounded,
                        color: AppColors.plum,
                      ),
                    ),

                    // Destination Marker (Buyer Delivery Address)
                    Positioned(
                      left: _routeWaypoints.last.dx - 18,
                      top: _routeWaypoints.last.dy - 36,
                      child: _buildLocationPin(
                        label: 'DELIVERY DESTINATION',
                        subLabel: shortDest.isNotEmpty ? shortDest : widget.order.deliveryAddress,
                        icon: Icons.home_filled,
                        color: const Color(0xFFD32F2F),
                        isPulse: isDelivered,
                      ),
                    ),

                    // Animated Moving Delivery Truck with Heading Alignment & Radar Wave
                    Positioned(
                      left: truckData.position.dx - 22,
                      top: truckData.position.dy - 22,
                      child: _buildMovingTruck(truckData.heading, remainingMins, isDelivered),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top Status Header (Google Maps Style Pill)
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDelivered ? const Color(0xFF4CAF50) : AppColors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDelivered ? const Color(0xFF4CAF50) : AppColors.orange).withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isDelivered ? 'PACKAGE DELIVERED' : 'EN ROUTE TO YOUR LOCATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDelivered ? const Color(0xFF2E7D32) : AppColors.plum,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDelivered
                              ? 'Delivered safely to ${shortDest.isNotEmpty ? shortDest : widget.order.deliveryAddress}'
                              : '$remainingMins mins away (${remainingKm.toStringAsFixed(1)} km) • ${widget.order.computedSortingHub}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.plum.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(_currentProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.plum),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Map Controls (Re-center, Simulation Speed, Play/Pause)
          Positioned(
            right: 14,
            bottom: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Natural Pinch Hint Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Pinch to zoom map',
                        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Speed Toggle (1x, 2x, 4x)
                    _mapCircularButton(
                      label: '${_simSpeed.toInt()}x',
                      tooltip: 'Simulation Speed',
                      onTap: _cycleSimulationSpeed,
                    ),
                    const SizedBox(width: 8),

                    // Play / Pause Simulation
                    _mapCircularButton(
                      icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                      tooltip: _isPlaying ? 'Pause' : 'Resume',
                      onTap: _togglePlayPause,
                    ),
                    const SizedBox(width: 8),

                    // Re-center on Delivery Truck
                    _mapCircularButton(
                      icon: Icons.my_location,
                      tooltip: 'Re-center camera',
                      color: AppColors.plum,
                      iconColor: Colors.white,
                      onTap: _resetMapCamera,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapCircularButton({
    IconData? icon,
    String? label,
    required String tooltip,
    required VoidCallback onTap,
    Color color = Colors.white,
    Color iconColor = AppColors.plum,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 18, color: iconColor)
                : Text(
                    label ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPin({
    required String label,
    required String subLabel,
    required IconData icon,
    required Color color,
    bool isPulse = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: color,
                ),
              ),
              Text(
                subLabel,
                style: const TextStyle(fontSize: 7.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 15, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildMovingTruck(double headingRad, int minsRemaining, bool isDelivered) {
    return AnimatedBuilder(
      animation: _radarPulseController,
      builder: (context, child) {
        final pulseVal = _radarPulseController.value;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Concentric GPS Radar Ping Rings
            if (!isDelivered)
              Container(
                width: 44 + (pulseVal * 34),
                height: 44 + (pulseVal * 34),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.plum.withValues(alpha: (1.0 - pulseVal) * 0.28),
                  border: Border.all(
                    color: AppColors.plum.withValues(alpha: (1.0 - pulseVal) * 0.5),
                    width: 1.5,
                  ),
                ),
              ),

            // Floating Tooltip above truck
            Positioned(
              top: -34,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.plum,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.plum.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: AppColors.gold, size: 10),
                    const SizedBox(width: 3),
                    Text(
                      isDelivered ? 'Arrived' : '${widget.order.driverName.split('(').first.trim()} • 32 km/h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Rotated Delivery Truck Icon matching road heading
            Transform.rotate(
              angle: headingRad,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.plum, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.plum.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: AppColors.plum,
                  size: 20,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class MapPointHeading {
  final Offset position;
  final double heading;

  MapPointHeading({required this.position, required this.heading});
}

// ============================================================================
// REALISTIC GOOGLE MAPS STYLE VECTOR CANVAS PAINTER
// ============================================================================

class _GoogleMapCanvasPainter extends CustomPainter {
  final List<Offset> waypoints;
  final double progress;

  _GoogleMapCanvasPainter({
    required this.waypoints,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Map Base / Urban Landscape
    final basePaint = Paint()..color = const Color(0xFFEBEFE8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // 2. City Blocks & Residential Parcels
    final blockPaint = Paint()..color = const Color(0xFFF7F8FA);
    final blockBorderPaint = Paint()
      ..color = const Color(0xFFDFE3E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final List<Rect> urbanBlocks = [
      const Rect.fromLTWH(20, 20, 90, 50),
      const Rect.fromLTWH(130, 25, 110, 55),
      const Rect.fromLTWH(260, 30, 100, 60),
      const Rect.fromLTWH(380, 20, 90, 70),

      const Rect.fromLTWH(30, 140, 95, 65),
      const Rect.fromLTWH(145, 175, 80, 60),
      const Rect.fromLTWH(240, 240, 75, 80),
      const Rect.fromLTWH(330, 275, 130, 70),
      const Rect.fromLTWH(40, 270, 110, 80),
    ];

    for (final b in urbanBlocks) {
      final rrect = RRect.fromRectAndRadius(b, const Radius.circular(8));
      canvas.drawRRect(rrect, blockPaint);
      canvas.drawRRect(rrect, blockBorderPaint);
    }

    // 3. Green Parks (Track 30th & Terra 28th Parks in BGC)
    final parkPaint = Paint()..color = const Color(0xFFD4ECD5);
    final parkBorder = Paint()
      ..color = const Color(0xFFB7E1B9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final parkRect1 = RRect.fromRectAndRadius(const Rect.fromLTWH(280, 120, 75, 55), const Radius.circular(10));
    final parkRect2 = RRect.fromRectAndRadius(const Rect.fromLTWH(180, 270, 65, 50), const Radius.circular(10));
    canvas.drawRRect(parkRect1, parkPaint);
    canvas.drawRRect(parkRect1, parkBorder);
    canvas.drawRRect(parkRect2, parkPaint);
    canvas.drawRRect(parkRect2, parkBorder);

    // 4. Waterway (Pasig River stream)
    final waterPaint = Paint()
      ..color = const Color(0xFFC7E6FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(0, 310)
      ..cubicTo(90, 330, 150, 360, 260, 345)
      ..cubicTo(340, 330, 420, 370, 500, 360);
    canvas.drawPath(riverPath, waterPaint);

    // 5. Urban Street Grid & Avenues
    final secondaryRoadBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final secondaryRoadFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final roadPaths = [
      Path()..moveTo(0, 100)..lineTo(500, 100),
      Path()..moveTo(0, 200)..lineTo(500, 200),
      Path()..moveTo(0, 280)..lineTo(500, 280),
      Path()..moveTo(130, 0)..lineTo(130, 380),
      Path()..moveTo(240, 0)..lineTo(240, 380),
      Path()..moveTo(350, 0)..lineTo(350, 380),
    ];

    for (final rp in roadPaths) {
      canvas.drawPath(rp, secondaryRoadBorder);
      canvas.drawPath(rp, secondaryRoadFill);
    }

    // 6. Major Arterial Highway (C-5 Road / EDSA with Amber Glow)
    final highwayBorder = Paint()
      ..color = const Color(0xFFE5A823)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final highwayFill = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    final highwayPath = Path()
      ..moveTo(40, 0)
      ..cubicTo(100, 80, 180, 120, 230, 180)
      ..cubicTo(270, 220, 360, 240, 500, 250);

    canvas.drawPath(highwayPath, highwayBorder);
    canvas.drawPath(highwayPath, highwayFill);

    // 7. Route Polyline (Delivery Path)
    if (waypoints.length > 1) {
      final fullPath = Path()..moveTo(waypoints.first.dx, waypoints.first.dy);
      for (int i = 1; i < waypoints.length; i++) {
        fullPath.lineTo(waypoints[i].dx, waypoints[i].dy);
      }

      // Remaining Path: Dashed Plum / Gray Line
      final remainingPaint = Paint()
        ..color = AppColors.plum.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(fullPath, remainingPaint);

      // Traversed Path: Solid Vibrant Emerald/Gold Gradient
      final traversedPaint = Paint()
        ..color = const Color(0xFF43A047)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      // Extract traversed segment
      final pathMetrics = fullPath.computeMetrics().toList();
      if (pathMetrics.isNotEmpty) {
        final metric = pathMetrics.first;
        final length = metric.length;
        final currentLen = length * progress.clamp(0.0, 1.0);
        final extracted = metric.extractPath(0, currentLen);
        canvas.drawPath(extracted, traversedPaint);
      }
    }

    // 8. Road Label Text (Google Maps Street Names)
    _drawRoadLabel(canvas, 'C-5 EXPRESSWAY', const Offset(120, 92), 0.38);
    _drawRoadLabel(canvas, '26TH STREET BGC', const Offset(340, 196), 0.0);
    _drawRoadLabel(canvas, '5TH AVENUE', const Offset(234, 130), math.pi / 2);
    _drawRoadLabel(canvas, 'BONIFACIO HIGH STREET', const Offset(275, 230), 0.12);
    _drawRoadLabel(canvas, 'PASIG RIVER', const Offset(170, 340), 0.1);
  }

  void _drawRoadLabel(Canvas canvas, String text, Offset position, double rotation) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0xFF78909C),
        fontSize: 8.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleMapCanvasPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
