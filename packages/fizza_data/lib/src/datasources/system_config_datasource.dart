import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../models/system_config_model.dart';

abstract class ISystemConfigDataSource {
  Future<SystemConfigModel> getConfig();
  Future<void> updateConfig(SystemConfigModel config);
}

@LazySingleton(as: ISystemConfigDataSource)
class SystemConfigDataSource implements ISystemConfigDataSource {
  final FirebaseFirestore _firestore;

  SystemConfigDataSource(this._firestore);

  @override
  Future<SystemConfigModel> getConfig() async {
    final doc = await _firestore.collection('system_configs').doc('default').get();
    if (doc.exists) {
      return SystemConfigModel.fromJson(doc.data()!);
    } else {
      // Create default config if not exists
      final defaultConfig = SystemConfigModel.defaultConfig();
      await updateConfig(defaultConfig);
      return defaultConfig;
    }
  }

  @override
  Future<void> updateConfig(SystemConfigModel config) async {
    await _firestore.collection('system_configs').doc('default').set(config.toJson());
  }
}
