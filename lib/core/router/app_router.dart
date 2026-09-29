import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/merchant/presentation/business_profile_screen.dart';
import '../../features/merchant/presentation/issue_warranty_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../features/merchant/presentation/qr_scanner_screen.dart';
// Simple placeholder screens for now — we'll build the real dashboards later
class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Verify Warranty',
            onPressed: () => context.push('/qr-scanner'),
          ),
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Business Profile',
            onPressed: () => context.push('/business-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => context.push('/issue-warranty'),
              child: const Text('Issue New Warranty'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/qr-scanner'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Verify Warranty'),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerWalletScreen extends ConsumerStatefulWidget {
  const CustomerWalletScreen({super.key});
  @override
  ConsumerState<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}
class WarrantyCardDetailScreen extends StatelessWidget {
  final Map<String, dynamic> card;
  const WarrantyCardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final businessName = card['businesses']?['business_name'] ?? 'Unknown';
    return Scaffold(
      appBar: AppBar(title: Text(card['title'] ?? '')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(businessName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Status: ${card['status']}'),
            Text('Issued: ${card['issue_date']}'),
            Text('Expires: ${card['expiry_date']}'),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: QrImageView(
                data: card['qr_hash'] ?? '',
                size: 220,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Show this to the merchant to verify', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _CustomerWalletScreenState extends ConsumerState<CustomerWalletScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final cards = await Supabase.instance.client
        .from('warranty_cards')
        .select('id, title, category, status, issue_date, expiry_date, qr_hash, business_id, businesses(business_name)')
        .eq('customer_user_id', userId)
        .order('issue_date', ascending: false);

    if (mounted) {
      setState(() {
        _cards = List<Map<String, dynamic>>.from(cards);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? const Center(child: Text('No warranty cards yet'))
              : RefreshIndicator(
                  onRefresh: _loadCards,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      final card = _cards[index];
                      final businessName = card['businesses']?['business_name'] ?? 'Unknown';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(card['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$businessName · ${card['status']}\nExpires: ${card['expiry_date']}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.qr_code, size: 28),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WarrantyCardDetailScreen(card: card),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/role-selection',
    routes: [
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/merchant-dashboard',
        builder: (context, state) => const MerchantDashboardScreen(),
      ),
      GoRoute(
        path: '/customer-wallet',
        builder: (context, state) => const CustomerWalletScreen(),
      ),
      GoRoute(
        path: '/business-profile',
        builder: (context, state) => const BusinessProfileScreen(),
      ),
      GoRoute(
        path: '/issue-warranty',
        builder: (context, state) => const IssueWarrantyScreen(),
      ),
      GoRoute(path: '/qr-scanner', builder: (context, state) => const QrScannerScreen())
    ],
    redirect: (context, state) async {
  final session = Supabase.instance.client.auth.currentSession;
  final loggedIn = session != null;

  final loggingInPaths = ['/role-selection', '/login'];
  final isOnAuthScreen = loggingInPaths.contains(state.matchedLocation);

  if (!loggedIn) {
    return isOnAuthScreen ? null : '/role-selection';
  }

  if (isOnAuthScreen) {
    try {
      final userId = session.user.id;
      final userRow = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final role = userRow?['role'];

      if (role == 'merchant') return '/merchant-dashboard';
      if (role == 'customer') return '/customer-wallet';

      return '/role-selection';
    } catch (e) {
      // Network or Supabase unreachable — don't crash, just stay put
      return null;
    }
  }

  return null;
},
  );
});