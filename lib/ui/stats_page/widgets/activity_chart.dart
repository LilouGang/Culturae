import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityChart extends StatelessWidget {
  final Map<DateTime, Map<String, int>> data;

  const ActivityChart({super.key, required this.data});

  Color getColorForTheme(String theme) {
    final Map<String, Color> themeColors = {
      'Animaux': const Color(0xFFF97316), // Orange
      'Art': const Color(0xFFEC4899), // Rose/Fuchsia
      'Divers': const Color(0xFF64748B), // Gris Bleu
      'Divertissement': const Color(0xFF8B5CF6), // Violet
      'Géographie': const Color(0xFF0EA5E9), // Bleu Ciel
      'Histoire': const Color(0xFFEAB308), // Jaune Or/Ambre
      'Nature': const Color(0xFF22C55E), // Vert
      'Science': const Color(0xFF06B6D4), // Cyan
      'Société': const Color(0xFFF43F5E), // Rouge/Rose doux
      'Technologie': const Color(0xFF3B82F6), // Bleu Électrique
      'Test': const Color(0xFF9CA3AF), // Gris
    };
    if (themeColors.containsKey(theme)) return themeColors[theme]!;
    return Colors.primaries[theme.hashCode.abs() % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = data.keys.toList()..sort();
    
    // Pour la légende : on collecte les thèmes qui ont des données
    final Set<String> activeThemes = {};

    // 1. Calcul du vrai maximum et récupération des thèmes
    double trueMaxY = 0;
    for (var dayStats in data.values) {
      int dailyTotal = dayStats.values.fold(0, (sum, val) => sum + val);
      if (dailyTotal > trueMaxY) trueMaxY = dailyTotal.toDouble();
      
      // On ajoute les thèmes actifs au set
      dayStats.forEach((key, value) {
        if (value > 0) activeThemes.add(key);
      });
    }

    if (trueMaxY == 0) trueMaxY = 5;

    // 2. Intervalle EXACT
    double interval = trueMaxY / 4;
    
    // 3. Hauteur du graphique
    double chartLimitY = trueMaxY * 1.15;

    List<BarChartGroupData> barGroups = [];
    int index = 0;

    for (var date in sortedDates) {
      final dayStats = data[date]!;
      double currentY = 0;
      List<BarChartRodStackItem> stackItems = [];
      final sortedThemes = dayStats.keys.toList()..sort();

      for (var theme in sortedThemes) {
        int count = dayStats[theme]!;
        if (count > 0) {
          stackItems.add(BarChartRodStackItem(
            currentY,
            currentY + count,
            getColorForTheme(theme),
            borderSide: const BorderSide(color: Colors.white, width: 1.5), 
          ));
          currentY += count;
        }
      }

      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: currentY,
              rodStackItems: stackItems,
              color: Colors.transparent,
              width: 14, 
              borderRadius: BorderRadius.circular(50), 
              backDrawRodData: BackgroundBarChartRodData(show: false),
            ),
          ],
        ),
      );
      index++;
    }

    // On trie les thèmes par ordre alphabétique pour la légende
    final sortedActiveThemes = activeThemes.toList()..sort();

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: chartLimitY,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(enabled: false),
              
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value <= 0) return const SizedBox();
                      if (value > trueMaxY) return const SizedBox();

                      int valueToShow = value.round();
                      if ((value - trueMaxY).abs() < 1) {
                        valueToShow = trueMaxY.toInt();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          valueToShow.toString(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8), 
                            fontSize: 10, 
                            fontWeight: FontWeight.w600
                          )
                        ),
                      );
                    },
                  ),
                ),
                
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= sortedDates.length || value.toInt() < 0) return const SizedBox();
                      final date = sortedDates[value.toInt()];
                      final isToday = DateTime.now().day == date.day && DateTime.now().month == date.month;

                      return SideTitleWidget(
                        meta: meta,
                        space: 12,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('E', 'fr_FR').format(date).substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: isToday ? Colors.blueAccent : const Color(0xFF64748B), 
                                  fontWeight: isToday ? FontWeight.w900 : FontWeight.bold, 
                                  fontSize: 11
                                ),
                              ),
                              if (isToday)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  width: 4, height: 4,
                                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval, 
                getDrawingHorizontalLine: (value) => FlLine(
                  color: const Color(0xFFE2E8F0), 
                  strokeWidth: 1, 
                  dashArray: [4, 4], 
                ),
              ),
              barGroups: barGroups,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // --- LÉGENDE DES COULEURS ---
        Wrap(
          spacing: 16,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: sortedActiveThemes.map((theme) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: getColorForTheme(theme),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  theme,
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}