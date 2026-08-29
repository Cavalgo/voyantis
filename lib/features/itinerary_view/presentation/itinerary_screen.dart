import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import 'itinerary_providers.dart';
import 'widgets/itinerary_header.dart';
import 'widgets/timeline_day.dart';
import 'widgets/trip_extras.dart';

/// Pantalla del itinerario: el timeline visual del `trip` actual.
/// Maneja los 3 estados de `AsyncValue` (loading / error / data) + vacío.
class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key, this.onOpenChat});

  /// CTA del estado vacío (en layout angosto lleva al chat).
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(currentTripProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: tripAsync.when(
        loading: () => const _Centered(child: CircularProgressIndicator()),
        error: (e, _) => _Centered(
          child: _Message(
            icon: Icons.cloud_off_rounded,
            title: 'No pude cargar el itinerario',
            subtitle: 'Revisa la conexión con Firestore.\n$e',
          ),
        ),
        data: (trip) {
          if (trip == null || trip.days.isEmpty && trip.summary == null) {
            return _Centered(
              child: _Message(
                icon: Icons.map_outlined,
                title: 'Aún no hay itinerario',
                subtitle:
                    'Conversa con Voyantis para diagnosticar tu viaje y generar '
                    'el plan día por día.',
                action: onOpenChat == null
                    ? null
                    : FilledButton.icon(
                        onPressed: onOpenChat,
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Hablar con Voyantis'),
                      ),
              ),
            );
          }
          return _TripBody(trip: trip);
        },
      ),
    );
  }
}

class _TripBody extends StatelessWidget {
  const _TripBody({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final summary = trip.summary ?? const Summary();
    final t = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 720 ? 32.0 : 16.0;
        final contentWidth =
            constraints.maxWidth > 900 ? 760.0 : constraints.maxWidth;

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ItineraryHeader(
                    summary: summary,
                    profile: trip.travelerProfile,
                    status: trip.status,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_profileLine(trip.travelerProfile) != null) ...[
                          Text(
                            _profileLine(trip.travelerProfile)!,
                            style: t.bodyMedium?.copyWith(
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (trip.days.isNotEmpty) ...[
                          _SectionTitle('Día a día'),
                          const SizedBox(height: 16),
                          for (var i = 0; i < trip.days.length; i++)
                            TimelineDay(
                              day: trip.days[i],
                              isLast: i == trip.days.length - 1,
                            ),
                          const SizedBox(height: 12),
                        ],
                        if (trip.flights.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          FlightsSection(flights: trip.flights),
                        ],
                        if (trip.accommodation.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          AccommodationSection(stays: trip.accommodation),
                        ],
                        if (trip.budgetBreakdown != null) ...[
                          const SizedBox(height: 12),
                          BudgetSection(
                            budget: trip.budgetBreakdown!,
                            currency: summary.currency,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _profileLine(TravelerProfile? p) {
    if (p == null) return null;
    final parts = <String>[
      if (p.paceStyle.isNotEmpty) 'ritmo ${p.paceStyle}',
      if (p.socialStyle.isNotEmpty) 'social ${p.socialStyle}',
      if (p.interests.isNotEmpty) p.interests.take(4).join(', '),
    ];
    if (parts.isEmpty) return null;
    return '${parts.join(' · ')}.';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: displayFont(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(32), child: child),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.sienna),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: displayFont(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: AppColors.muted, height: 1.45),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}
