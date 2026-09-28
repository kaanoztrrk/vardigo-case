import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_scroll_behavior.dart';
import '../core/widgets/main/phone_frame.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/widget/role_switch.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'router/route.dart';

/// Root widget.
///
/// There's one fixed light theme since the goal is matching the reference
/// PNG, so widgets read colors straight from [AppColors] instead of Theme.
class VardigoApp extends StatelessWidget {
  const VardigoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Vardigo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'Urbanist',
      scaffoldBackgroundColor: AppColors.slate100,
    ),
    routerConfig: router,
    // Lets you scroll by dragging with the mouse.
    scrollBehavior: const AppScrollBehavior(),
    // The phone frame wraps the Navigator here, so snackbars and dialogs
    // open inside the frame too.
    //
    // The frame sits outside the Navigator, so the status bar clock has no
    // Material ancestor and would render with the yellow debug underline.
    // Hence the Material.
    //
    // The role switch lives above the phone because it's a demo control,
    // not part of the app (see RoleSwitch).
    builder: (context, child) => Material(
      color: AppColors.slate100,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RoleSwitch(bloc: getIt<AuthBloc>()),
            const SizedBox(height: 20),
            // Scales the phone down when the browser window is short.
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _Frame(child: child ?? const SizedBox.shrink()),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Phone frame that hides the home indicator on the offers screen.
///
/// Reference 2 has no home indicator and the cards run down to the bezel.
/// The frame is outside the route tree, so it listens to the router
/// directly. The router can notify mid-build, which is why the update
/// waits for the next frame.
class _Frame extends StatefulWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  bool _showHomeIndicator = true;

  @override
  void initState() {
    super.initState();
    router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    final show =
        router.routerDelegate.currentConfiguration.uri.path !=
        AppRoutes.offersView;
    if (show == _showHomeIndicator) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showHomeIndicator = show);
    });
  }

  @override
  Widget build(BuildContext context) =>
      PhoneFrame(showHomeIndicator: _showHomeIndicator, child: widget.child);
}
