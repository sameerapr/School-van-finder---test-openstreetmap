import 'package:flutter/material.dart';

import '../models/van_stop.dart';

class DriverControlPanel extends StatelessWidget {
  final bool isMorningTrip;
  final bool isChildPickedUp;
  final List<VanStop> activeStops;
  final String currentPlaceName;
  final VoidCallback onTogglePickupStatus;
  final ValueChanged<VanStop> onJumpToStop;

  const DriverControlPanel({
    super.key,
    required this.isMorningTrip,
    required this.isChildPickedUp,
    required this.activeStops,
    required this.currentPlaceName,
    required this.onTogglePickupStatus,
    required this.onJumpToStop,
  });

  @override
  Widget build(BuildContext context) {
    // Morning සහ Evening අනුව Button එකේ Text එක වෙනස් වේ
    String buttonLabel;
    if (isMorningTrip) {
      buttonLabel = isChildPickedUp
          ? "Picked Up from Home ✓ (Tap to Undo)"
          : "Mark Child Picked Up from Home";
    } else {
      buttonLabel = isChildPickedUp
          ? "Picked Up from School ✓ (Tap to Undo)"
          : "Mark Child Picked Up from School";
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Morning සහ Evening දෙකටම අදාළ Pickup Button එක
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTogglePickupStatus,
            icon: Icon(isChildPickedUp ? Icons.undo : Icons.how_to_reg),
            label: Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isChildPickedUp
                  ? Colors.green.shade700
                  : Colors.orange.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 2. Quick Jump Dropdown (GPS නැතුව Van එක නැවතුමකට ගෙනයාමට)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.indigo.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<VanStop>(
              hint: const Text("Jump Van to a Stop / School..."),
              isExpanded: true,
              items: activeStops.map((stop) {
                return DropdownMenuItem(
                  value: stop,
                  child: Text(stop.name, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (selectedStop) {
                if (selectedStop != null) onJumpToStop(selectedStop);
              },
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 3. Current Road Info
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.indigo),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Current Road: $currentPlaceName",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
