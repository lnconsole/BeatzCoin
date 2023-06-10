import 'package:beatcoin/services/nostr.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _pk = '';

  @override
  Widget build(BuildContext context) {
    NostrService nostrService = Get.find();

    return SingleChildScrollView(
      child: Obx(
        () => nostrService.loggedIn.value
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            nostrService.profile.value.pictureUrl,
                          ),
                        ),
                        title: Text(
                          nostrService.profile.value.name,
                        ),
                        trailing: FilledButton.icon(
                          onPressed: () {},
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              Colors.blue[100],
                            ),
                          ),
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.blue,
                          ),
                          label: const Text(
                            'logout',
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _pk = value;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter your private key',
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      nostrService.setPrivateKey(_pk);
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Colors.blue[100],
                      ),
                    ),
                    icon: const Icon(
                      Icons.login,
                      color: Colors.blue,
                    ),
                    label: const Text(
                      'login',
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
