import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../button/app_pressable.dart';
import '../icon/app_icon.dart';

/// Sort chip'ten açılan alt panel: seçenekler, seçilinin yanında tik.
/// Seçilen değeri döner; dışarı dokunulup kapatılırsa null.
///
/// Spec 01 chip'e her basışta sıradaki sıralamaya geçen bir DÖNGÜ
/// tanımlıyor; kullanıcı üç seçeneği görüp doğrudan seçebilsin diye
/// bilerek panele çevrildi (bkz. Mülakat notları). Panel Navigator
/// üzerinden açıldığı için telefon çerçevesinin İÇİNDE kalıyor
/// (bkz. app.dart → builder).
Future<T?> showAppSortSheet<T>({
  required BuildContext context,
  required List<(T value, String label)> options,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.white,
    // Liste arkada görünür kalsın: yalnızca hafif bir karartma.
    barrierColor: const Color(0x33171717),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 320),
      reverseDuration: Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    ),
    builder: (context) => _SortSheet<T>(options: options, selected: selected),
  );
}

class _SortSheet<T> extends StatelessWidget {
  const _SortSheet({required this.options, required this.selected});

  final List<(T, String)> options;
  final T selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      8,
      20,
      MediaQuery.paddingOf(context).bottom + 16,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate200,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Sırala', style: AppTextStyle.title18),
        const SizedBox(height: 8),
        for (final (value, label) in options)
          _Option(
            label: label,
            selected: value == selected,
            onTap: () => Navigator.of(context).pop(value),
          ),
      ],
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppPressable(
    onTap: onTap,
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLighter : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyle.label14.copyWith(
                color: selected ? AppColors.primary : AppColors.slate700,
              ),
            ),
          ),
          if (selected)
            const AppIcon('check', size: 20, color: AppColors.primary),
        ],
      ),
    ),
  );
}
