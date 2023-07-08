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
  String _newLnAddress = '';

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
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: NetworkImage(
                        nostrService.profile.value.pictureUrl,
                      ),
                    ),
                    Text(
                      nostrService.profile.value.name,
                    ),
                    Text(
                      nostrService.profile.value.lud16,
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        nostrService.logout();
                      },
                      icon: const Icon(
                        Icons.logout,
                      ),
                      label: const Text(
                        'logout',
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Update your Lightning Address'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  _newLnAddress = value;
                                });
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'bob@xxx.io',
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          FilledButton(
                            onPressed: () {
                              nostrService.updateLud16(_newLnAddress);
                              _newLnAddress = '';
                            },
                            child: const Text('update'),
                          ),
                        ],
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
                    icon: const Icon(
                      Icons.login,
                    ),
                    label: const Text(
                      'login',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
