import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panal_flutter_app/views/home/home_view.dart';
import 'package:panal_flutter_app/views/warehouse/warehouse_view.dart';
import 'package:panal_flutter_app/views/services/services_view.dart'; // Import ServicesView
import 'package:panal_flutter_app/views/maintenance/maintenance_view.dart';
import 'package:panal_flutter_app/views/system/system_view.dart';
import 'package:panal_flutter_app/utils/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 2; // Set default index to 2 (Home/Inicio)

  // Actual Views
  final List<Widget> _pages = [
    const ServicesView(),
    const WarehouseView(),
    const HomeView(),
    const MaintenanceView(),
    const SystemView(),
  ];

  final List<String> _titles = [
    'Servicios',
    'Almacén',
    'Asistente',
    'Mantenimiento',
    'Sistema',
  ];

  final List<IconData> _icons = [
    Icons.grid_view_outlined,
    Icons.inventory_2_outlined,
    Icons.psychology_outlined,
    Icons.engineering_outlined,
    Icons.settings_outlined,
  ];

  final List<IconData> _activeIcons = [
    Icons.grid_view,
    Icons.inventory_2,
    Icons.psychology,
    Icons.engineering,
    Icons.settings,
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120), // Increased header height
        child: AppBar(
          toolbarHeight: 120,
          title: Text(
            _titles[_currentIndex],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.menuBackground,
          elevation: 0,
          flexibleSpace: ClipRRect(
            child: Stack(
              children: [
                // The SVG as the header background
                SvgPicture.asset(
                  'assets/app/Hexagon.svg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                // Overlay for better text readability
                Container(color: Colors.black.withOpacity(0.2)),
              ],
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      body: Container(
        color: AppColors.menuBackground, // Seamless with AppBar
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.contentBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0),
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ),
        ),
      ),
      // Custom "Pop-out" Navigation Bar
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.headerBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
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
                                  .menuBackground // Changed to Secondary Blue
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.menuBackground.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 5,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                        border: isSelected
                            ? Border.all(
                                color: AppColors.headerBackground,
                                width: 4,
                              ) // "Cutout" effect
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: isSelected
                            ? Colors.white
                            : Colors.black.withOpacity(0.5),
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
                          color: Colors.black.withOpacity(0.5),
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
