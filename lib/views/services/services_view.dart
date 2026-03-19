import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import './ordenes_tab.dart';
import './tickets_tab.dart';

class ServicesView extends StatelessWidget {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.transparent,
            child: const TabBar(
              indicatorColor: AppColors.secondaryBase,
              labelColor: AppColors.secondaryBase,
              unselectedLabelColor: Colors.grey,
              dividerColor: Colors.black12,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(
                  icon: Icon(Icons.build_circle_outlined),
                  text: 'Órdenes',
                ),
                Tab(
                  icon: Icon(Icons.confirmation_number_outlined),
                  text: 'Tickets',
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                OrdenesTab(),
                TicketsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
