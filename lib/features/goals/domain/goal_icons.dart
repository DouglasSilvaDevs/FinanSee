import 'package:flutter/material.dart';

class GoalIconOption {
  final String key;
  final String label;
  final IconData icon;

  const GoalIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

const goalIconOptions = [
  GoalIconOption(
    key: 'target',
    label: 'Meta',
    icon: Icons.flag_outlined,
  ),
  GoalIconOption(
    key: 'computer',
    label: 'Computador',
    icon: Icons.computer_outlined,
  ),
  GoalIconOption(
    key: 'flight',
    label: 'Viagem',
    icon: Icons.flight_outlined,
  ),
  GoalIconOption(
    key: 'car',
    label: 'Carro',
    icon: Icons.directions_car_outlined,
  ),
  GoalIconOption(
    key: 'home',
    label: 'Casa',
    icon: Icons.home_outlined,
  ),
  GoalIconOption(
    key: 'shield',
    label: 'Reserva',
    icon: Icons.shield_outlined,
  ),
  GoalIconOption(
    key: 'school',
    label: 'Estudos',
    icon: Icons.school_outlined,
  ),
  GoalIconOption(
    key: 'phone',
    label: 'Celular',
    icon: Icons.phone_android_outlined,
  ),
  GoalIconOption(
    key: 'redeem',
    label: 'Compra',
    icon: Icons.redeem_outlined,
  ),
  GoalIconOption(
    key: 'savings',
    label: 'Economia',
    icon: Icons.savings_outlined,
  ),
];

IconData goalIconFromKey(
  String? key,
) {
  for (final option in goalIconOptions) {
    if (option.key == key) {
      return option.icon;
    }
  }

  return Icons.flag_outlined;
}
