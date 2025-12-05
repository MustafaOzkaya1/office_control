import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

enum DoorCommand { open, close, status }

class ESP32Service {
  final NetworkInfo _networkInfo = NetworkInfo();
  
  String? _espIpAddress;
  String? _espSsid;
  
  void configure({String? ipAddress, String? ssid}) {
    _espIpAddress = ipAddress;
    _espSsid = ssid;
  }

  Future<String?> getCurrentWifiName() async {
    try {
      return await _networkInfo.getWifiName();
    } catch (e) {
      return null;
    }
  }

  Future<bool> isConnectedToEspNetwork() async {
    if (_espSsid == null) return false;
    
    final currentSsid = await getCurrentWifiName();
    if (currentSsid == null) return false;
    
    // Remove quotes from SSID if present
    final cleanCurrentSsid = currentSsid.replaceAll('"', '');
    final cleanEspSsid = _espSsid!.replaceAll('"', '');
    
    return cleanCurrentSsid.toLowerCase() == cleanEspSsid.toLowerCase();
  }

  Future<ESP32Response> sendCommand(DoorCommand command) async {
    if (_espIpAddress == null) {
      return ESP32Response(
        success: false,
        message: 'ESP32 IP adresi yapılandırılmamış.',
      );
    }

    try {
      final uri = Uri.parse('http://$_espIpAddress/door/${command.name}');
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Bağlantı zaman aşımına uğradı');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ESP32Response(
          success: data['success'] ?? true,
          message: data['message'] ?? 'İşlem başarılı',
          data: data,
        );
      } else {
        return ESP32Response(
          success: false,
          message: 'ESP32 yanıt hatası: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      return ESP32Response(
        success: false,
        message: 'ESP32 ile bağlantı zaman aşımına uğradı.',
      );
    } catch (e) {
      return ESP32Response(
        success: false,
        message: 'ESP32 ile iletişim hatası: $e',
      );
    }
  }

  Future<ESP32Response> openDoor() async {
    return sendCommand(DoorCommand.open);
  }

  Future<ESP32Response> closeDoor() async {
    return sendCommand(DoorCommand.close);
  }

  Future<ESP32Response> getDoorStatus() async {
    return sendCommand(DoorCommand.status);
  }

  Future<bool> pingESP32() async {
    if (_espIpAddress == null) return false;

    try {
      final uri = Uri.parse('http://$_espIpAddress/ping');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class ESP32Response {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ESP32Response({
    required this.success,
    required this.message,
    this.data,
  });
}

