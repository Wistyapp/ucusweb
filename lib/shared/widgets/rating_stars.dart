import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final Color emptyColor;
  final bool showValue;
  final int? reviewCount;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.color = Colors.amber,
    this.emptyColor = Colors.grey,
    this.showValue = true,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon;
          Color iconColor;

          if (rating >= starValue) {
            icon = Icons.star;
            iconColor = color;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half;
            iconColor = color;
          } else {
            icon = Icons.star_border;
            iconColor = emptyColor.withOpacity(0.3);
          }

          return Icon(icon, size: size, color: iconColor);
        }),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.7,
            ),
          ),
        ],
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: size * 0.6,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveRatingStars extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final double size;
  final Color color;
  final Color emptyColor;
  final bool allowHalf;

  const InteractiveRatingStars({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40,
    this.color = Colors.amber,
    this.emptyColor = Colors.grey,
    this.allowHalf = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;
        Color iconColor;

        if (rating >= starValue) {
          icon = Icons.star;
          iconColor = color;
        } else if (allowHalf && rating >= starValue - 0.5) {
          icon = Icons.star_half;
          iconColor = color;
        } else {
          icon = Icons.star_border;
          iconColor = emptyColor.withOpacity(0.3);
        }

        return GestureDetector(
          onTap: () => onRatingChanged(starValue.toDouble()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(icon, size: size, color: iconColor),
          ),
        );
      }),
    );
  }
}
