import 'package:flutter/material.dart';

enum ButtonState { idle, loading, success, error }

class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final ButtonState state;

  const AnimatedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.height = 50,
    this.borderRadius = 12,
    this.state = ButtonState.idle,
  }) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.secondary;
    final txtColor = widget.textColor ?? Colors.white;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? _handleTapDown : null,
      onTapUp: widget.onPressed != null ? _handleTapUp : null,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bgColor,
                bgColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: bgColor.withOpacity(0.3),
                blurRadius: _isPressed ? 8 : 15,
                offset: Offset(0, _isPressed ? 2 : 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              onTap: widget.onPressed,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _buildButtonContent(txtColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    switch (widget.state) {
      case ButtonState.loading:
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
        );
      case ButtonState.success:
        return Center(
          child: Icon(Icons.check_circle, color: textColor, size: 28),
        );
      case ButtonState.error:
        return Center(
          child: Icon(Icons.error, color: textColor, size: 28),
        );
      case ButtonState.idle:
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: textColor, size: 20),
              SizedBox(width: 8),
            ],
            Text(
              widget.text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
    }
  }
}
