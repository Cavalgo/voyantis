import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trip_repository.dart';
import 'widgets/budget_breakdown_card.dart';
import 'widgets/itinerary_header.dart';
import 'widgets/timeline_day.dart';

/// Pantalla principal: el itinerario "actual" (perfil fijo) como timeline visual.
/// Escucha [currentTripProvider] y maneja los 3 estados (loading / error / data),
/// incluido "todavía no hay viaje".
class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(currentTripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voyantis'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(currentTripProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Ajustar con el agente'),
        onPressed: () => Navigator.of(context).pushNamed('/chat'),
      ),
      body: tripAsync.when(
        loading: () => const _Centered(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          error: err,
          onRetry: () => ref.invalidate(currentTripProvider),
        ),
        data: (trip) =>
            trip == null ? const _EmptyState() : _Itinerary(trip: trip),
      ),
    );
  }
}

class _Itinerary extends StatelessWidget {
  const _Itinerary({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final currency = trip.summary?.currency ?? '';
    final days = [...trip.days]
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    final budget = trip.budgetBreakdown;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
          children: [
            ItineraryHeader(trip: trip),
            const SizedBox(height: 28),
            for (var i = 0; i < days.length; i++)
              TimelineDay(
                day: days[i],
                currency: currency,
                isLast: i == days.length - 1,
              ),
            if (budget != null &&
                (budget.total > 0 ||
                    budget.flights > 0 ||
                    budget.accommodation > 0 ||
                    budget.activities > 0 ||
                    budget.food > 0 ||
                    budget.buffer > 0)) ...[
              const SizedBox(height: 4),
              BudgetBreakdownCard(budget: budget, currency: currency),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Centered(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.luggage_outlined, size: 56, color: AppColors.muted),
            const SizedBox(height: 16),
            Text('Aún no hay un itinerario',
                style: t.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Habla con el agente para diagnosticar tu viaje y generarlo.',
              style: t.bodyMedium?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Centered(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 52, color: AppColors.muted),
            const SizedBox(height: 16),
            Text('No pudimos cargar tu viaje.',
                style: t.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: t.bodySmall?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(child: child);
}
