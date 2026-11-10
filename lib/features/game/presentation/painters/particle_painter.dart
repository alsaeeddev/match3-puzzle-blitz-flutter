import 'dart:math';
import 'package:flutter/material.dart';

/// Lightweight representation of a transient graphical particle.
class Particle {
  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  double life; // 1.0 -> 0.0
  double rotation;
  final double rotationSpeed;
  final bool isCircle;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    this.life = 1.0,
    this.rotation = 0.0,
    required this.rotationSpeed,
    this.isCircle = false,
  });
}

/// Dynamic particle system driving burst explosions during gem clears and cascade combos.
class ParticleSystem {
  final List<Particle> particles = [];
  final Random _random = Random();

  static const double gravity = 200.0; // 200 px/s² downward gravity

  bool get hasActiveParticles => particles.isNotEmpty;

  /// Creates a radial particle burst for a cleared match.
  void emitMatchParticles(Offset center, Color color, int count) {
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 80.0 + _random.nextDouble() * 160.0;
      final velocity = Offset(cos(angle) * speed, sin(angle) * speed);

      particles.add(
        Particle(
          position: center,
          velocity: velocity,
          color: color,
          size: 3.5 + _random.nextDouble() * 4.5,
          life: 1.0,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 8.0,
          isCircle: _random.nextBool(),
        ),
      );
    }
  }

  /// Creates an intensified multi-colored particle fountain for combo events.
  void emitComboParticles(Offset center, int comboLevel) {
    const rainbow = [
      Colors.redAccent,
      Colors.amberAccent,
      Colors.lightGreenAccent,
      Colors.cyanAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
    ];

    final count = (14 * comboLevel).clamp(14, 80);
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 120.0 + _random.nextDouble() * 240.0;
      final velocity = Offset(cos(angle) * speed, sin(angle) * speed);
      final color = rainbow[_random.nextInt(rainbow.length)];

      particles.add(
        Particle(
          position: center,
          velocity: velocity,
          color: color,
          size: 4.5 + _random.nextDouble() * 5.5,
          life: 1.0,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 10.0,
          isCircle: _random.nextBool(),
        ),
      );
    }
  }

  /// Advances physics simulation and cleans up dead particles.
  void update(double dt) {
    if (particles.isEmpty) return;

    for (var i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.velocity = Offset(p.velocity.dx, p.velocity.dy + gravity * dt);
      p.position += p.velocity * dt;
      p.rotation += p.rotationSpeed * dt;
      p.life -= dt * 1.5;

      if (p.life <= 0.0) {
        particles.removeAt(i);
      }
    }
  }

  /// Clears all existing particles.
  void clear() {
    particles.clear();
  }
}

/// Custom painter rendering active simulation particles on a transparent canvas.
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Paint _paint = Paint();

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.life <= 0.0) continue;

      _paint.color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0));
      _paint.style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, _paint);
      } else {
        final half = p.size / 2;
        canvas.drawRect(Rect.fromLTRB(-half, -half, half, half), _paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

