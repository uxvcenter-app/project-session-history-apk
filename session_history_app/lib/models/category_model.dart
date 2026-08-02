import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CategoryModel {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  static const List<CategoryModel> defaults = [
    CategoryModel(id: 'work', name: 'Work', color: AppColors.work, icon: Icons.work_outline),
    CategoryModel(id: 'development', name: 'Développement', color: AppColors.development, icon: Icons.code_rounded),
    CategoryModel(id: 'debug', name: 'Debug', color: AppColors.debug, icon: Icons.bug_report_outlined),
    CategoryModel(id: 'formation', name: 'Formation', color: AppColors.formation, icon: Icons.cast_for_education_outlined),
    CategoryModel(id: 'laboratory', name: 'Laboratoire', color: AppColors.laboratory, icon: Icons.science_outlined),
    CategoryModel(id: 'study', name: 'Study', color: AppColors.study, icon: Icons.school_outlined),
    CategoryModel(id: 'meeting', name: 'Meeting', color: AppColors.meeting, icon: Icons.groups_outlined),
    CategoryModel(id: 'personal', name: 'Personal', color: AppColors.personal, icon: Icons.person_outline),
    CategoryModel(id: 'ideas', name: 'Ideas', color: AppColors.ideas, icon: Icons.lightbulb_outline),
    CategoryModel(id: 'others', name: 'Others', color: AppColors.others, icon: Icons.folder_outlined),
  ];

  static CategoryModel byId(String id) {
    return defaults.firstWhere(
      (c) => c.id == id,
      orElse: () => defaults.last,
    );
  }
}
