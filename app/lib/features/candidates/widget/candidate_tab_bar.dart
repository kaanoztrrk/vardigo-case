import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_style.dart';
import '../data/enum/candidate_tab.dart';

/// "%100 Eşleşme (26)" | "Benzer Personeller (16)" segmented tab.
///
/// The spec says "track p 4, radius 999", but the reference PNG has no
/// track padding and ~12 px corners. The PNG takes priority, so I followed
/// that.
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

  static const _duration = Duration(milliseconds: 260);

  // One active pill that slides between the tabs, with the labels on top
  // fading between colors.
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.slate100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: AnimatedAlign(
            duration: _duration,
            curve: Curves.easeOutCubic,
            alignment: active == CandidateTab.perfect
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.tabActiveMatches,
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            _label(CandidateTab.perfect, '%100 Eşleşme ($totalPerfect)'),
            _label(CandidateTab.similar, 'Benzer Personeller ($totalSimilar)'),
          ],
        ),
      ],
    ),
  );

  Widget _label(CandidateTab tab, String label) => Expanded(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: AnimatedDefaultTextStyle(
          duration: _duration,
          style: AppTextStyle.caption12Medium.copyWith(
            color: tab == active ? AppColors.white : AppColors.slate500,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ),
  );
}
