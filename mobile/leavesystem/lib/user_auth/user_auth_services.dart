import 'dart:io';
import 'package:http/http.dart' as http;

class UserAuthServices {
  final String baseUrl = "http://localhost:5000/api/home"; // change in prod

  Future<http.Response> register({
    required String firstName,
    required String surname,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    final uri = Uri.parse("$baseUrl/register");
    final request = http.MultipartRequest("POST", uri);

    request.fields['FirstName'] = firstName;
    request.fields['Surname'] = surname;
    request.fields['EmailAddress'] = email;
    request.fields['Password'] = password;

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'ProfileImage',
        profileImage.path,
      ));
    }

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }
}
