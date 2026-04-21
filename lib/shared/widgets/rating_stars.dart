import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;

  const RatingStars({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final starValue = index + 1;
        double fillValue;

        if (rating >= starValue) {
          fillValue = 1.0;
        } else if (rating >= starValue - 0.5) {
          fillValue = 0.5;
        } else {
          fillValue = 0.0;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            fillValue == 1.0
                ? Icons.star
                : fillValue == 0.5
                ? Icons.star_half
                : Icons.star_border,
            size: size,
            color: Colors.amber,
          ),
        );
      }),
    );
  }
}
