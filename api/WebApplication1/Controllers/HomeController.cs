using Amazon.Rekognition;

using CloudinaryDotNet;

using CloudinaryDotNet.Actions;

using Firebase.Auth;

using Google.Cloud.Firestore;

using Microsoft.AspNetCore.Mvc;

using System.IdentityModel.Tokens.Jwt;

using System.Text;

using WebApplication1.Models;

using WebApplication1.services;



using System.Text.Json;



namespace LEAVE_SYSTEM.ApiControllers

{

    [Route("api/[controller]")]

    [ApiController]

    public class HomeController : ControllerBase

    {

        private readonly FirebaseAuthProvider _firebaseAuth;

        private readonly FirestoreDb _firestore;

        private readonly Cloudinary _cloudinary;

        private readonly FaceComparisonService _faceComparisonService;

        private readonly HttpClient _httpClient = new HttpClient();





        public HomeController(FirebaseAuthProvider firebaseAuth, FirestoreDb firestore, Cloudinary cloudinary, FaceComparisonService faceComparison)

        {

            _firebaseAuth = firebaseAuth;

            _firestore = firestore;

            _cloudinary = cloudinary;

            _faceComparisonService = faceComparison;

        }



        private string? GetUidFromToken(string token)

        {

            var handler = new JwtSecurityTokenHandler();

            var jwt = handler.ReadJwtToken(token);

            var uidClaim = jwt.Claims.FirstOrDefault(c => c.Type == "user_id");

            return uidClaim?.Value;

        }

        [HttpPost("login")]

        public async Task<IActionResult> Login([FromBody] LoginViewModel model)

        {

            if (!ModelState.IsValid)

                return BadRequest(ModelState);



            try

            {

                var user = await _firebaseAuth.SignInWithEmailAndPasswordAsync(model.EmailAddress, model.Password);

                if (string.IsNullOrEmpty(user.FirebaseToken))

                    return Unauthorized(new { message = "Login failed" });



                var uid = GetUidFromToken(user.FirebaseToken);

                var userDoc = _firestore.Collection("users").Document(uid);

                var userSnap = await userDoc.GetSnapshotAsync();



                var profile = userSnap.Exists ? userSnap.ToDictionary() : null;

                return Ok(new

                {

                    token = user.FirebaseToken,

                    uid,

                    profile

                });

            }

            catch (FirebaseAuthException ex)

            {

                return Unauthorized(new { message = ex.Message });

            }

        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] Employee vm)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            if (string.IsNullOrEmpty(vm.PopiaConsent))
                return BadRequest(new { message = "POPIA consent is required" });

            if (string.IsNullOrEmpty(vm.ProfileImageBase64))
                return BadRequest(new { message = "Captured profile image is required" });

            try
            {
                var deptCollection = _firestore.Collection(vm.Department);
                var deptSnapshot = await deptCollection
                    .WhereEqualTo("id", vm.IdNumber)
                    .WhereEqualTo("employeeNumber", vm.EmployeeNumber)
                    .GetSnapshotAsync();

                if (deptSnapshot.Count == 0)
                    return BadRequest(new { message = "Employee not found in selected department" });

                var usersCollection = _firestore.Collection("users");
                var existingUser = await usersCollection
                    .WhereEqualTo("Id", vm.IdNumber)
                    .WhereEqualTo("PersonnelNumber", vm.EmployeeNumber)
                    .GetSnapshotAsync();

                if (existingUser.Count > 0)
                    return BadRequest(new { message = "Employee already registered" });

                var employeeDoc = deptSnapshot.Documents.First();
                var employeeData = employeeDoc.ToDictionary();
                employeeData.TryGetValue("ProfileImageUrl", out object? profileImageUrlObj);
                var profileImageUrl = profileImageUrlObj?.ToString();

                if (string.IsNullOrEmpty(profileImageUrl))
                    return BadRequest(new { message = "Official profile image missing from department record" });

                var bytes = Convert.FromBase64String(vm.ProfileImageBase64);
                var uploadParams = new ImageUploadParams
                {
                    File = new FileDescription($"{vm.IdNumber}_register.jpg", new MemoryStream(bytes)),
                    Folder = "register_verification",
                    Overwrite = true
                };
                var uploadResult = _cloudinary.Upload(uploadParams);
                if (uploadResult.StatusCode != System.Net.HttpStatusCode.OK)
                    return BadRequest(new { message = "Captured image upload failed" });

                var capturedImageUrl = uploadResult.SecureUrl.AbsoluteUri;

                var (isMatch, similarity, rawResponse) =
                    await _faceComparisonService.CompareAsync(profileImageUrl, capturedImageUrl);

                if (!isMatch || similarity < 90)
                    return BadRequest(new
                    {
                        message = $"Face mismatch detected. Similarity score: {similarity:F2}%. Registration blocked."
                    });

                var authLink = await _firebaseAuth.CreateUserWithEmailAndPasswordAsync(vm.EmailAddress, vm.Password);
                var user = await _firebaseAuth.SignInWithEmailAndPasswordAsync(vm.EmailAddress, vm.Password);

                if (string.IsNullOrEmpty(user.FirebaseToken))
                    return BadRequest(new { message = "Could not generate token" });

                var uid = user.User.LocalId;

                var userData = new Dictionary<string, object>
        {
            { "FirstName", vm.FirstName },
            { "Surname", vm.Surname },
            { "EmailAddress", vm.EmailAddress },
            { "Id", vm.IdNumber },
            { "PersonnelNumber", vm.EmployeeNumber },
            { "Department", vm.Department },
            { "Contract", vm.Contract },
            { "Gender", vm.Gender },
            { "IsAdmin", false },
            { "POPIAConsent", vm.PopiaConsent },
            { "ProfileImageUrl", capturedImageUrl },
            { "CreatedAt", FieldValue.ServerTimestamp }
        };

                var docRef = _firestore.Collection("users").Document(uid);
                await docRef.SetAsync(userData);

                return Ok(new
                {
                    uid,
                    token = user.FirebaseToken,
                    similarity = similarity,
                    message = "Registration successful; face verified."
                });
            }
            catch (FirebaseAuthException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }














        [HttpPost("addlog")]

        public async Task<IActionResult> AddLog([FromHeader] string token, [FromBody] AddLogRequest payload)

        {

            var uid = GetUidFromToken(token);

            if (string.IsNullOrEmpty(uid))

                return Unauthorized();



            if (string.IsNullOrEmpty(payload.ProfileImageBase64))

                return BadRequest(new { message = "Profile image is required" });




            var bytes = Convert.FromBase64String(payload.ProfileImageBase64);

            var uploadParams = new ImageUploadParams

            {

                File = new FileDescription($"{uid}_verify.jpg", new MemoryStream(bytes)),

                PublicId = $"verification_pics/{uid}",

                Overwrite = true

            };

            var uploadResult = _cloudinary.Upload(uploadParams);

            if (uploadResult.StatusCode != System.Net.HttpStatusCode.OK)

                return BadRequest(new { message = "Image upload failed" });



            var profileImageUrl = uploadResult.SecureUrl.AbsoluteUri;



            var userDoc = _firestore.Collection("users").Document(uid);

            var snap = await userDoc.GetSnapshotAsync();

            var userData = snap.Exists ? snap.ToDictionary() : new Dictionary<string, object>();



            userData.TryGetValue("FirstName", out var firstName);

            userData.TryGetValue("Surname", out var surname);

            userData.TryGetValue("Gender", out var gender);

            userData.TryGetValue("Contract", out var contract);

            userData.TryGetValue("EmailAddress", out var emailObj);

            var email = emailObj?.ToString() ?? "";




            var logId = Guid.NewGuid().ToString("N"); // e.g., kK27yEfLYvhgkFWZ062q



            var logData = new Dictionary<string, object>

    {

        { "logId", logId },
        { "uid", uid },

        { "name", firstName?.ToString() ?? "" },

        { "surname", surname?.ToString() ?? "" },

        { "employeeNumber", payload.EmployeeNumber },

        { "idNumber", payload.IdNumber },

        { "gender" , gender?.ToString() ?? "" },

        { "citizenship", payload.Citizenship },

        { "age", payload.Age },

        { "contract",  contract?.ToString() ?? "" },

        { "department", payload.Department },

        { "verificationImageUrl", profileImageUrl },

        { "profileCompleted", true },

        { "completedAt", DateTime.UtcNow.ToString("o") },

        { "status", "pending" }

    };




            await _firestore.Collection("logs").Document(logId).SetAsync(logData);

            // send to the user who created the log
            try
            {
                await SendEmailAsync(
                    userName: $"{firstName?.ToString()} {surname?.ToString()}",
                    date: DateTime.UtcNow.ToString("yyyy-MM-dd"),
                    details: $"Log created for department {payload.Department}",
                    email: email
                );
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Email send failed (user): {ex.Message}");
            }

            try
            {
                var adminsQuery = await _firestore.Collection("users")
                    .WhereEqualTo("isAdmin", true)
                    .GetSnapshotAsync();

                foreach (var adminDoc in adminsQuery.Documents)
                {
                    var adminEmail = adminDoc.ContainsField("EmailAddress")
                        ? adminDoc.GetValue<string>("EmailAddress")
                        : null;

                    var adminName = adminDoc.ContainsField("FirstName")
                        ? adminDoc.GetValue<string>("FirstName")
                        : "Admin";

                    if (!string.IsNullOrEmpty(adminEmail))
                    {
                        await SendEmailAsync(
                            userName: adminName,
                            date: DateTime.UtcNow.ToString("yyyy-MM-dd"),
                            details: $"A new verification log has been created for department {payload.Department}.",
                            email: adminEmail
                        );
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Email send failed (admins): {ex.Message}");
            }




            return Ok(new { message = "Verification log added", logId });

        }













        [HttpGet("logs")]

        public async Task<IActionResult> GetLogs([FromHeader] string token)

        {

            var uid = GetUidFromToken(token);

            if (string.IsNullOrEmpty(uid))

                return Unauthorized();



            var userDoc = _firestore.Collection("users").Document(uid);

            var userSnap = await userDoc.GetSnapshotAsync();

            if (!userSnap.Exists)

                return NotFound(new { message = "User not found" });



            var userData = userSnap.ToDictionary();




            var isAdmin = false;

            if (userData.TryGetValue("IsAdmin", out var upperKey))

            {

                isAdmin = upperKey is bool b && b ||

                          upperKey?.ToString()?.ToLower() == "true";

            }

            else if (userData.TryGetValue("isAdmin", out var lowerKey))

            {

                isAdmin = lowerKey is bool b && b ||

                          lowerKey?.ToString()?.ToLower() == "true";

            }



            Query query = isAdmin

                ? _firestore.Collection("logs")

                : _firestore.Collection("logs").WhereEqualTo("uid", uid);



            var logsSnap = await query.GetSnapshotAsync();

            var logs = logsSnap.Documents.Select(d => d.ToDictionary()).ToList();





            return Ok(new { isAdmin, logs });

        }







        [HttpGet("profile")]

        public async Task<IActionResult> GetProfile([FromHeader] string token)

        {

            var uid = GetUidFromToken(token);

            if (string.IsNullOrEmpty(uid))

                return Unauthorized();



            var docRef = _firestore.Collection("users").Document(uid);

            var snapshot = await docRef.GetSnapshotAsync();



            if (!snapshot.Exists)

                return NotFound(new { message = "User not found" });



            return Ok(snapshot.ToDictionary());

        }



        [HttpPost("verifylog/{logId}")]

        public async Task<IActionResult> VerifyLog(string logId, [FromHeader(Name = "token")] string token)

        {

            var uid = GetUidFromToken(token);

            if (string.IsNullOrEmpty(uid))

                return Unauthorized(new { message = "Unauthorized" });



            try

            {

                var logRef = _firestore.Collection("logs").Document(logId);

                var logSnap = await logRef.GetSnapshotAsync();

                if (!logSnap.Exists)

                    return NotFound(new { message = "Log not found" });



                var log = logSnap.ToDictionary();

                var department = log.TryGetValue("department", out var dep) ? dep?.ToString()?.Trim() ?? "" : "";

                var idNumber = log.TryGetValue("idNumber", out var id) ? id?.ToString()?.Trim() ?? "" : "";

                var employeeNo = log.TryGetValue("employeeNumber", out var emp) ? emp?.ToString()?.Trim() ?? "" : "";

                var verificationImageUrl = log.TryGetValue("verificationImageUrl", out var vImg) ? vImg?.ToString() ?? "" : "";

                var logName = log.TryGetValue("name", out var logNameObj) ? logNameObj?.ToString()?.Trim() ?? "" : "";

                var logSurname = log.TryGetValue("surname", out var logSurnameObj) ? logSurnameObj?.ToString()?.Trim() ?? "" : "";



                if (string.IsNullOrEmpty(idNumber) && log.TryGetValue("id", out var altId))

                    idNumber = altId?.ToString()?.Trim() ?? "";



                if (string.IsNullOrEmpty(idNumber) || string.IsNullOrEmpty(verificationImageUrl) || string.IsNullOrEmpty(department))

                    return BadRequest(new { message = "Log missing required fields (idNumber/id, verificationImageUrl, department)." });



                idNumber = idNumber.Trim();




                var mockDocRef = _firestore.Collection("MockHomeAffairs").Document(idNumber);

                var mockSnap = await mockDocRef.GetSnapshotAsync();

                if (!mockSnap.Exists)

                {

                    var querySnap = await _firestore.Collection("MockHomeAffairs")

                        .WhereEqualTo("idNumber", idNumber)

                        .Limit(1)

                        .GetSnapshotAsync();

                    if (querySnap.Count == 0)

                        return RejectLog("No record found in HomeAffairs", logRef, logId, idNumber, department, uid);



                    mockSnap = querySnap.Documents[0];

                }


                var deptCollectionRef = _firestore.Collection(department);

                var deptQuerySnap = await deptCollectionRef

                    .WhereEqualTo("employeeNumber", employeeNo)
                    .Limit(1)

                    .GetSnapshotAsync();



                if (deptQuerySnap.Count == 0)

                    return RejectLog("No record found in department for the given employee number", logRef, logId, idNumber, department, uid);



                var deptDoc = deptQuerySnap.Documents[0];

                var deptData = deptDoc.ToDictionary();




                deptData.TryGetValue("name", out var deptNameObj);

                deptData.TryGetValue("surname", out var deptSurnameObj);

                var deptName = deptNameObj?.ToString()?.Trim() ?? "";

                var deptSurname = deptSurnameObj?.ToString()?.Trim() ?? "";

                var logGenderSafe = (log.TryGetValue("gender", out var lg) ? lg?.ToString() : "")?.Trim().ToLowerInvariant() ?? "";

                var deptGenderSafe = (deptData.TryGetValue("gender", out var dg) ? dg?.ToString() : "")?.Trim().ToLowerInvariant() ?? "";



                if (!string.Equals(logGenderSafe, deptGenderSafe, StringComparison.OrdinalIgnoreCase))

                    return RejectLog("Gender mismatch with department record", logRef, logId, idNumber, department, uid);





                if (!string.Equals(logName, deptName, StringComparison.OrdinalIgnoreCase) ||

                    !string.Equals(logSurname, deptSurname, StringComparison.OrdinalIgnoreCase))

                {

                    return RejectLog("Name mismatch with department record", logRef, logId, idNumber, department, uid);

                }









                var mockData = mockSnap.ToDictionary();

                mockData.TryGetValue("status", out var statusObj);

                mockData.TryGetValue("name", out var mockNameObj);

                mockData.TryGetValue("surname", out var mockSurnameObj);

                var status = statusObj?.ToString()?.Trim().ToLowerInvariant() ?? "";

                var mockName = mockNameObj?.ToString()?.Trim() ?? "";

                var mockSurname = mockSurnameObj?.ToString()?.Trim() ?? "";

                mockData.TryGetValue("gender", out var mockGenderObj);

                var mockGender = mockGenderObj?.ToString()?.Trim().ToLowerInvariant() ?? "";

                var logGender = log.TryGetValue("gender", out var logGenderObj) ? logGenderObj?.ToString()?.Trim().ToLowerInvariant() : "";



                if (!string.Equals(logGender, mockGender, StringComparison.OrdinalIgnoreCase))

                    return RejectLog("Gender mismatch with HomeAffairs", logRef, logId, idNumber, department, uid);





                if (status != "alive")

                    return RejectLog("Verification failed: individual is deceased", logRef, logId, idNumber, department, uid);

                if (!string.Equals(logName, mockName, StringComparison.OrdinalIgnoreCase) ||

                    !string.Equals(logSurname, mockSurname, StringComparison.OrdinalIgnoreCase))

                    return RejectLog("Verification failed: name mismatch with HomeAffairs", logRef, logId, idNumber, department, uid);




                var empDocRef = _firestore.Collection("EmploymentAndLabour").Document(idNumber);

                var empSnap = await empDocRef.GetSnapshotAsync();

                if (!empSnap.Exists)

                {

                    var querySnap = await _firestore.Collection("EmploymentAndLabour")

                        .WhereEqualTo("idNumber", idNumber)

                        .Limit(1)

                        .GetSnapshotAsync();

                    if (querySnap.Count == 0)

                        return RejectLog("No record found in EmploymentAndLabour", logRef, logId, idNumber, department, uid);



                    empSnap = querySnap.Documents[0];

                }



                var empData = empSnap.ToDictionary();

                empData.TryGetValue("employement", out var empStatusObj);

                empData.TryGetValue("name", out var empNameObj);

                empData.TryGetValue("surname", out var empSurnameObj);

                var empStatus = empStatusObj?.ToString()?.Trim().ToLowerInvariant() ?? "";

                var empName = empNameObj?.ToString()?.Trim() ?? "";

                var empSurname = empSurnameObj?.ToString()?.Trim() ?? "";



                if (empStatus != "employed")

                    return RejectLog("Verification failed: individual is unemployed", logRef, logId, idNumber, department, uid);

                if (!string.Equals(logName, empName, StringComparison.OrdinalIgnoreCase) ||

                    !string.Equals(logSurname, empSurname, StringComparison.OrdinalIgnoreCase))

                    return RejectLog("Verification failed: name mismatch with EmploymentAndLabour", logRef, logId, idNumber, department, uid);




                mockData.TryGetValue("imageurl", out var officialImageObj);

                var officialImageUrl = officialImageObj?.ToString();

                if (string.IsNullOrEmpty(officialImageUrl))

                    return BadRequest(new { message = $"Official image missing for ID '{idNumber}'" });



                var (isMatch, similarity, rawResponse) = await _faceComparisonService.CompareAsync(officialImageUrl, verificationImageUrl);



                var comparisonSummary = new Dictionary<string, object>

        {

            { "match", isMatch },

            { "similarity", similarity },

            { "timestamp",DateTime.UtcNow.ToString("o") }

        };



                var statusStr = isMatch ? "verified" : "rejected";
                var reason = isMatch
    ? "All information provided is valid"
    : "Information provided does not match";

                var updateData = new Dictionary<string, object>

        {

            { "verifiedBy", uid },

            { "verifiedAt", DateTime.UtcNow.ToString("o") },

            { "similarity", similarity },

            { "comparisonSummary", comparisonSummary },

            { "status", statusStr },
            { "reason", reason }


        };



                await logRef.UpdateAsync(updateData);



                var userSnap = await _firestore.Collection("users").Document(uid).GetSnapshotAsync();
                var userProfile = userSnap.Exists ? userSnap.ToDictionary() : new Dictionary<string, object>();

                userProfile.TryGetValue("FirstName", out var adminFirstName);
                userProfile.TryGetValue("Surname", out var adminSurname);
                userProfile.TryGetValue("PersonnelNumber", out var adminPersonnelNumber);
                userProfile.TryGetValue("EmailAddress", out var adminEmail);
                userProfile.TryGetValue("Contract", out var adminContract);
                userProfile.TryGetValue("Department", out var adminDepartment);
                userProfile.TryGetValue("Gender", out var adminGender);
                userProfile.TryGetValue("Id", out var adminId);
                userProfile.TryGetValue("POPIAConsent", out var adminPopia);
                userProfile.TryGetValue("ProfileImageUrl", out var adminProfileImageUrl);
                userProfile.TryGetValue("isAdmin", out var adminIsAdmin);

                await _firestore.Collection("audit_trail").AddAsync(new Dictionary<string, object>
        {
            { "logId", logId },
            { "idNumber", idNumber },
            { "department", department },
            { "verifiedBy", uid },
            { "timestamp", DateTime.UtcNow.ToString("o")  },
            { "result", statusStr },
            { "similarity", similarity },
            { "reason", isMatch ? "All information provided is valid" : "Face comparison mismatch" },

            { "VerifierFirstName", adminFirstName?.ToString() ?? "" },
            { "VerifierSurname", adminSurname?.ToString() ?? "" },
            { "VerifierPersonnelNumber", adminPersonnelNumber?.ToString() ?? "" },
            { "VerifierEmail", adminEmail?.ToString() ?? "" },
            { "VerifierDepartment", adminDepartment?.ToString() ?? "" },
            { "VerifierProfileImageUrl", adminProfileImageUrl?.ToString() ?? "" },
        });



                return Ok(new

                {

                    logId,

                    idNumber,

                    department,

                    isMatch,

                    similarity,

                    message = isMatch ? $"Verification successful (similarity {similarity:F2}%)" : $"Verification failed (similarity {similarity:F2}%)"

                });

            }

            catch (AmazonRekognitionException rekEx)

            {

                return StatusCode(502, new { message = "Face comparison failed", rekEx.Message });

            }

            catch (Exception ex)

            {

                return StatusCode(500, new { message = ex.Message });

            }




            IActionResult RejectLog(string reason, DocumentReference logRef, string logId, string idNumber, string department, string uid)

            {

                logRef.UpdateAsync(new Dictionary<string, object>

        {

            { "verifiedBy", uid },

            { "verifiedAt",DateTime.UtcNow.ToString("o")  },

            { "status", "rejected" },

            { "reason", reason }

        }).Wait();



                var rejectUserSnap = _firestore.Collection("users").Document(uid).GetSnapshotAsync().Result;
                var rejectProfile = rejectUserSnap.Exists ? rejectUserSnap.ToDictionary() : new Dictionary<string, object>();

                rejectProfile.TryGetValue("FirstName", out var rFirstName);
                rejectProfile.TryGetValue("Surname", out var rSurname);
                rejectProfile.TryGetValue("PersonnelNumber", out var rPersonnelNumber);
                rejectProfile.TryGetValue("EmailAddress", out var rEmail);
                rejectProfile.TryGetValue("Contract", out var rContract);
                rejectProfile.TryGetValue("Department", out var rDepartment);
                rejectProfile.TryGetValue("Gender", out var rGender);
                rejectProfile.TryGetValue("Id", out var rId);
                rejectProfile.TryGetValue("POPIAConsent", out var rPopia);
                rejectProfile.TryGetValue("ProfileImageUrl", out var rProfileImageUrl);
                rejectProfile.TryGetValue("isAdmin", out var rIsAdmin);

                _firestore.Collection("audit_trail").AddAsync(new Dictionary<string, object>
        {
            { "logId", logId },
            { "idNumber", idNumber },
            { "department", department },
            { "verifiedBy", uid },
            { "timestamp",DateTime.UtcNow.ToString("o") },
            { "result", "rejected" },
            { "reason", reason },

            { "VerifierFirstName", rFirstName?.ToString() ?? "" },
            { "VerifierSurname", rSurname?.ToString() ?? "" },
            { "VerifierPersonnelNumber", rPersonnelNumber?.ToString() ?? "" },
            { "VerifierEmail", rEmail?.ToString() ?? "" },
            { "VerifierDepartment", rDepartment?.ToString() ?? "" },
            { "VerifierProfileImageUrl", rProfileImageUrl?.ToString() ?? "" },
        }).Wait();


                return Ok(new { message = reason });

            }

        }

















        [HttpGet("log/{logId}")]

        public async Task<IActionResult> GetLogById(string logId)

        {

            var doc = await _firestore.Collection("logs").Document(logId).GetSnapshotAsync();

            if (!doc.Exists)

                return NotFound(new { message = "Log not found" });



            var data = doc.ToDictionary();

            data["logId"] = doc.Id;

            return Ok(data);

        }



        private async Task SendEmailAsync(string userName, string date, string details, string email)

        {

            const string serviceId = "service_t7z0qov";

            const string templateId = "template_igmhngh";

            const string userId = "DfqAMuTqk1Pw6sRs6";



            var payload = new

            {

                service_id = serviceId,

                template_id = templateId,

                user_id = userId,

                template_params = new

                {

                    userName,

                    date,

                    details,

                    email

                }

            };



            var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            content.Headers.Add("origin", "http://localhost"); // required by EmailJS



            var response = await _httpClient.PostAsync("https://api.emailjs.com/api/v1.0/email/send", content);



            if (!response.IsSuccessStatusCode)

            {

                var responseBody = await response.Content.ReadAsStringAsync();

                throw new Exception($"Failed to send email: {responseBody}");

            }

        }





        [HttpGet("auditlogs")]
        public async Task<IActionResult> GetAuditLogs([FromHeader] string token)
        {
            var uid = GetUidFromToken(token);
            if (string.IsNullOrEmpty(uid))
                return Unauthorized();

            var userDoc = _firestore.Collection("users").Document(uid);
            var snap = await userDoc.GetSnapshotAsync();

            if (!snap.Exists)
                return NotFound(new { message = "User not found" });

            var data = snap.ToDictionary();
            bool isAdmin = data.TryGetValue("IsAdmin", out var a) && (a is bool b && b);
            bool isAuditor = data.TryGetValue("IsAuditor", out var u) && (u is bool b2 && b2);

            if (!isAdmin && !isAuditor)
                return Forbid();

            var query = _firestore.Collection("audit_trail").OrderByDescending("timestamp");
            var docs = await query.GetSnapshotAsync();
            var logs = docs.Documents.Select(d => d.ToDictionary()).ToList();

            return Ok(new { isAdmin, isAuditor, logs });
        }

        [HttpGet("getusers")]
        public async Task<IActionResult> GetUsers()
        {
            try
            {
                var usersCollection = _firestore.Collection("users");
                var snapshot = await usersCollection.GetSnapshotAsync();

                var users = snapshot.Documents.Select(doc => new
                {
                    Uid = doc.Id,
                    FirstName = doc.ContainsField("FirstName") ? doc.GetValue<string>("FirstName") : "",
                    Surname = doc.ContainsField("Surname") ? doc.GetValue<string>("Surname") : "",
                    EmailAddress = doc.ContainsField("EmailAddress") ? doc.GetValue<string>("EmailAddress") : "",
                    Department = doc.ContainsField("Department") ? doc.GetValue<string>("Department") : "",
                    Contract = doc.ContainsField("Contract") ? doc.GetValue<string>("Contract") : "",
                    IsAdmin = doc.ContainsField("IsAdmin") && doc.GetValue<bool>("IsAdmin"),
                    IsAuditor = doc.ContainsField("IsAuditor") && doc.GetValue<bool>("IsAuditor"),
                    Gender = doc.ContainsField("Gender") ? doc.GetValue<string>("Gender") : "",
                    POPIAConsent = doc.ContainsField("POPIAConsent") ? doc.GetValue<string>("POPIAConsent") : "",
                    ProfileImageUrl = doc.ContainsField("ProfileImageUrl") ? doc.GetValue<string>("ProfileImageUrl") : "",
                    PersonnelNumber = doc.ContainsField("PersonnelNumber") ? doc.GetValue<string>("PersonnelNumber") : "",
                    CreatedAt = doc.ContainsField("CreatedAt") ? doc.GetValue<Timestamp>("CreatedAt").ToDateTime() : (DateTime?)null
                }).ToList();
                var count = users.Count;
                Console.WriteLine($"Fetched {count} users from Firestore.");
                return Ok(new { users });

            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Failed to fetch users", error = ex.Message });
            }
        }

        [HttpGet("getemployees")]
        public async Task<IActionResult> GetEmployees()
        {
            try
            {
                var departments = new[]
                {
            "Public Finance",
            "Economic Policy and International Cooperation",
            "Tax and Financial Sector Policy",
            "Asset and Liability Management",
            "Office of the Accountant-General",
            "Intergovernmental Relations"
        };

                var employees = new List<Employees>();

                foreach (var dept in departments)
                {
                    var collection = _firestore.Collection(dept);
                    var snapshot = await collection.GetSnapshotAsync();

                    employees.AddRange(snapshot.Documents.Select(doc => new Employees
                    {
                        IdNumber = doc.ContainsField("id") ? doc.GetValue<string>("id") : "",
                        employeeNumber = doc.ContainsField("employeeNumber") ? doc.GetValue<string>("employeeNumber") : "",
                        FirstName = doc.ContainsField("name") ? doc.GetValue<string>("name") : "",
                        Surname = doc.ContainsField("surname") ? doc.GetValue<string>("surname") : "",
                        Department = dept,
                        Gender = doc.ContainsField("gender") ? doc.GetValue<string>("gender") : "",
                        Contract = doc.ContainsField("contract") ? doc.GetValue<string>("contract") : "",
                        ProfileImageUrl = doc.ContainsField("ProfileImageUrl") ? doc.GetValue<string>("ProfileImageUrl") : "",
                        email = doc.ContainsField("EmailAddress")
                      ? doc.GetValue<string>("EmailAddress")
                      : (doc.ContainsField("email") ? doc.GetValue<string>("email") : "")
                    }));

                }

                return Ok(new { employees });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Failed to fetch employees", error = ex.Message });
            }
        }





        [HttpPost("resetpassword")]
        public async Task<IActionResult> ResetPassword([FromBody] JsonElement body)
        {
            if (!body.TryGetProperty("email", out var emailProp))
                return BadRequest(new { message = "Email is required" });

            var email = emailProp.GetString();
            if (string.IsNullOrWhiteSpace(email))
                return BadRequest(new { message = "Invalid email address" });

            try
            {
                await _firebaseAuth.SendPasswordResetEmailAsync(email);
                return Ok(new { message = $"Password reset email sent to {email}" });
            }
            catch (FirebaseAuthException ex)
            {
                return BadRequest(new { message = ex.Reason.ToString(), detail = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Unexpected error", error = ex.Message });
            }
        }

    }
}