import 'package:flutter/material.dart';

class AppColors {
  //Background colours
  static const bannerGreen = Color(0xFF1E6036);
  static const bgMain = Color(0xFFF9F9F9);
  static const bannerWhite = Color(0xFFFDFDFD);

  //badge widget colours
  static const badgeYellow = Color(0xFFFEF7DC); 
  static const badgeGreen = Color(0xFFD9FBD7); 
  static const badgeRed = Color(0xFFFEE0DF);


  //button colours
  static const btnGreen = Color(0XFF229E3E);
  static const btnGray = Color(0xFFABAFAE);

  //icon colours
  static const iconLightGreen = Color(0xFF8CCB46);
  static const iconRed = Color(0xFFFE6139);
  static const iconBlue = Color(0xFF1383E7);

  //font colours 
  static const fontRed = Color(0xFFF17C7C);     
  static const fontOrange = Color(0xFFD48F68);  
  static const fontGreen = Color(0xFF378C3F);
  static const fontBlack = Color(0xFF000000);  
  static const fontWhite = Color(0xFFFFFFFF);
}

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor:  AppColors.bannerGreen),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bannerGreen,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.btnGreen,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )
    ),
  );
}