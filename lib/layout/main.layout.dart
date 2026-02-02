import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panal_flutter_app/views/home/home_view.dart';
import 'package:panal_flutter_app/views/warehouse/warehouse_view.dart';
import 'package:panal_flutter_app/views/tools/tools_view.dart';
import 'package:panal_flutter_app/views/maintenance/maintenance_view.dart';
import 'package:panal_flutter_app/utils/app_colors.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Actual Views
  final List<Widget> _pages = [
    const HomeView(),
    const WarehouseView(),
    const ToolsView(),
    const MaintenanceView(),
  ];

  final List<String> _titles = [
    'Inicio',
    'Almacén',
    'Herramientas',
    'Mantenimiento',
  ];

  final List<IconData> _icons = [
    Icons.home_outlined,
    Icons.inventory_2_outlined,
    Icons.build_outlined,
    Icons.engineering_outlined,
  ];

  final List<IconData> _activeIcons = [
    Icons.home,
    Icons.inventory_2,
    Icons.build,
    Icons.engineering,
  ];

  @override
  Widget build(BuildContext context) {
    // Ensure the status bar is distinct (transparent with dark icons for white header)
    // "no sea parte de la app" interpreted as clear separation via system UI style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:
            Colors.transparent, // Let background show through (or white)
        statusBarIconBrightness:
            Brightness.dark, // Dark icons for white background
        statusBarBrightness: Brightness.light, // iOS
      ),
    );

    return Scaffold(
      // Extended body not needed if we want distinct separation, but typical for transparent status bar
      // using standard app bar color
      backgroundColor: AppColors.contentBackground,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.headerBackground,
        elevation: 0,
        // Explicit system overlay style for the app bar
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: IndexedStack(index: _currentIndex, children: _pages),
        ),
      ),
      // Custom "Pop-out" Navigation Bar
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.menuBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _icons.asMap().entries.map((entry) {
            final int index = entry.key;
            final bool isSelected = _currentIndex == index;
            final IconData icon = isSelected
                ? _activeIcons[index]
                : _icons[index];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                // If selected, move it up to create the "sobresale" effect
                transform: Matrix4.translationValues(
                  0,
                  isSelected ? -25 : 0,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Container
                    Container(
                      padding: EdgeInsets.all(isSelected ? 12 : 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors
                                  .secondaryBase // Changed to Secondary Blue
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.secondaryBase.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                        border: isSelected
                            ? Border.all(
                                color: AppColors.menuBackground,
                                width: 4,
                              ) // "Cutout" effect
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                    // Optional label, hidden when selected if desired, or always shown
                    if (!isSelected) ...[
                      const SizedBox(height: 2),
                      Text(
                        // Shorten titles for nav bar
                        _titles[index].length > 8
                            ? '${_titles[index].substring(0, 6)}..'
                            : _titles[_indexTitle(index)],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Helper just to match titles logic slightly differently if needed
  int _indexTitle(int index) => index;
}
