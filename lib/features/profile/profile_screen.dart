import 'package:flutter/material.dart';

import '../../database/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder(
        future: _databaseService.getActiveCycle(),
        builder: (context, snapshot) {
          final cycle = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              const Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFF0082C8),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text('CHIA Professional'),
                  subtitle: Text('Local profile settings will be added in next phase.'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.autorenew),
                  title: const Text('Active Recertification Cycle'),
                  subtitle: Text(
                    cycle == null
                        ? 'No active cycle found'
                        : '${cycle.cycleName}\n${cycle.startDate} to ${cycle.endDate}',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
