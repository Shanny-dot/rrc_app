import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../theme/app_theme.dart';
import 'dashboard_screens.dart'; // To access ReferFormScreen
import '../widgets/loading.dart';

class ImportContactsScreen extends StatefulWidget {
  const ImportContactsScreen({Key? key}) : super(key: key);

  @override
  State<ImportContactsScreen> createState() => _ImportContactsScreenState();
}

class _ImportContactsScreenState extends State<ImportContactsScreen> {
  List<Contact>? _contacts;
  bool _permissionDenied = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
        setState(() => _permissionDenied = true);
        return;
      }

      final contacts = await FlutterContacts.getAll(properties: {
        ContactProperty.name,
        ContactProperty.phone,
        ContactProperty.email,
      });
      setState(() => _contacts = contacts);
    } catch (e) {
      debugPrint("Failed to fetch contacts: $e");
      setState(() => _contacts = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Import Contacts')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.contacts_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Permission denied.\nPlease allow access to your contacts in settings.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => FlutterContacts.permissions.request(PermissionType.read).then((_) => _fetchContacts()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    if (_contacts == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Import Contacts')),
        body: const FriendlyLoader(message: 'Reading your contacts…'),
      );
    }

    // Filter contacts based on search query
    final filteredContacts = _contacts!.where((c) {
      final nameMatches = (c.displayName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      final phoneMatches = c.phones.isNotEmpty && c.phones.any((phone) => phone.number.contains(_searchQuery));
      return nameMatches || phoneMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contact'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.pageMargin),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: AppColors.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: filteredContacts.isEmpty
                ? Center(
                    child: Text(
                      'No contacts found',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      final name = contact.displayName ?? '';
                      final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
                      final email = contact.emails.isNotEmpty ? contact.emails.first.address : '';

                      if (phone.isEmpty && email.isEmpty) {
                        return const SizedBox.shrink(); // Skip contacts without contact info
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryGold.withOpacity(0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(name, style: AppTextStyles.labelMedium),
                        subtitle: Text(phone.isNotEmpty ? phone : email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: OutlinedButton(
                          onPressed: () {
                            // Navigate to ReferFormScreen with pre-filled data
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReferFormScreen(
                                  initialName: name,
                                  initialPhone: phone,
                                  initialEmail: email,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryGold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Invite', style: TextStyle(color: AppColors.primaryGold, fontSize: 12)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
