import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/client_provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  late TextEditingController _searchController;
  late final ScrollController _scrollController;
  Timer? _searchDebounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_searchQuery.isNotEmpty) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(clientListProvider.notifier).loadClients();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientListState = ref.watch(clientListProvider);
    final searchResults = ref.watch(searchClientsProvider(_searchQuery));

    final displayClients = _searchQuery.isEmpty
        ? clientListState.clients
        : searchResults.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authNotifier = ref.read(authStateProvider.notifier);
              await authNotifier.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(Routes.login);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search clients...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchDebounce?.cancel();
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                  if (!mounted) return;
                  setState(() {
                    _searchQuery = value.trim();
                  });
                });
              },
            ),
          ),
          Expanded(
            child: _searchQuery.isEmpty
                ? clientListState.isLoading && clientListState.clients.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : displayClients.isEmpty
                      ? const Center(
                          child: Text(
                            'No clients found. Add one to get started!',
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              displayClients.length +
                              (clientListState.hasMore ||
                                      clientListState.isLoading
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index >= displayClients.length) {
                              if (clientListState.isLoading) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text('Fin de la liste des clients'),
                                ),
                              );
                            }

                            final client = displayClients[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(client.firstName[0]),
                              ),
                              title: Text(client.fullName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(client.phone ?? 'No phone'),
                                  Text(
                                    'Debt: ${client.totalDebt} DT',
                                    style: TextStyle(
                                      color: client.totalDebt > 0
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.of(context).pushNamed(
                                  Routes.clientDetails,
                                  arguments: client.id,
                                );
                                if (!mounted) return;
                                if (_searchQuery.isEmpty) {
                                  await ref
                                      .read(clientListProvider.notifier)
                                      .loadClients(refresh: true);
                                } else {
                                  ref.invalidate(
                                    searchClientsProvider(_searchQuery),
                                  );
                                }
                              },
                            );
                          },
                        )
                : searchResults.when(
                    data: (clients) => clients.isEmpty
                        ? const Center(child: Text('No results found'))
                        : ListView.builder(
                            itemCount: clients.length,
                            itemBuilder: (context, index) {
                              final client = clients[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(client.firstName[0]),
                                ),
                                title: Text(client.fullName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(client.phone ?? 'No phone'),
                                    Text(
                                      'Debt: ${client.totalDebt} DT',
                                      style: TextStyle(
                                        color: client.totalDebt > 0
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.of(context).pushNamed(
                                    Routes.clientDetails,
                                    arguments: client.id,
                                  );
                                  if (!mounted) return;
                                  if (_searchQuery.isEmpty) {
                                    await ref
                                        .read(clientListProvider.notifier)
                                        .loadClients(refresh: true);
                                  } else {
                                    ref.invalidate(
                                      searchClientsProvider(_searchQuery),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).pushNamed(Routes.addClient);
          if (!mounted) return;
          await ref
              .read(clientListProvider.notifier)
              .loadClients(refresh: true);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
