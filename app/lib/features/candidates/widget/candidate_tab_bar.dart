import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_style.dart';
import '../data/enum/candidate_tab.dart';

/// "%100 Eşleşme (26)" | "Benzer Personeller (16)" segmented tab.
///
/// Spec "track p 4, radius 999" diyor; referans PNG'de track'in iç
/// boşluğu yok ve köşeler ~12 px. Öncelik sırası PNG > spec, o yüzden
/// referans uygulandı.
class CandidateTabBar extends StatelessWidget {
  const CandidateTabBar({
    super.key,
    required this.active,
    required this.totalPerfect,
    required this.totalSimilar,
    required this.onChanged,
  });

  final CandidateTab active;
  final int totalPerfect;
  final int totalSimilar;
  final ValueChanged<CandidateTab> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.slate100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        _pill(CandidateTab.perfect, '%100 Eşleşme ($totalPerfect)'),
        _pill(CandidateTab.similar, 'Benzer Personeller ($totalSimilar)'),
      ],
    ),
  );

  Widget _pill(CandidateTab tab, String label) {
    final isActive = tab == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive ? AppShadows.tabActiveMatches : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.caption12Medium.copyWith(
              color: isActive ? AppColors.white : AppColors.slate500,
            ),
          ),
        ),
      ),
    );
  }
}
