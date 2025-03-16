import 'package:mockito/mockito.dart';
import 'package:jar/jar.dart';

class MockStringSchema extends Mock implements JarSchema<String, MockStringSchema> {
  @override
  JarResult validate(String? value, [Map<String, dynamic>? values]) {
    return JarResult.success();
  }
}

class MockFailingStringSchema extends Mock implements JarSchema<String, MockFailingStringSchema> {
  final String errorMessage;
  
  MockFailingStringSchema(this.errorMessage);
  
  @override
  JarResult validate(String? value, [Map<String, dynamic>? values]) {
    return JarResult.error(errorMessage);
  }
}
