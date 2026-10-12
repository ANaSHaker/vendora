import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../data/models/order_model.dart';
import '../../../domain/entities/order_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────

class OrderTrackingPage extends StatefulWidget {
  /// The store tracking slug (e.g. "demo-coffee").
  final String token;

  /// Optional order reference to auto-search on load (from ?ref= query param).
  final String? initialRef;

  const OrderTrackingPage({super.key, required this.token, this.initialRef});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  OrderEntity? _order;
  bool _searching = false;
  bool _searched = false;
  bool _notFound = false;
  String? _serverError;
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _checkStaff();
    _focusNode.addListener(() => setState(() {}));
    if (widget.initialRef != null && widget.initialRef!.isNotEmpty) {
      _ctrl.text = widget.initialRef!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkStaff() async {
    final token = await getIt<SecureStorage>().getToken();
    if (mounted) setState(() => _isStaff = token != null);
  }

  Future<void> _search() async {
    final ref = _ctrl.text.trim();
    if (ref.isEmpty) return;
    _focusNode.unfocus();
    setState(() {
      _searching = true;
      _notFound = false;
      _serverError = null;
      _searched = false;
      _order = null;
    });
    try {
      final client = getIt<ApiClient>();
      final response = await client.get<Map<String, dynamic>>(
        ApiEndpoints.orderTrackSearch(widget.token, ref),
      );
      final body = response.data!;
      final data = body.containsKey('data')
          ? body['data'] as Map<String, dynamic>
          : body;
      if (mounted) {
        setState(() {
          _order = OrderModel.fromJson(data);
          _searching = false;
          _searched = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // Staff fallback: search via authenticated orders API when public endpoint fails
      if (_isStaff) {
        final order = await _tryAuthSearch(ref);
        if (order != null && mounted) {
          setState(() {
            _order = order;
            _searching = false;
            _searched = true;
          });
          return;
        }
      }
      if (mounted) {
        final (isNotFound, msg) = _classifyError(e);
        setState(() {
          _searching = false;
          _searched = true;
          _notFound = isNotFound;
          _serverError = isNotFound ? null : msg;
        });
      }
    }
  }

  Future<OrderEntity?> _tryAuthSearch(String ref) async {
    try {
      final response = await getIt<ApiClient>().get<Map<String, dynamic>>(
        ApiEndpoints.orders,
        queryParameters: {'search': ref, 'per_page': '5'},
      );
      final body = response.data!;
      final items = body['data'] as List<dynamic>? ?? [];
      for (final item in items) {
        final map = item as Map<String, dynamic>;
        final itemRef = map['reference'] as String? ?? '';
        if (itemRef == ref || itemRef == '#$ref') {
          return OrderModel.fromJson(map);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  (bool, String?) _classifyError(Object e) {
    if (e is DioException) {
      if (e.response?.statusCode == 404) return (true, null);
      final inner = e.error;
      if (inner is ServerException) return (false, inner.message);
      if (inner is NetworkException) return (false, inner.message);
      if (inner is ValidationException) {
        final first = inner.errors?.values.firstOrNull?.firstOrNull;
        return (false, first ?? inner.message);
      }
      if (inner is UnauthorizedException) return (false, 'Access denied');
      if (inner is ForbiddenException) return (false, 'Permission denied');
      final body = e.response?.data;
      if (body is Map) {
        return (false, body['message'] as String? ?? 'Server error (${e.response?.statusCode})');
      }
      return (false, e.message ?? 'Server error');
    }
    return (false, e.toString());
  }

  Future<void> _reload() async {
    final ref = _ctrl.text.trim();
    if (ref.isEmpty || _order == null) return;
    setState(() => _searching = true);
    try {
      final response = await getIt<ApiClient>().get<Map<String, dynamic>>(
        ApiEndpoints.orderTrackSearch(widget.token, ref),
      );
      final body = response.data!;
      final data = body.containsKey('data')
          ? body['data'] as Map<String, dynamic>
          : body;
      if (mounted) {
        setState(() {
          _order = OrderModel.fromJson(data);
          _searching = false;
        });
      }
    } catch (_) {
      if (_isStaff) {
        final ref = _ctrl.text.trim();
        final order = await _tryAuthSearch(ref);
        if (order != null && mounted) {
          setState(() { _order = order; _searching = false; });
          return;
        }
      }
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_order == null) return;
    try {
      await getIt<ApiClient>().patch<dynamic>(
        ApiEndpoints.orderStatus(_order!.id),
        data: {
          'status': status,
          if (_order!.fulfillmentStatus != null)
            'fulfillment_status': _order!.fulfillmentStatus,
        },
      );
      await _reload();
      if (mounted) AppSnackbar.success(context, AppLocalizations.of(context).success);
    } catch (e) {
      if (mounted) {
        final (_, msg) = _classifyError(e);
        AppSnackbar.error(context, msg ?? 'Error');
      }
    }
  }

  Future<void> _updateFulfillment(String status) async {
    if (_order == null) return;
    try {
      // Backend uses /status endpoint for both fields; /fulfillment only supports GET
      await getIt<ApiClient>().patch<dynamic>(
        ApiEndpoints.orderStatus(_order!.id),
        data: {
          'status': _order!.status,
          'fulfillment_status': status,
        },
      );
      await _reload();
      if (mounted) AppSnackbar.success(context, AppLocalizations.of(context).success);
    } catch (e) {
      if (mounted) {
        final (_, msg) = _classifyError(e);
        AppSnackbar.error(context, msg ?? 'Error');
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? const Color(0xFF080D1A) : const Color(0xFFF0F4FF);
    final mq = MediaQuery.of(context);
    final isDesktop = mq.size.width >= 960;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _HeroHeader(isDark: isDark, cs: cs, l10n: l10n, safeTop: mq.padding.top),
          Expanded(
            child: isDesktop
                ? _buildDesktopLayout(l10n, isDark, cs, mq)
                : _buildMobileLayout(l10n, isDark, cs, mq),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(AppLocalizations l10n, bool isDark, ColorScheme cs, MediaQueryData mq) {
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: search + state cards ──────────────────────────────────────
        Flexible(
          flex: 4,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                _SearchCard(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  searching: _searching,
                  isDark: isDark,
                  cs: cs,
                  l10n: l10n,
                  onSubmit: _search,
                  onClear: () => setState(() {}),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: _buildStateCards(l10n, isDark, cs),
                ),
                const SizedBox(height: AppSpacing.xl),
                _Footer(cs: cs, isDark: isDark, l10n: l10n),
                SizedBox(height: mq.padding.bottom + AppSpacing.lg),
              ],
            ),
          ),
        ),

        // ── Divider ─────────────────────────────────────────────────────────
        VerticalDivider(width: 1, thickness: 1, color: border),

        // ── Right: order result ──────────────────────────────────────────────
        Flexible(
          flex: 6,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _buildDesktopResultPanel(l10n, isDark, cs, mq),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopResultPanel(AppLocalizations l10n, bool isDark, ColorScheme cs, MediaQueryData mq) {
    if (_searching) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
        child: Center(
          child: SizedBox(
            width: 36, height: 36,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
          ),
        ),
      );
    }
    if (!_searched || _order == null) {
      return _buildEmptyDesktopPanel(isDark, cs, l10n);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrderResultCard(order: _order!, isDark: isDark, cs: cs, l10n: l10n),
        if (_isStaff) ...[
          const SizedBox(height: AppSpacing.md),
          _StaffControlsCard(
            order: _order!,
            isDark: isDark,
            cs: cs,
            l10n: l10n,
            onStatusChange: _updateStatus,
            onFulfillmentChange: _updateFulfillment,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _Footer(cs: cs, isDark: isDark, l10n: l10n),
        SizedBox(height: mq.padding.bottom + AppSpacing.lg),
      ],
    );
  }

  Widget _buildEmptyDesktopPanel(bool isDark, ColorScheme cs, AppLocalizations l10n) {
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl * 3),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.06),
              border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
            ),
            child: Icon(Icons.local_shipping_outlined, size: 42, color: cs.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.trackYourOrder,
            style: AppTextStyles.h6.copyWith(
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.trackingSubtitle,
            style: AppTextStyles.bodySm.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Returns only state (not-found / server-error / unavailable) cards, no result card
  Widget _buildStateCards(AppLocalizations l10n, bool isDark, ColorScheme cs) {
    if (_searching || !_searched) return const SizedBox.shrink();
    if (_serverError != null) {
      return _ServerErrorCard(error: _serverError!, isDark: isDark, onRetry: _search, l10n: l10n);
    }
    if (widget.token.isEmpty) return _UnavailableCard(isDark: isDark, l10n: l10n);
    if (_notFound) return _NotFoundCard(isDark: isDark, l10n: l10n);
    return const SizedBox.shrink();
  }

  Widget _buildMobileLayout(AppLocalizations l10n, bool isDark, ColorScheme cs, MediaQueryData mq) {
    final isWide = mq.size.width >= 640;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 0 : AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              _SearchCard(
                controller: _ctrl,
                focusNode: _focusNode,
                searching: _searching,
                isDark: isDark,
                cs: cs,
                l10n: l10n,
                onSubmit: _search,
                onClear: () => setState(() {}),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: _buildResults(l10n, isDark, cs),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Footer(cs: cs, isDark: isDark, l10n: l10n),
              SizedBox(height: mq.padding.bottom + AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n, bool isDark, ColorScheme cs) {
    if (!_searched && !_searching) return const SizedBox.shrink();

    if (_searching) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
        child: Column(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: cs.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (_serverError != null) {
      return _ServerErrorCard(
        error: _serverError!,
        isDark: isDark,
        onRetry: _search,
        l10n: l10n,
      );
    }

    if (widget.token.isEmpty) {
      return _UnavailableCard(isDark: isDark, l10n: l10n);
    }

    if (_notFound) {
      return _NotFoundCard(isDark: isDark, l10n: l10n);
    }

    if (_order != null) {
      return Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          _OrderResultCard(order: _order!, isDark: isDark, cs: cs, l10n: l10n),
          if (_isStaff) ...[
            const SizedBox(height: AppSpacing.md),
            _StaffControlsCard(
              order: _order!,
              isDark: isDark,
              cs: cs,
              l10n: l10n,
              onStatusChange: _updateStatus,
              onFulfillmentChange: _updateFulfillment,
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  final AppLocalizations l10n;
  const _Footer({required this.cs, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_rounded, size: 13, color: cs.primary.withValues(alpha: 0.6)),
        const SizedBox(width: 5),
        Text(
          l10n.poweredByVendora,
          style: AppTextStyles.bodyXs.copyWith(color: muted),
        ),
      ],
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;
  final AppLocalizations l10n;
  final double safeTop;

  const _HeroHeader({
    required this.isDark,
    required this.cs,
    required this.l10n,
    required this.safeTop,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, safeTop + 36, 24, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  cs.primary.withValues(alpha: 0.22),
                  cs.primary.withValues(alpha: 0.08),
                  const Color(0xFF080D1A),
                ]
              : [
                  cs.primary.withValues(alpha: 0.14),
                  cs.primary.withValues(alpha: 0.04),
                  const Color(0xFFF0F4FF),
                ],
        ),
        border: Border(
          bottom: BorderSide(
            color: cs.primary.withValues(alpha: isDark ? 0.15 : 0.10),
          ),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Background radial glow
          Positioned(
            top: -40, right: isWide ? 80 : -20,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                    cs.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Column(
            children: [
              // Dual-ring icon
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                  ),
                  // Inner filled circle
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.30),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.25),
                          blurRadius: 28,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      size: 30,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                l10n.trackYourOrder,
                style: (isWide ? AppTextStyles.h3 : AppTextStyles.h4).copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.trackingSubtitle,
                style: AppTextStyles.bodySm.copyWith(color: muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Search Card ──────────────────────────────────────────────────────────────

class _SearchCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final bool isDark;
  final ColorScheme cs;
  final AppLocalizations l10n;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const _SearchCard({
    required this.controller,
    required this.focusNode,
    required this.searching,
    required this.isDark,
    required this.cs,
    required this.l10n,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final inputBg = isDark ? AppColors.darkMuted : const Color(0xFFF8FAFC);
    final hasFocus = focusNode.hasFocus;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: AppRadius.brLg,
              border: Border.all(
                color: hasFocus ? cs.primary : border,
                width: hasFocus ? 1.5 : 1.0,
              ),
              boxShadow: hasFocus
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.12),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !searching,
                      style: AppTextStyles.labelMd.copyWith(color: fg),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixText: '#',
                        prefixStyle: AppTextStyles.labelMd.copyWith(
                          color: hasFocus ? cs.primary : muted,
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: l10n.enterOrderHint,
                        hintStyle: AppTextStyles.bodySm.copyWith(color: muted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(
                          left: 14,
                          right: 8,
                          top: 14,
                          bottom: 14,
                        ),
                      ),
                      onSubmitted: (_) => onSubmit(),
                      onChanged: (_) => onClear(),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 16, color: muted),
                      onPressed: () {
                        controller.clear();
                        onClear();
                        focusNode.requestFocus();
                      },
                      splashRadius: 20,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // Button
          AppButton.primary(
            label: l10n.trackOrderBtn,
            isLoading: searching,
            fullWidth: true,
            onPressed: searching ? null : onSubmit,
            trailing: searching
                ? null
                : const Icon(Icons.search_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─── Order Result Card ────────────────────────────────────────────────────────

class _OrderResultCard extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final ColorScheme cs;
  final AppLocalizations l10n;

  const _OrderResultCard({
    required this.order,
    required this.isDark,
    required this.cs,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brXl,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            _CardHeader(order: order, isDark: isDark, cs: cs, l10n: l10n),

            // ── Fulfillment progress ─────────────────────────────────────
            if (order.fulfillmentStatus != null) ...[
              Divider(height: 1, color: border),
              _ProgressSection(
                status: order.fulfillmentStatus!,
                isDark: isDark,
                cs: cs,
                l10n: l10n,
              ),
            ],

            // ── Order details ─────────────────────────────────────────
            Divider(height: 1, color: border),
            _DetailsSection(order: order, isDark: isDark, l10n: l10n),

            // ── Items ────────────────────────────────────────────────────
            if (order.items.isNotEmpty) ...[
              Divider(height: 1, color: border),
              _ItemsSection(order: order, isDark: isDark, l10n: l10n),
            ],

            // ── Totals ───────────────────────────────────────────────────
            Divider(height: 1, color: border),
            _TotalsSection(order: order, isDark: isDark, cs: cs, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final ColorScheme cs;
  final AppLocalizations l10n;

  const _CardHeader({
    required this.order,
    required this.isDark,
    required this.cs,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.06),
            cs.primary.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.reference,
                  style: AppTextStyles.h5.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: muted),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.orderedOn} ${DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt.toLocal())}',
                      style: AppTextStyles.bodyXs.copyWith(color: muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusPill(status: order.status, l10n: l10n),
        ],
      ),
    );
  }
}

// ─── Progress Section ─────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final String status;
  final bool isDark;
  final ColorScheme cs;
  final AppLocalizations l10n;

  const _ProgressSection({
    required this.status,
    required this.isDark,
    required this.cs,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final steps = [
      (key: 'preparing', label: l10n.fulfillPreparing, icon: Icons.inventory_2_outlined,
          desc: l10n.fulfillPreparingDesc),
      (key: 'ready', label: l10n.fulfillReady, icon: Icons.storefront_outlined,
          desc: l10n.fulfillReadyDesc),
      (key: 'completed', label: l10n.fulfillCompleted, icon: Icons.check_circle_outline_rounded,
          desc: l10n.fulfillCompletedDesc),
    ];

    final currentIdx = steps.indexWhere((s) => s.key == status);
    final isCancelled = status == 'cancelled';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                l10n.orderProgress.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Step row
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              // Connector line
              if (i.isOdd) {
                final stepIdx = i ~/ 2;
                final isCompleted = stepIdx < currentIdx && !isCancelled;
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 28),
                    decoration: BoxDecoration(
                      gradient: isCompleted
                          ? LinearGradient(colors: [cs.primary, cs.primary])
                          : null,
                      color: isCompleted ? null : border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }

              final stepIdx = i ~/ 2;
              final isDone = stepIdx <= currentIdx && !isCancelled;
              final isCurrent = stepIdx == currentIdx && !isCancelled;
              final step = steps[stepIdx];

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCancelled
                          ? AppColors.statusCancelledBg
                          : isDone
                              ? cs.primary
                              : surface,
                      border: Border.all(
                        color: isCancelled
                            ? AppColors.statusCancelled
                            : isCurrent
                                ? cs.primary
                                : border,
                        width: isCurrent ? 2 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.28),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isCancelled ? Icons.block_rounded : step.icon,
                      size: 20,
                      color: isCancelled
                          ? AppColors.statusCancelled
                          : isDone
                              ? Colors.white
                              : muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent ? cs.primary : muted,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              );
            }),
          ),

          // Status description badge
          if (currentIdx >= 0 && !isCancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: AppRadius.brMd,
                border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      steps[currentIdx].desc,
                      style: AppTextStyles.bodySm.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isCancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.statusCancelledBg,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: AppColors.statusCancelled.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.block_rounded, size: 14, color: AppColors.statusCancelled),
                  const SizedBox(width: 8),
                  Text(
                    l10n.fulfillCancelled,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.statusCancelled,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Details Section ──────────────────────────────────────────────────────────

class _DetailsSection extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final AppLocalizations l10n;

  const _DetailsSection({
    required this.order,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (order.customerName != null) (l10n.customer, order.customerName!),
      (l10n.paymentMethod, _paymentLabel(order.paymentMethod, l10n)),
      if (order.branchName.isNotEmpty) (l10n.branch, order.branchName),
      if (order.note != null && order.note!.isNotEmpty) (l10n.note, order.note!),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: rows.map((r) => _DetailRow(label: r.$1, value: r.$2, isDark: isDark)).toList(),
      ),
    );
  }

  String _paymentLabel(String method, AppLocalizations l10n) => switch (method) {
    'cash' => l10n.cash,
    'card' => l10n.card,
    'bank_transfer' => l10n.bankTransfer,
    _ => method,
  };
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _DetailRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(color: muted)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.labelSm.copyWith(color: fg),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Items Section ────────────────────────────────────────────────────────────

class _ItemsSection extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final AppLocalizations l10n;

  const _ItemsSection({
    required this.order,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 14, color: muted),
              const SizedBox(width: 6),
              Text(
                l10n.itemsOrdered.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: muted,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(order.items.length, (i) {
            final item = order.items[i];
            return Column(
              children: [
                if (i > 0) Divider(height: 1, color: border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: AppRadius.brSm,
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}×',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: AppTextStyles.labelSm.copyWith(color: fg),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.sku != null)
                              Text(
                                'SKU: ${item.sku}',
                                style: AppTextStyles.bodyXs.copyWith(color: muted),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        AppFormatters.currency(item.lineTotal),
                        style: AppTextStyles.labelSm.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Totals Section ───────────────────────────────────────────────────────────

class _TotalsSection extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final ColorScheme cs;
  final AppLocalizations l10n;

  const _TotalsSection({
    required this.order,
    required this.isDark,
    required this.cs,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _TotalRow(label: l10n.subtotal, value: AppFormatters.currency(order.subtotal), fg: muted),
          if (order.discountAmount > 0)
            _TotalRow(
              label: l10n.discount,
              value: '-${AppFormatters.currency(order.discountAmount)}',
              fg: AppColors.success,
            ),
          _TotalRow(label: l10n.tax, value: AppFormatters.currency(order.taxAmount), fg: muted),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Divider(height: 1, color: border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.total,
                style: AppTextStyles.labelMd.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.brFull,
                  border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  AppFormatters.currency(order.total),
                  style: AppTextStyles.labelMd.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color fg;
  const _TotalRow({required this.label, required this.value, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(color: fg)),
          Text(value, style: AppTextStyles.labelSm.copyWith(color: fg)),
        ],
      ),
    );
  }
}

// ─── Status Pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;
  const _StatusPill({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = switch (status) {
      'paid'       => (AppColors.statusPaid, AppColors.statusPaidBg, l10n.statusPaid),
      'pending'    => (AppColors.statusPending, AppColors.statusPendingBg, l10n.statusPending),
      'completed'  => (AppColors.statusCompleted, AppColors.statusCompletedBg, l10n.statusCompleted),
      'refunded'   => (AppColors.statusRefunded, AppColors.statusRefundedBg, l10n.statusRefunded),
      'cancelled'  => (AppColors.statusCancelled, AppColors.statusCancelledBg, l10n.statusCancelled),
      'processing' => (AppColors.statusApproved, AppColors.statusApprovedBg, l10n.statusProcessing),
      _            => (AppColors.statusDraft, AppColors.statusDraftBg, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brFull,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Staff Controls Card ──────────────────────────────────────────────────────

class _StaffControlsCard extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  final ColorScheme cs;
  final AppLocalizations l10n;
  final Future<void> Function(String) onStatusChange;
  final Future<void> Function(String) onFulfillmentChange;

  const _StaffControlsCard({
    required this.order,
    required this.isDark,
    required this.cs,
    required this.l10n,
    required this.onStatusChange,
    required this.onFulfillmentChange,
  });

  @override
  State<_StaffControlsCard> createState() => _StaffControlsCardState();
}

class _StaffControlsCardState extends State<_StaffControlsCard> {
  late String _status;
  late String? _fulfillment;
  bool _savingStatus = false;
  bool _savingFulfillment = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
    _fulfillment = widget.order.fulfillmentStatus;
  }

  @override
  void didUpdateWidget(_StaffControlsCard old) {
    super.didUpdateWidget(old);
    if (old.order.status != widget.order.status) _status = widget.order.status;
    if (old.order.fulfillmentStatus != widget.order.fulfillmentStatus) {
      _fulfillment = widget.order.fulfillmentStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppColors.darkSurface : AppColors.surface;
    final border = widget.isDark ? AppColors.darkBorder : AppColors.border;
    final fg = widget.isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = widget.isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final l10n = widget.l10n;

    final statusOptions = [
      (value: 'paid', label: l10n.statusPaid),
      (value: 'pending', label: l10n.statusPending),
      (value: 'processing', label: l10n.statusProcessing),
      (value: 'completed', label: l10n.statusCompleted),
      (value: 'cancelled', label: l10n.statusCancelled),
      (value: 'refunded', label: l10n.statusRefunded),
    ];

    final fulfillmentOptions = [
      (value: 'preparing', label: l10n.fulfillPreparing),
      (value: 'ready', label: l10n.fulfillReady),
      (value: 'completed', label: l10n.fulfillCompleted),
      (value: 'cancelled', label: l10n.fulfillCancelled),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: widget.cs.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: widget.cs.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brXl,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.cs.primary.withValues(alpha: 0.08),
                    widget.cs.primary.withValues(alpha: 0.03),
                  ],
                ),
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.manage_accounts_rounded,
                      size: 18,
                      color: widget.cs.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.staffControls,
                        style: AppTextStyles.labelMd.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.manageOrder,
                        style: AppTextStyles.bodyXs.copyWith(color: muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _StaffDropdown(
                    label: l10n.orderStatus.toUpperCase(),
                    value: _status,
                    options: statusOptions,
                    saving: _savingStatus,
                    isDark: widget.isDark,
                    onChanged: (v) async {
                      if (v == null || v == _status || _savingStatus) return;
                      setState(() { _status = v; _savingStatus = true; });
                      await widget.onStatusChange(v);
                      if (mounted) setState(() => _savingStatus = false);
                    },
                  ),
                  if (widget.order.fulfillmentStatus != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _StaffDropdown(
                      label: l10n.fulfillmentStatus.toUpperCase(),
                      value: _fulfillment ?? 'preparing',
                      options: fulfillmentOptions,
                      saving: _savingFulfillment,
                      isDark: widget.isDark,
                      onChanged: (v) async {
                        if (v == null || v == _fulfillment || _savingFulfillment) return;
                        setState(() { _fulfillment = v; _savingFulfillment = true; });
                        await widget.onFulfillmentChange(v);
                        if (mounted) setState(() => _savingFulfillment = false);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<({String value, String label})> options;
  final bool saving;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _StaffDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.saving,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final bg = isDark ? AppColors.darkMuted : const Color(0xFFF8FAFC);
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: muted,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
          child: DropdownButton<String>(
            value: value,
            items: options
                .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
                .toList(),
            onChanged: saving ? null : onChanged,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            style: AppTextStyles.labelSm.copyWith(color: fg),
            dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
            icon: saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.expand_more_rounded, color: muted, size: 20),
          ),
        ),
      ],
    );
  }
}

// ─── State Cards ──────────────────────────────────────────────────────────────

class _NotFoundCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  const _NotFoundCard({required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.brXl,
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.destructive.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 28,
                color: AppColors.destructive,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.orderNotFound,
              style: AppTextStyles.h6.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.orderNotFoundDesc,
              style: AppTextStyles.bodySm.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerErrorCard extends StatelessWidget {
  final String error;
  final bool isDark;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  const _ServerErrorCard({
    required this.error,
    required this.isDark,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.brXl,
          border: Border.all(color: AppColors.destructive.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: AppColors.destructive),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: AppTextStyles.bodySm.copyWith(color: fg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.outline(
              label: l10n.retry,
              onPressed: onRetry,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  const _UnavailableCard({required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.brXl,
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.link_off_rounded, size: 36, color: muted),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.trackingUnavailable,
              style: AppTextStyles.h6.copyWith(color: fg),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.trackingUnavailableDesc,
              style: AppTextStyles.bodySm.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
