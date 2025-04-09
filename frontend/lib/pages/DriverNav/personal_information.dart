import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bussin_buses/viewmodels/driver_viewmodel.dart';

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({super.key});

  @override
  _PersonalInformationState createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation> {
  String profilePicUrl = 'https://creazilla-store.fra1.digitaloceanspaces.com/cliparts/7937373/bus-driver-clipart-md.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverViewModel = Provider.of<DriverViewModel>(context, listen: false);
      driverViewModel.fetchPersonalInformation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverViewModel = Provider.of<DriverViewModel>(context);

    /// Ensure the driver profile is fetched before displaying
    if (driverViewModel.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Personal Information")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// If the profile data is null, display an error message
    if (driverViewModel.driverProfile == null) {
      return Scaffold(
        body: Center(child: Text('No profile information available.')),
      );
    }

    final driverProfile = driverViewModel.driverProfile!;

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 70),
            CircleAvatar(
              radius: 120,
              backgroundImage: NetworkImage(profilePicUrl),
            ),
            const SizedBox(height: 40),

            Text("${driverProfile.username}",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),

            Text("Role: ${driverProfile.userType[0].toUpperCase()}${driverProfile.userType.substring(1)}",
                style: const TextStyle(fontSize: 23)),

            const SizedBox(height: 20),

            Text("Date Joined: ${driverProfile.createdAt}",
                style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
