// lib/screens/home_screen.dart
import 'package:app_porto/widgets/store_section.dart';
import 'package:flutter/material.dart';
import '../widgets/top_navbar.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/cta_section.dart';
import '../widgets/footer.dart';
import '../widgets/next_match_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const double maxContentWidth = 1200;

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: TopNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
           
            HeroSection(),
             
            FeaturesSection(),
            NextMatchSection(
              // localTeam: 'PortoAmbato',
              // awayTeam: 'El 10',
              // matchDate: DateTime(2025, 8, 12, 15, 30),
              // location: 'Estadio Colegio Santo Domingo',
              // category: 'Sub-12',
            ),
            StoreSection(),
            CTASection(),
            Footer(),
          ],
        ),
      ),
    );
  }
}
