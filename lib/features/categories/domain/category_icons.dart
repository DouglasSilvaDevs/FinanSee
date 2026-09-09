import 'package:flutter/material.dart';

class CategoryIconOption {
  final String key;
  final String label;
  final IconData icon;

  const CategoryIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

const categoryIconOptions = <CategoryIconOption>[
  CategoryIconOption(
    key: 'restaurant',
    label: 'Alimentação',
    icon: Icons.restaurant_outlined,
  ),
  CategoryIconOption(
    key: 'directions_car',
    label: 'Transporte',
    icon: Icons.directions_car_outlined,
  ),
  CategoryIconOption(
    key: 'home',
    label: 'Casa',
    icon: Icons.home_outlined,
  ),
  CategoryIconOption(
    key: 'health',
    label: 'Saúde',
    icon: Icons.medical_services_outlined,
  ),
  CategoryIconOption(
    key: 'sports_esports',
    label: 'Lazer',
    icon: Icons.sports_esports_outlined,
  ),
  CategoryIconOption(
    key: 'school',
    label: 'Educação',
    icon: Icons.school_outlined,
  ),
  CategoryIconOption(
    key: 'shopping_bag',
    label: 'Compras',
    icon: Icons.shopping_bag_outlined,
  ),
  CategoryIconOption(
    key: 'receipt',
    label: 'Contas',
    icon: Icons.receipt_long_outlined,
  ),
  CategoryIconOption(
    key: 'payments',
    label: 'Salário',
    icon: Icons.payments_outlined,
  ),
  CategoryIconOption(
    key: 'work',
    label: 'Trabalho',
    icon: Icons.work_outline_rounded,
  ),
  CategoryIconOption(
    key: 'trending_up',
    label: 'Investimentos',
    icon: Icons.trending_up_rounded,
  ),
  CategoryIconOption(
    key: 'attach_money',
    label: 'Dinheiro',
    icon: Icons.attach_money_rounded,
  ),
  CategoryIconOption(
    key: 'local_gas_station',
    label: 'Combustível',
    icon: Icons.local_gas_station_outlined,
  ),
  CategoryIconOption(
    key: 'subscriptions',
    label: 'Assinaturas',
    icon: Icons.subscriptions_outlined,
  ),
  CategoryIconOption(
    key: 'phone_android',
    label: 'Tecnologia',
    icon: Icons.phone_android_outlined,
  ),
  CategoryIconOption(
    key: 'flight',
    label: 'Viagem',
    icon: Icons.flight_outlined,
  ),
  CategoryIconOption(
    key: 'fitness_center',
    label: 'Academia',
    icon: Icons.fitness_center_outlined,
  ),
  CategoryIconOption(
    key: 'pets',
    label: 'Pets',
    icon: Icons.pets_outlined,
  ),
  CategoryIconOption(
    key: 'redeem',
    label: 'Presentes',
    icon: Icons.redeem_outlined,
  ),
  CategoryIconOption(
    key: 'more_horiz',
    label: 'Outros',
    icon: Icons.more_horiz_rounded,
  ),
];

IconData categoryIconFromKey(
  String? key,
) {
  for (final item in categoryIconOptions) {
    if (item.key == key) {
      return item.icon;
    }
  }

  return Icons.category_outlined;
}
