import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/path_widgets.dart';

class PathScreen extends StatelessWidget {
  const PathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'My Learning Path',
            subtitle: 'AI-generated roadmap based on your skill gaps.',
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.route_rounded, color: AppColors.purple, size: 20),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Estimated completion: 3 weeks based on your current pace.',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const PathModule(
            completed: true,
            title: 'Database Fundamentals',
            subtitle: 'Relational models, normalization, ACID.',
            progress: 1,
            status: 'Completed',
            icon: Icons.storage_rounded,
          ),
          const PathModule(
            completed: true,
            title: 'Basic SQL Queries',
            subtitle: 'SELECT, JOIN, GROUP BY, filtering.',
            progress: 1,
            status: 'Completed',
            icon: Icons.table_chart_rounded,
          ),
          const PathModule(
            current: true,
            title: 'SQL Joins & Subqueries',
            subtitle: 'Build practical queries using real datasets.',
            progress: .6,
            status: 'In Progress',
            icon: Icons.code_rounded,
          ),
          const PathModule(
            title: 'Window Functions',
            subtitle: 'Advanced analytics and ranking queries.',
            progress: 0,
            status: 'Locked',
            icon: Icons.functions_rounded,
          ),
          const PathModule(
            title: 'Query Optimization',
            subtitle: 'Indexes, execution plans and performance.',
            progress: 0,
            status: 'Locked',
            icon: Icons.speed_rounded,
          ),
        ],
      ),
    );
  }
}
