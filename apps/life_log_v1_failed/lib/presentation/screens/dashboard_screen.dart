import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SFX Life-Log')),
      body: Center(
        child:
            syncState.isLoading
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (syncState.message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(syncState.message!),
                      ),
                    SizedBox(
                      width: 250,
                      height: 80,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed:
                            () =>
                                ref.read(syncProvider.notifier).syncSleepData(),
                        child: const Text(
                          '[AI 플래너 동기화]',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
