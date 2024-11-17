import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String broker = 'io.adafruit.com';
  final int port = 1883;
  final String username = '';
  final String aioKey = '';
  final Logger logger = Logger('MqttService');
  final List<String> topics = ['coordinate'];

  Future<void> connect() async {
    final client = MqttServerClient(broker, '');
    client.port = port;
    client.secure = false;
    client.logging(on: true);
    client.keepAlivePeriod = 30;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(
            'flutter_mqtt_client') // Unique identifier for the client
        .withWillTopic('willtopic') // Optional last-will topic
        .withWillMessage('Connection closed')
        .startClean() // Clean session
        .authenticateAs(username, aioKey) // Authentication
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMessage;

    try {
      print('Connecting to Adafruit IO...');
      await client.connect();
    } on NoConnectionException catch (e) {
      print('MQTT client exception - $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT client connected');
    } else {
      print('Connection failed - ${client.connectionStatus!.state}');
      client.disconnect();
      return;
    }

    subscribeToFeeds(client);
    listenFromFeeds(client);
  }

  void subscribeToFeeds(MqttClient client) {
    print('Subscribing to feed...');
    for (var topic in topics) {
      final String fullTopic = '$username/feeds/$topic';
      client.subscribe(fullTopic, MqttQos.atLeastOnce);
      print('Subscribed to feed: $topic');
    }
  }

  void listenFromFeeds(MqttClient client) {
    print('Listening for messages from subscribed feeds...');
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (var message in messages) {
        final topic = message.topic;
        final MqttPublishMessage payloadMessage = message.payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(payloadMessage.payload.message);

        print('Message received: Topic = $topic, Payload = $payload');
      }
    });
  }
}
