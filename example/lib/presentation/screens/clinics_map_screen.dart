import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:ultralytics_yolo_example/presentation/viewmodel/clinics_viewmodel.dart';

class ClinicsMapScreen extends StatefulWidget {
  const ClinicsMapScreen({super.key});

  @override
  State<ClinicsMapScreen> createState() => _ClinicsMapScreenState();
}

class _ClinicsMapScreenState extends State<ClinicsMapScreen> {
  final MapController _mapController = MapController();
  LatLng _initialCenter = const LatLng(37.5665, 126.9780); // 기본값: 서울 시청

  @override
  void initState() {
    super.initState();
    _setCurrentLocation();
  }

  Future<void> _setCurrentLocation() async {
    final location = Location();

    // 사용자에게 위치 권한 사용 안내 다이얼로그
    final agree = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 권한 요청'),
        content: const Text('현재 위치를 기반으로 주변 치과를 추천합니다.\n위치 정보 사용에 동의하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('거부'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('허용'),
          ),
        ],
      ),
    );

    if (agree != true) return; // 사용자가 동의하지 않으면 종료

    if (!await location.serviceEnabled()) {
      if (!await location.requestService()) return;
    }

    var permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) return;
    }

    final locData = await location.getLocation();
    setState(() {
      _initialCenter = LatLng(locData.latitude!, locData.longitude!);
    });
    _mapController.move(_initialCenter, 13.0);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ClinicsViewModel>(context);

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('오류: ${viewModel.errorMessage}', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => viewModel.fetchClinics(),
                child: const Text('다시 불러오기'),
              ),
            ],
          ),
        ),
      );
    }

    final markers = viewModel.clinics.map((clinic) {
      return Marker(
        width: 80,
        height: 80,
        point: LatLng(clinic.lat, clinic.lng),
        child: GestureDetector(
          onTap: () {
            _mapController.move(LatLng(clinic.lat, clinic.lng), _mapController.zoom);
            _showClinicDetails(context, clinic);
          },
          child: Column(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 40),
              Text(clinic.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _setCurrentLocation,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.my_location),
      ),
      body: Container(
        color: const Color(0xFFA9CCF7),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(center: _initialCenter, zoom: 13.0),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.toothapp',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.clinics.length,
                itemBuilder: (context, index) {
                  final clinic = viewModel.clinics[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      title: Text(clinic.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(clinic.address),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _mapController.move(LatLng(clinic.lat, clinic.lng), 15.0);
                        _showClinicDetails(context, clinic);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClinicDetails(BuildContext context, Clinic clinic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(clinic.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text('주소: ${clinic.address}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              Text('전화: ${clinic.phone}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(icon: Icons.call, label: '전화', onPressed: () => Navigator.pop(context)),
                  _buildActionButton(icon: Icons.directions, label: '길찾기', onPressed: () => Navigator.pop(context)),
                  _buildActionButton(icon: Icons.share, label: '공유', onPressed: () => Navigator.pop(context)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            elevation: 0,
          ),
          child: Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

