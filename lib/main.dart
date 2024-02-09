import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SerialCommunicationScreen(),
    );
  }
}

class SerialCommunicationScreen extends StatefulWidget {
  const SerialCommunicationScreen({super.key});

  @override
  SerialCommunicationScreenState createState() =>
      SerialCommunicationScreenState();
}

class SerialCommunicationScreenState extends State<SerialCommunicationScreen> {
  late UsbPort port;
  final TextEditingController messageController = TextEditingController();
  final TextEditingController outputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isNotEmpty) {
      port = (await devices[0].create())!;
      bool openResult = await port.open();
      if (!openResult) {
        print("Failed to open");
        return;
      }
      await port.setDTR(true);
      await port.setRTS(true);
      port.setPortParameters(
          115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
      listenForData();
    }
  }

  void listenForData() {
    port.inputStream?.listen((Uint8List event) {
      setState(() {
        outputController.text += String.fromCharCodes(event);
      });
    });
  }

  void sendMessage(String message) async {
    Uint8List data = Uint8List.fromList(message.codeUnits);
    await port.write(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('USB Serial Communication')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'Enter message'),
            ),
          ),
          FloatingActionButton(
            onPressed: () => sendMessage(messageController.text),
            child: const Text('Send Message'),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: outputController,
              readOnly: true,
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Received Data'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    port.close();
    super.dispose();
  }
}
