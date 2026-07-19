import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CacheService {
  static final CacheService instance = CacheService._internal();
  CacheService._internal();

  File? _ordersFile;
  File? _transactionsFile;

  Future<File> _getOrdersFile() async {
    if (_ordersFile != null) return _ordersFile!;
    final dir = await getApplicationDocumentsDirectory();
    _ordersFile = File('${dir.path}/orders_cache.json');
    return _ordersFile!;
  }

  Future<File> _getTransactionsFile() async {
    if (_transactionsFile != null) return _transactionsFile!;
    final dir = await getApplicationDocumentsDirectory();
    _transactionsFile = File('${dir.path}/transactions_cache.json');
    return _transactionsFile!;
  }

  // Clear cache on logout
  Future<void> clearCache() async {
    try {
      final f1 = await _getOrdersFile();
      if (await f1.exists()) await f1.delete();
      final f2 = await _getTransactionsFile();
      if (await f2.exists()) await f2.delete();
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getCachedOrders() async {
    try {
      final file = await _getOrdersFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> cacheOrders(List<dynamic> orders) async {
    try {
      final file = await _getOrdersFile();
      await file.writeAsString(jsonEncode(orders));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getCachedTransactions() async {
    try {
      final file = await _getTransactionsFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> cacheTransactions(List<dynamic> transactions) async {
    try {
      final file = await _getTransactionsFile();
      await file.writeAsString(jsonEncode(transactions));
    } catch (_) {}
  }

  // Calculate Dashboard Statistics locally
  Future<Map<String, dynamic>> calculateStats() async {
    final orders = await getCachedOrders();
    final transactions = await getCachedTransactions();

    int totalSales = 0;
    int pendingOrders = 0;
    int confirmedOrders = 0;
    int shippedOrders = 0;
    int deliveredOrders = 0;
    int retourFactureOrders = 0;
    int retourExonereOrders = 0;
    int cancelledOrders = 0;
    int failedOrders = 0;

    for (final order in orders) {
      final status = order['status'] as String? ?? 'pending';
      if (status != 'cancelled') {
        totalSales++;
      }
      switch (status) {
        case 'pending':
          pendingOrders++;
          break;
        case 'confirmed':
          confirmedOrders++;
          break;
        case 'shipped':
          shippedOrders++;
          break;
        case 'delivered':
          deliveredOrders++;
          break;
        case 'failed':
          failedOrders++;
          break;
        case 'retour_facture':
          retourFactureOrders++;
          break;
        case 'retour_exonere':
          retourExonereOrders++;
          break;
        case 'cancelled':
          cancelledOrders++;
          break;
      }
    }

    double deliveryRate = 0;
    final totalFinished = deliveredOrders + retourFactureOrders + retourExonereOrders + failedOrders;
    if (totalFinished > 0) {
      deliveryRate = (deliveredOrders / totalFinished) * 100;
    }

    // Calculations for wallet
    final walletBalances = _calculateWalletBalances(transactions);

    return {
      'total_sales': totalSales,
      'pending_orders': pendingOrders,
      'confirmed_orders': confirmedOrders,
      'shipped_orders': shippedOrders,
      'delivered_orders': deliveredOrders,
      'retour_facture_orders': retourFactureOrders,
      'retour_exonere_orders': retourExonereOrders,
      'cancelled_orders': cancelledOrders,
      'delivery_rate': deliveryRate.round(),
      'wallet': walletBalances,
    };
  }

  Map<String, dynamic> _calculateWalletBalances(List<Map<String, dynamic>> transactions) {
    double approvedCommissions = 0;
    double returnFees = 0;
    double approvedWithdrawals = 0;
    double pendingWithdrawals = 0;

    for (final tx in transactions) {
      final type = tx['type'] as String? ?? 'commission';
      final status = tx['status'] as String? ?? 'pending';
      final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;

      if (type == 'commission' && status == 'approved') {
        approvedCommissions += amount;
      } else if (type == 'return_fee' && status == 'approved') {
        returnFees += amount;
      } else if (type == 'withdrawal') {
        if (status == 'approved') {
          approvedWithdrawals += amount;
        } else if (status == 'pending') {
          pendingWithdrawals += amount;
        }
      }
    }

    final earned = approvedCommissions - returnFees;
    final available = earned - approvedWithdrawals - pendingWithdrawals;

    return {
      'earned': earned,
      'pending_withdrawals': pendingWithdrawals,
      'available': available,
    };
  }

  // Sync Order Statuses and update transactions accordingly
  Future<void> syncOrderStatuses(List<dynamic> serverStatuses) async {
    final cachedOrders = await getCachedOrders();
    final cachedTransactions = await getCachedTransactions();

    bool ordersChanged = false;
    bool txChanged = false;

    // Build lookup maps
    final txMap = {
      for (var tx in cachedTransactions)
        '${tx['order_id']}_${tx['type']}': tx
    };

    final orderMap = {
      for (var o in cachedOrders)
        o['id'].toString(): o
    };

    for (final s in serverStatuses) {
      final idStr = s['id'].toString();
      final status = s['status'] as String;
      final commission = double.tryParse(s['marketer_commission']?.toString() ?? '0') ?? 0.0;
      final returnFee = double.tryParse(s['return_fee']?.toString() ?? '400') ?? 400.0;

      if (orderMap.containsKey(idStr)) {
        final order = orderMap[idStr]!;
        final oldStatus = order['status'] as String?;
        if (oldStatus != status) {
          order['status'] = status;
          ordersChanged = true;

          // If status became delivered, ensure we have a commission transaction
          if (status == 'delivered') {
            final key = '${idStr}_commission';
            if (!txMap.containsKey(key)) {
              cachedTransactions.add({
                'id': DateTime.now().millisecondsSinceEpoch, // temporary local id
                'order_id': s['id'],
                'type': 'commission',
                'amount': commission,
                'status': 'approved',
                'created_at': DateTime.now().toIso8601String(),
              });
              txChanged = true;
            }
          }
          // If status became retour_facture, ensure we have a return fee transaction
          else if (status == 'retour_facture') {
            final key = '${idStr}_return_fee';
            if (!txMap.containsKey(key)) {
              cachedTransactions.add({
                'id': DateTime.now().millisecondsSinceEpoch, // temporary local id
                'order_id': s['id'],
                'type': 'return_fee',
                'amount': returnFee,
                'status': 'approved',
                'created_at': DateTime.now().toIso8601String(),
              });
              txChanged = true;
            }
          }
          // If status changed from delivered/retour_facture to cancelled/failed, update transaction status
          else if (status == 'cancelled' || status == 'failed') {
            final commKey = '${idStr}_commission';
            if (txMap.containsKey(commKey)) {
              txMap[commKey]!['status'] = 'cancelled';
              txChanged = true;
            }
            final retKey = '${idStr}_return_fee';
            if (txMap.containsKey(retKey)) {
              txMap[retKey]!['status'] = 'cancelled';
              txChanged = true;
            }
          }
        }
      }
    }

    if (ordersChanged) {
      await cacheOrders(cachedOrders);
    }
    if (txChanged) {
      await cacheTransactions(cachedTransactions);
    }
  }

  // Sync Withdrawal statuses
  Future<void> syncWithdrawalStatuses(List<dynamic> updatedWithdrawals) async {
    final cachedTransactions = await getCachedTransactions();
    bool txChanged = false;

    final updatedMap = {
      for (var w in updatedWithdrawals)
        w['id'].toString(): w['status'] as String
    };

    for (final tx in cachedTransactions) {
      final txIdStr = tx['id'].toString();
      if (tx['type'] == 'withdrawal' && tx['status'] == 'pending' && updatedMap.containsKey(txIdStr)) {
        tx['status'] = updatedMap[txIdStr];
        txChanged = true;
      }
    }

    if (txChanged) {
      await cacheTransactions(cachedTransactions);
    }
  }
}
