import '../core/api_client.dart';

class ContactService {
  final _api = ApiClient.instance;

  Future<void> send({required String name, required String email, required String subject, required String body}) {
    return _api.post('/contact_messages', data: {
      'name': name,
      'email': email,
      'subject': subject,
      'body': body,
    });
  }
}
