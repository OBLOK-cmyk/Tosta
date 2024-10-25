import 'package:flutter/material.dart';

class AppBanner extends StatefulWidget {
  const AppBanner({Key? key}) : super(key: key);

  @override
  _AppBannerState createState() => _AppBannerState();
}

class _AppBannerState extends State<AppBanner> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
      upperBound: 1.0,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade600,
              Colors.purple.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Image.asset(
                    'assets/images/BGC.png',
                    fit: BoxFit.cover,
                    height: 200, // Adjust the height as needed
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'WELCOME!!',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 12.0,
                        color: Colors.black.withOpacity(0.6),
                        offset: const Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}