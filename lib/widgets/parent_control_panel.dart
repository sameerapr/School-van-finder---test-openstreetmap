import 'package:flutter/material.dart';

import '../models/van_stop.dart';

class ParentControlPanel extends StatelessWidget {
  final bool isMorningTrip;
  final bool isChildPickedUp;
  final bool isSelectingHomeOnMap;
  final VanStop selectedChildSchool;
  final List<VanStop> schoolsOnly;
  final String currentPlaceName;
  final String targetEstTime;
  final String targetEstDist;
  final ValueChanged<VanStop> onSchoolChanged;
  final VoidCallback onToggleSetHome;

  const ParentControlPanel({
    super.key,
    required this.isMorningTrip,
    required this.isChildPickedUp,
    required this.isSelectingHomeOnMap,
    required this.selectedChildSchool,
    required this.schoolsOnly,
    required this.currentPlaceName,
    required this.targetEstTime,
    required this.targetEstDist,
    required this.onSchoolChanged,
    required this.onToggleSetHome,
  });

  @override
  Widget build(BuildContext context) {
    // Morning සහ Evening අනුව Status Badge සහ Target Label වෙනස් කිරීම
    String statusBadgeText;
    Color statusBadgeColor;
    String etaTitle;
    bool isGoingToSchool;

    if (isMorningTrip) {
      if (!isChildPickedUp) {
        statusBadgeText = "MORNING: WAITING FOR PICKUP AT HOME";
        statusBadgeColor = Colors.orange.shade800;
        etaTitle = "Van to Your Home:";
        isGoingToSchool = false;
      } else {
        statusBadgeText = "MORNING: CHILD ON BOARD (GOING TO SCHOOL)";
        statusBadgeColor = Colors.blue.shade700;
        etaTitle = "Van to ${selectedChildSchool.shortName}:";
        isGoingToSchool = true;
      }
    } else {
      if (!isChildPickedUp) {
        statusBadgeText = "EVENING: VAN GOING TO PICK FROM SCHOOL";
        statusBadgeColor = Colors.indigo;
        etaTitle = "Van to ${selectedChildSchool.shortName}:";
        isGoingToSchool = true;
      } else {
        statusBadgeText = "EVENING: PICKED FROM SCHOOL (COMING HOME)";
        statusBadgeColor = Colors.green.shade700;
        etaTitle = "Van to Your Home:";
        isGoingToSchool = false;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Child Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusBadgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusBadgeColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isChildPickedUp ? Icons.check_circle : Icons.access_time_filled,
                size: 14,
                color: statusBadgeColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  statusBadgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusBadgeColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. School Dropdown + Set Home Button
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<VanStop>(
                    value: selectedChildSchool,
                    isExpanded: true,
                    items: schoolsOnly.map((school) {
                      return DropdownMenuItem(
                        value: school,
                        child: Text(
                          school.shortName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newSchool) {
                      if (newSchool != null) onSchoolChanged(newSchool);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onToggleSetHome,
              icon: const Icon(Icons.edit_location_alt, size: 18),
              label: Text(isSelectingHomeOnMap ? "Cancel" : "Set Home"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelectingHomeOnMap
                    ? Colors.red
                    : Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 16),

        // 3. Current Place Name
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Van Now At: $currentPlaceName",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 4. Dynamic Distance & Time Box
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isGoingToSchool ? Colors.blue.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  etaTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "$targetEstTime  •  $targetEstDist",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isGoingToSchool
                      ? Colors.blue.shade800
                      : Colors.green.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
