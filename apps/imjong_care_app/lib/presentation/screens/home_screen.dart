import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch, Widget child) {
    final userListProvider = watch(userListProvider);
    if (userListProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userListProvider.hasError) {
      return const Text('An error occurred while fetching user data.');
    }
    if (userListProvider.hasValue) {
      return ListView(
        children:
            userListProvider.value
                .map((user) => ListTile(title: Text(user.name)))
                .toList(),
      );
    }
    return const Text('No users found.');
  }
}
