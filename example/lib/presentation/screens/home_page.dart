import 'package:flutter/material.dart';
import '/services/local_push_notification.dart';
 
class HomePage extends StatefulWidget {
  const HomePage({super.key});
 
  @override
  State<HomePage> createState() => _HomePageState();
}
 
class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    listenNotifications();
    super.initState();
  }
  //푸시 알림 스트림에 데이터를 리슨
  void listenNotifications() {
    LocalPushNotifications.notificationStream.stream.listen((String? payload) {
      if (payload != null) {
        print('Received payload: $payload');
        Navigator.pushNamed(context, '/message', arguments: payload);
      }
    });
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로컬 푸시 알림 테스트'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                LocalPushNotifications.showSimpleNotification(
                    title: "일반 푸시 알림 제목",
                    body: "일반 푸시 알림 바디",
                    payload: "일반 푸시 알림 데이터");
              },
              child: const Text('일반 푸시 알림'),
            ),
            ElevatedButton(
              onPressed: () {
                LocalPushNotifications.showPeriodicNotifications(
                    title: "주기적 푸시 알림 제목",
                    body: "주기적 푸시 알림 바디",
                    payload: "주기적 푸시 알림 데이터");
              },
              child: const Text('주기 푸시 알림'),
            ),
            ElevatedButton(
              onPressed: () {
                LocalPushNotifications.showScheduleNotification(
                    title: "스케쥴 푸시 알림 제목",
                    body: "스케쥴 푸시 알림 바디",
                    payload: "스케쥴 푸시 알림 데이터");
              },
              child: const Text("스케쥴 푸시 알림"),
            ),
            TextButton(
                onPressed: () {
                  LocalPushNotifications.cancel(1);
                },
                child: const Text('주기 푸시 알림 끄기')),
            TextButton(
                onPressed: () {
                  LocalPushNotifications.cancelAll();
                },
                child: const Text('전체 푸시 알림 끄기')),
          ],
        ),
      ),
    );
  }
}