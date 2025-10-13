// lib/app/models/onboarding_item_model.dart
import 'package:flutter/material.dart'; // Untuk IconData

class OnboardingItemModel {
  final String title;
  final String description;
  final String imagePath; // Path ke SVG atau Lottie
  final bool isLottie;    // true jika Lottie, false jika SVG
  final IconData? icon;   // Opsional, jika ingin ikon selain gambar

  OnboardingItemModel({
    required this.title,
    required this.description,
    required this.imagePath,
    this.isLottie = false,
    this.icon,
  });
}