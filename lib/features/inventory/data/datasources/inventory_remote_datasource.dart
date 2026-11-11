import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/variant_entity.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/stock_movement_model.dart';

abstract class InventoryRemoteDatasource {
  Future<List<ProductModel>> getProducts({
    required String businessId,
    String? categoryId,
    String? searchQuery,
  });

  Future<ProductModel> getProductById(String id);

  Future<ProductModel> createProduct({
    required String businessId,
    String? categoryId,
    required String name,
    String? description,
    String? sku,
    String? barcode,
    required int costPrice,
    required int sellingPrice,
    required String currency,
    String unit = 'pcs',
    int reorderLevel = 10,
    int initialStock = 0,
    String? initialBranchId,
    List<ProductVariantEntity> variants = const [],
    List<String> imageUrls = const [],
  });

  Future<ProductModel> updateProduct(ProductEntity product);
  Future<void> deleteProduct(String productId);

  Future<List<ProductCategoryModel>> getCategories(String businessId);
  Future<ProductCategoryModel> createCategory({
    required String businessId,
    required String name,
    String? description,
  });
  Future<void> deleteCategory(String categoryId);

  Future<void> adjustStock({
    required String businessId,
    required String productId,
    required String branchId,
    String? variantId,
    required int newQuantity,
    String type = 'adjustment',
    String? reason,
    String? batchNumber,
    DateTime? expiryDate,
  });

  Future<List<StockMovementModel>> getStockMovements({
    required String businessId,
    String? branchId,
    String? productId,
  });
}

class InventoryRemoteDatasourceImpl implements InventoryRemoteDatasource {
  final SupabaseClient _supabaseClient;

  InventoryRemoteDatasourceImpl(this._supabaseClient);

  @override
  Future<List<ProductModel>> getProducts({
    required String businessId,
    String? categoryId,
    String? searchQuery,
  }) async {
    try {
      var query = _supabaseClient
          .from('products')
          .select('''
        id,
        business_id,
        category_id,
        name,
        description,
        sku,
        barcode,
        cost_price,
        selling_price,
        currency,
        unit,
        reorder_level,
        is_active,
        image_urls,
        created_at,
        updated_at,
        product_categories (
          id,
          business_id,
          name,
          description,
          is_active,
          created_at
        ),
        product_variants (
          id,
          product_id,
          name,
          sku,
          barcode,
          cost_price,
          selling_price,
          attributes,
          is_active,
          created_at
        ),
        stock (
          id,
          product_id,
          variant_id,
          branch_id,
          quantity,
          batch_number,
          expiry_date,
          updated_at
        )
      ''')
          .eq('business_id', businessId)
          .eq('is_active', true);

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.ilike('name', '%${searchQuery.trim()}%');
      }

      final response = await query.order('name');
      final list = response as List;
      return list
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e('Get Products Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await _supabaseClient
          .from('products')
          .select('''
        id,
        business_id,
        category_id,
        name,
        description,
        sku,
        barcode,
        cost_price,
        selling_price,
        currency,
        unit,
        reorder_level,
        is_active,
        image_urls,
        created_at,
        updated_at,
        product_categories (
          id,
          business_id,
          name,
          description,
          is_active,
          created_at
        ),
        product_variants (
          id,
          product_id,
          name,
          sku,
          barcode,
          cost_price,
          selling_price,
          attributes,
          is_active,
          created_at
        ),
        stock (
          id,
          product_id,
          variant_id,
          branch_id,
          quantity,
          batch_number,
          expiry_date,
          updated_at
        )
      ''')
          .eq('id', id)
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      AppLogger.e('Get Product By Id Error: $e');
      final str = e.toString();
      if (str.contains('SocketException') ||
          str.contains('ClientException') ||
          str.contains('Failed host lookup') ||
          str.contains('errno = 7')) {
        throw AppException(
          'Unable to connect to server. Please check your internet connection.',
        );
      }
      throw AppException(str);
    }
  }

  @override
  Future<ProductModel> createProduct({
    required String businessId,
    String? categoryId,
    required String name,
    String? description,
    String? sku,
    String? barcode,
    required int costPrice,
    required int sellingPrice,
    required String currency,
    String unit = 'pcs',
    int reorderLevel = 10,
    int initialStock = 0,
    String? initialBranchId,
    List<ProductVariantEntity> variants = const [],
    List<String> imageUrls = const [],
  }) async {
    try {
      // 1. Insert product
      final productData = await _supabaseClient
          .from('products')
          .insert({
            'business_id': businessId,
            'category_id': categoryId,
            'name': name,
            'description': description,
            'sku': sku,
            'barcode': barcode,
            'cost_price': costPrice,
            'selling_price': sellingPrice,
            'currency': currency,
            'unit': unit,
            'reorder_level': reorderLevel,
            'image_urls': imageUrls,
          })
          .select()
          .single();

      final newProductId = productData['id'] as String;

      // 2. Insert variants if any
      if (variants.isNotEmpty) {
        final variantInserts = variants
            .map(
              (v) => {
                'product_id': newProductId,
                'name': v.name,
                'sku': v.sku,
                'barcode': v.barcode,
                'cost_price': v.costPrice,
                'selling_price': v.sellingPrice,
                'attributes': v.attributes,
              },
            )
            .toList();

        await _supabaseClient.from('product_variants').insert(variantInserts);
      }

      // 3. Insert initial stock if specified
      if (initialStock > 0 && initialBranchId != null) {
        await _supabaseClient.from('stock').insert({
          'product_id': newProductId,
          'branch_id': initialBranchId,
          'quantity': initialStock,
        });
      }

      return await getProductById(newProductId);
    } catch (e) {
      AppLogger.e('Create Product Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductEntity product) async {
    try {
      await _supabaseClient
          .from('products')
          .update({
            'category_id': product.categoryId,
            'name': product.name,
            'description': product.description,
            'sku': product.sku,
            'barcode': product.barcode,
            'cost_price': product.costPrice,
            'selling_price': product.sellingPrice,
            'unit': product.unit,
            'reorder_level': product.reorderLevel,
            'image_urls': product.imageUrls,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', product.id);

      return await getProductById(product.id);
    } catch (e) {
      AppLogger.e('Update Product Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabaseClient
          .from('products')
          .update({
            'is_active': false,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);
    } catch (e) {
      AppLogger.e('Delete Product Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<List<ProductCategoryModel>> getCategories(String businessId) async {
    try {
      final response = await _supabaseClient
          .from('product_categories')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true)
          .order('name');

      final list = response as List;
      return list
          .map(
            (item) =>
                ProductCategoryModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      AppLogger.e('Get Categories Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<ProductCategoryModel> createCategory({
    required String businessId,
    required String name,
    String? description,
  }) async {
    try {
      final response = await _supabaseClient
          .from('product_categories')
          .insert({
            'business_id': businessId,
            'name': name,
            'description': description,
          })
          .select()
          .single();

      return ProductCategoryModel.fromJson(response);
    } catch (e) {
      AppLogger.e('Create Category Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _supabaseClient
          .from('product_categories')
          .update({'is_active': false})
          .eq('id', categoryId);
    } catch (e) {
      AppLogger.e('Delete Category Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> adjustStock({
    required String businessId,
    required String productId,
    required String branchId,
    String? variantId,
    required int newQuantity,
    String type = 'adjustment',
    String? reason,
    String? batchNumber,
    DateTime? expiryDate,
  }) async {
    try {
      // 1. Get current stock to determine delta
      var existingQuery = _supabaseClient
          .from('stock')
          .select('quantity')
          .eq('branch_id', branchId)
          .eq('product_id', productId);
      if (variantId != null) {
        existingQuery = existingQuery.eq('variant_id', variantId);
      } else {
        existingQuery = existingQuery.isFilter('variant_id', null);
      }
      final existingRows = await existingQuery;
      final currentQty = existingRows.isNotEmpty
          ? (existingRows.first['quantity'] as num).toInt()
          : 0;
      final delta = newQuantity - currentQty;

      // 2. Upsert stock
      final stockPayload = <String, dynamic>{
        'product_id': productId,
        'branch_id': branchId,
        'variant_id': variantId,
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (batchNumber != null && batchNumber.isNotEmpty) {
        stockPayload['batch_number'] = batchNumber;
      }
      if (expiryDate != null) {
        stockPayload['expiry_date'] = expiryDate.toIso8601String();
      }

      await _supabaseClient.from('stock').upsert(stockPayload);

      // 3. Log stock movement audit
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      await _supabaseClient.from('stock_movements').insert({
        'business_id': businessId,
        'branch_id': branchId,
        'product_id': productId,
        'variant_id': variantId,
        'quantity': delta,
        'type': type,
        'reason': reason ?? 'Manual stock adjustment to $newQuantity',
        'batch_number': batchNumber,
        'expiry_date': expiryDate?.toIso8601String(),
        'user_id': currentUserId,
      });
    } catch (e) {
      AppLogger.e('Adjust Stock Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<List<StockMovementModel>> getStockMovements({
    required String businessId,
    String? branchId,
    String? productId,
  }) async {
    try {
      var query = _supabaseClient
          .from('stock_movements')
          .select('''
        id,
        business_id,
        branch_id,
        product_id,
        variant_id,
        quantity,
        type,
        reason,
        batch_number,
        expiry_date,
        user_id,
        created_at,
        products ( name ),
        product_variants ( name ),
        profiles ( full_name )
      ''')
          .eq('business_id', businessId);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }
      if (productId != null) {
        query = query.eq('product_id', productId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(100);
      return (response as List<dynamic>)
          .map(
            (json) => StockMovementModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (e is PostgrestException &&
          (e.code == 'PGRST205' || e.message.contains('stock_movements'))) {
        AppLogger.w(
          'stock_movements table not yet migrated in Supabase (PGRST205). Please run migration 20261009000003_sales_pos_schema.sql.',
        );
        return [];
      }
      AppLogger.e('Get Stock Movements Error: $e');
      throw AppException(e.toString());
    }
  }
}
