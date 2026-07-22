using LEAVE_SYSTEM.Models;

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Configuration;

using Newtonsoft.Json;

using Newtonsoft.Json.Linq;

using System.IdentityModel.Tokens.Jwt;

using System.Net.Http.Headers;

using System.Text;



namespace LEAVE_SYSTEM.Controllers

{

    public class HomeController : Controller

    {

        private readonly ILogger<HomeController> _logger;

        private readonly HttpClient _http;

        private readonly string _apiBaseUrl;



        public HomeController(ILogger<HomeController> logger, IHttpClientFactory factory, IConfiguration config)

        {

            _logger = logger;

            _http = factory.CreateClient();



            _apiBaseUrl = config["ApiBaseUrl"] ?? "http://localhost:5000/api/home/";

            _http.BaseAddress = new Uri(_apiBaseUrl);



            _http.Timeout = TimeSpan.FromSeconds(120);

        }



        private static string? GetUidFromToken(string token)

        {

            var handler = new JwtSecurityTokenHandler();

            var jwt = handler.ReadJwtToken(token);

            return jwt.Claims.FirstOrDefault(c => c.Type == "user_id")?.Value;

        }



        public IActionResult Login() => View();

        public IActionResult Create() => View();

        public IActionResult AddLog() {
           
            ViewBag.User = true;

            return View(); }
        public async Task<IActionResult>  About() {
 
            var token = HttpContext.Session.GetString("AccessToken");
            if (string.IsNullOrEmpty(token))
                return View("Abouts");

            try
            {
                // 1. Get user profile first — contains role info
                var profileRequest = new HttpRequestMessage(HttpMethod.Get, "profile");
                profileRequest.Headers.Add("token", token);
                var profileResponse = await _http.SendAsync(profileRequest);

                bool isAdmin = false;
                bool isAuditor = false;
                string fullName = "Employee";

                if (profileResponse.IsSuccessStatusCode)
                {
                    var profileBody = await profileResponse.Content.ReadAsStringAsync();
                    dynamic profileResult = JsonConvert.DeserializeObject(profileBody)!;


                    // Ensure boolean cast
                    isAdmin = profileResult.isAdmin == true;
                    isAuditor = profileResult.isAuditor == true;

                }

              

              
                   
                

                ViewBag.CurrentName = fullName;
                ViewBag.IsAdmin = isAdmin;
                ViewBag.IsAuditor = isAuditor;
                if (isAdmin == false && isAuditor == false)
                {
                    ViewBag.User = true;
                }


              
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to load logs");
                TempData["ErrorMessage"] = "Unexpected error loading logs.";
                return View(new List<Log>());
            }
            return View();
        }

        
        



        [HttpPost]

        public async Task<IActionResult> Login(LoginViewModel model)

        {

            if (!ModelState.IsValid) return View(model);



            try

            {

                var content = new StringContent(JsonConvert.SerializeObject(model), Encoding.UTF8, "application/json");

                var response = await _http.PostAsync("login", content);



                if (!response.IsSuccessStatusCode)

                {

                    ModelState.AddModelError(string.Empty, "Invalid credentials or API unavailable.");

                    return View(model);

                }



                var body = await response.Content.ReadAsStringAsync();

                dynamic result = JsonConvert.DeserializeObject(body)!;



                HttpContext.Session.SetString("AccessToken", (string)result.token);

                HttpContext.Session.SetString("Uid", (string)result.uid);



                return RedirectToAction("Index");

            }

            catch (HttpRequestException ex)

            {

                _logger.LogError(ex, "Failed to connect to API.");

                ModelState.AddModelError(string.Empty, "Unable to connect to API. Make sure it is running.");

                return View(model);

            }

            catch (TaskCanceledException)

            {

                ModelState.AddModelError(string.Empty, "Request to API timed out.");

                return View(model);

            }

        }



        [HttpPost]

        public async Task<IActionResult> RegisterUser(Employee vm)

        {

            if (!ModelState.IsValid)

                return View("Create", vm);



            try

            {

                var content = new StringContent(JsonConvert.SerializeObject(vm), Encoding.UTF8, "application/json");

                var response = await _http.PostAsync("register", content);



                var bodyDebug = await response.Content.ReadAsStringAsync();



                if (!response.IsSuccessStatusCode)

                {

                    ModelState.AddModelError(string.Empty, bodyDebug);

                    return View("Create", vm);

                }



                dynamic result = JsonConvert.DeserializeObject(bodyDebug)!;



                HttpContext.Session.SetString("AccessToken", (string)result.token);

                HttpContext.Session.SetString("Uid", (string)result.uid);



                return RedirectToAction("Index");

            }

            catch (HttpRequestException ex)

            {

                ModelState.AddModelError(string.Empty, "Unable to connect to API. " + ex.Message);

                return View("Create", vm);

            }

            catch (TaskCanceledException)

            {

                ModelState.AddModelError(string.Empty, "Request to API timed out.");

                return View("Create", vm);

            }

            catch (Exception ex)

            {

                ModelState.AddModelError(string.Empty, "Unexpected error: " + ex.Message);

                return View("Create", vm);

            }

        }





        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var token = HttpContext.Session.GetString("AccessToken");
            if (string.IsNullOrEmpty(token))
                return View("PublicHome");

            try
            {
                // 1. Get user profile first — contains role info
                var profileRequest = new HttpRequestMessage(HttpMethod.Get, "profile");
                profileRequest.Headers.Add("token", token);
                var profileResponse = await _http.SendAsync(profileRequest);

                bool isAdmin = false;
                bool isAuditor = false;
                string fullName = "Employee";

                if (profileResponse.IsSuccessStatusCode)
                {
                    var profileBody = await profileResponse.Content.ReadAsStringAsync();
                    dynamic profileResult = JsonConvert.DeserializeObject(profileBody)!;

                    string firstName = profileResult.FirstName ?? "";
                    string surname = profileResult.Surname ?? "";
                    fullName = $"{firstName} {surname}".Trim();

                    // Ensure boolean cast
                    isAdmin = profileResult.isAdmin == true;
                    isAuditor = profileResult.isAuditor == true;
                    
                }

                // 2. Fetch logs separately
                var request = new HttpRequestMessage(HttpMethod.Get, "logs");
                request.Headers.Add("token", token);
                var response = await _http.SendAsync(request);

                if (!response.IsSuccessStatusCode)
                {
                    TempData["ErrorMessage"] = "Unable to fetch logs from API.";
                    return View(new List<Log>());
                }

                var body = await response.Content.ReadAsStringAsync();
                dynamic result = JsonConvert.DeserializeObject(body)!;

                var logs = new List<Log>();
                if (result.logs != null)
                {
                    foreach (var item in result.logs)
                    {
                        DateTime? completedAt = null;



                        // handle ISO8601 string

                        if (item.completedAt != null)

                        {

                            string completedAtStr = item.completedAt.ToString();

                            if (DateTime.TryParse(completedAtStr, null, System.Globalization.DateTimeStyles.AdjustToUniversal, out var parsed))

                                completedAt = parsed.ToLocalTime();

                        }

                        logs.Add(new Log
                        {
                            logId = item.logId ?? "",
                            Id = item.uid ?? "",
                            Name = item.name ?? "",
                            Surname = item.surname ?? "",
                            Status = item.status ?? "",
                            EmployeeNumber = item.employeeNumber ?? "",
                            IdNumber = item.idNumber ?? "",
                            VerificationImageUrl = item.verificationImageUrl ?? "",
                            CompletedAt = completedAt
                        });
                    }
                }

                ViewBag.CurrentName = fullName;
                ViewBag.IsAdmin = isAdmin;
                ViewBag.IsAuditor = isAuditor;
                if(isAdmin == false && isAuditor == false)
                {
                    ViewBag.User = true;
                }
              

                if (isAdmin)
                    return View("AdminDash", logs);
                else if (isAuditor)
                    return RedirectToAction("AuditorDash");
                else
                    return View("Index", logs);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to load logs");
                TempData["ErrorMessage"] = "Unexpected error loading logs.";
                return View(new List<Log>());
            }
        }














        [HttpPost]

        public async Task<IActionResult> AddLog(AddLogRequest payload)
            ////\\\\\\\\\
        {

            var token = HttpContext.Session.GetString("AccessToken");

            if (string.IsNullOrEmpty(token)) return RedirectToAction("Login");



            try

            {
                ViewBag.IsAdmin = HttpContext.Session.GetString("IsAdmin") == "true";
                ViewBag.IsAuditor = HttpContext.Session.GetString("IsAuditor") == "true";
                ViewBag.User = HttpContext.Session.GetString("User") == "true";


                var content = new StringContent(JsonConvert.SerializeObject(payload), Encoding.UTF8, "application/json");

                var request = new HttpRequestMessage(HttpMethod.Post, "addlog");

                request.Headers.Add("token", token);

                request.Content = content;



                var response = await _http.SendAsync(request);



                if (!response.IsSuccessStatusCode)

                {

                    ModelState.AddModelError(string.Empty, "Failed to add log.");

                    return View(payload);

                }



                return RedirectToAction("Index");

            }

            catch (HttpRequestException ex)

            {

                _logger.LogError(ex, "Failed to connect to API.");

                ModelState.AddModelError(string.Empty, "Unable to connect to API.");

                return View(payload);

            }

            catch (TaskCanceledException)

            {

                ModelState.AddModelError(string.Empty, "Request to API timed out.");

                return View(payload);

            }

        }



        public IActionResult SignOutUser()

        {

            HttpContext.Session.Clear();

            return View("PublicHome");

        }

        [HttpGet]

        public async Task<IActionResult> Profile()

        {

            var token = HttpContext.Session.GetString("AccessToken");

            if (string.IsNullOrEmpty(token))

                return RedirectToAction("Login");



            try

            {

                var request = new HttpRequestMessage(HttpMethod.Get, "profile");

                request.Headers.Add("token", token);



                var response = await _http.SendAsync(request);



                if (!response.IsSuccessStatusCode)

                {

                    TempData["ErrorMessage"] = "Unable to fetch profile from API.";

                    return View(new Employee());

                }



                var body = await response.Content.ReadAsStringAsync();

                dynamic logData = JsonConvert.DeserializeObject(body)!;

                bool isAdmin = logData.isAdmin == true;
                bool isAuditor = logData.isAuditor == true;
                bool isUser = !isAdmin && !isAuditor;

                ViewBag.IsAdmin = isAdmin;
                ViewBag.IsAuditor = isAuditor;
                ViewBag.User = isUser;


                var profile = new Profile

                {

                    FirstName = logData.FirstName ?? "",

                    Surname = logData.Surname ?? "",

                    EmailAddress = logData.EmailAddress ?? "",

                    IdNumber = logData.Id ?? "",

                    EmployeeNumber = logData.PersonnelNumber ?? "",

                    Department = logData.Department ?? "",

                    Contract = logData.Contract ?? "",

                    Gender = logData.Gender ?? "",

                    ProfileImageUrl = logData.ProfileImageUrl ?? "",

                    PopiaConsent = logData.POPIAConsent ?? ""

                };






                return View(profile);

            }

            catch (Exception ex)

            {

                _logger.LogError(ex, "Failed to load profile");

                TempData["ErrorMessage"] = "Unexpected error loading profile.";

                return View(new Employee());

            }

        }





        [HttpGet]

        public async Task<IActionResult> LogDetails(string logId)

        {

            var token = HttpContext.Session.GetString("AccessToken");

            if (string.IsNullOrEmpty(token))

            {

                TempData["ErrorMessage"] = "Session expired. Please login again.";

                return RedirectToAction("Login");

            }



            try

            {

                var request = new HttpRequestMessage(HttpMethod.Get, $"log/{logId}");

                request.Headers.Add("token", token);



                var response = await _http.SendAsync(request);

                var body = await response.Content.ReadAsStringAsync();



                if (!response.IsSuccessStatusCode)

                {

                    TempData["ErrorMessage"] = "Unable to fetch log details.";

                    return RedirectToAction("Index");

                }



                var tokenResult = JToken.Parse(body);



                // Handle array or object consistently

                JToken logData;

                if (tokenResult.Type == JTokenType.Array)

                {

                    logData = tokenResult.First; // take first if array

                }

                else

                {

                    logData = tokenResult;

                }



                if (logData == null)

                {

                    TempData["ErrorMessage"] = "Log not found.";

                    return RedirectToAction("Index");

                }

                ViewBag.isAdmin = true;


                var profile = new LogDetails

                {

                    LogId = logData["logId"]?.ToString() ?? "",

                    Name = logData["name"]?.ToString() ?? "",

                    Surname = logData["surname"]?.ToString() ?? "",

                    IdNumber = logData["idNumber"]?.ToString() ?? "",

                    EmployeeNumber = logData["employeeNumber"]?.ToString() ?? "",

                    Department = logData["department"]?.ToString() ?? "",

                    Contract = logData["contract"]?.ToString() ?? "",

                    Gender = logData["gender"]?.ToString() ?? "",

                    VerificationImageUrl = logData["verificationImageUrl"]?.ToString() ?? "",
                    Reason = logData["reason"]?.ToString() ?? "N/A",

                };



                ViewBag.Status = logData["status"]?.ToString() ?? "";

                ViewBag.CompletedAt = logData["completedAt"]?.ToString() ?? "";



                return View("LogProfile", profile);

            }

            catch (Exception ex)

            {

                _logger.LogError(ex, "Unexpected error loading log {logId}", logId);

                TempData["ErrorMessage"] = $"Unexpected error: {ex.Message}";

                return RedirectToAction("Index");

            }

        }







        [HttpPost]

        public async Task<IActionResult> VerifyLog(string logId)

        {

            var token = HttpContext.Session.GetString("AccessToken");

            if (string.IsNullOrEmpty(token))

            {

                TempData["ErrorMessage"] = "Session expired. Please login again.";

                return RedirectToAction("Login");

            }



            try

            {

                var request = new HttpRequestMessage(HttpMethod.Post, $"verifylog/{logId}");

                request.Headers.Add("token", token);



                var response = await _http.SendAsync(request);

                var body = await response.Content.ReadAsStringAsync();



                if (!response.IsSuccessStatusCode)

                {

                    string errorMessage;

                    try

                    {

                        dynamic errorResponse = JsonConvert.DeserializeObject(body);

                        errorMessage = errorResponse?.message?.ToString() ?? "Verification failed";

                    }

                    catch

                    {

                        errorMessage = "Verification failed; invalid API response.";

                    }



                    TempData["ErrorMessage"] = errorMessage;

                    return RedirectToAction("LogDetails", new { logId });

                }



                dynamic result = JsonConvert.DeserializeObject(body);

                TempData["SuccessMessage"] = result?.message?.ToString() ?? "Log verified successfully.";



                return RedirectToAction("LogDetails", new { logId });

            }

            catch (HttpRequestException ex)

            {

                _logger.LogError(ex, "Failed to connect to API for VerifyLog {logId}", logId);

                TempData["ErrorMessage"] = "Unable to connect to API. Check server availability.";

                return RedirectToAction("LogDetails", new { logId });

            }

            catch (TaskCanceledException)

            {

                TempData["ErrorMessage"] = "API request timed out. Try again later.";

                return RedirectToAction("LogDetails", new { logId });

            }

            catch (Exception ex)

            {

                _logger.LogError(ex, "Unexpected error in VerifyLog {logId}", logId);

                TempData["ErrorMessage"] = $"Unexpected error: {ex.Message}";

                return RedirectToAction("LogDetails", new { logId });

            }

        }



        [HttpGet]
        public async Task<IActionResult> AuditorDash()
        {
            var token = HttpContext.Session.GetString("AccessToken");
            if (string.IsNullOrEmpty(token))
                return RedirectToAction("Login");

            var request = new HttpRequestMessage(HttpMethod.Get, "auditlogs");
            request.Headers.Add("token", token);
            var response = await _http.SendAsync(request);

            if (!response.IsSuccessStatusCode)
            {
                TempData["ErrorMessage"] = "Unable to fetch audit logs.";
                return View(new List<AuditLog>());
            }

            var body = await response.Content.ReadAsStringAsync();
            dynamic result = JsonConvert.DeserializeObject(body)!;

            bool isAuditor = result.isAuditor ?? false;
            if (!isAuditor)
                return RedirectToAction("Index");

            var logs = new List<AuditLog>();
            if (result.logs != null)
            {
                DateTime? completedAt = null;
                foreach (var item in result.logs)
                {
                    if (item.completedAt != null)
                    {
                        if (DateTime.TryParse(item.completedAt.ToString(), out DateTime parsed))
                            completedAt = parsed.ToLocalTime();
                    }

                    ViewBag.IsAuditor = isAuditor;

                    logs.Add(new AuditLog
                    {
                        LogId = item.logId ?? "",
                        IdNumber = item.idNumber ?? "",
                        Result = item.result ?? "",
                        Reason = item.reason ?? "",
                        Department = item.department ?? "",
                        VerifierFirstName = item.VerifierFirstName ?? "",
                        VerifierSurname = item.VerifierSurname ?? "",
                        VerifierPersonnelNumber = item.VerifierPersonnelNumber ?? ""
                    });

                }
            }

            return View("AuditorDash", logs);
        }

        [HttpGet]

        public async Task<IActionResult> UserLogDetails(string logId)

        {

            var token = HttpContext.Session.GetString("AccessToken");

            if (string.IsNullOrEmpty(token))

            {

                TempData["ErrorMessage"] = "Session expired. Please login again.";

                return RedirectToAction("Login");

            }



            try

            {

                var request = new HttpRequestMessage(HttpMethod.Get, $"log/{logId}");

                request.Headers.Add("token", token);



                var response = await _http.SendAsync(request);

                var body = await response.Content.ReadAsStringAsync();



                if (!response.IsSuccessStatusCode)

                {

                    TempData["ErrorMessage"] = "Unable to fetch log details.";

                    return RedirectToAction("Index");

                }



                var tokenResult = JToken.Parse(body);



                // Handle array or object consistently

                JToken logData;

                if (tokenResult.Type == JTokenType.Array)

                {

                    logData = tokenResult.First; // take first if array

                }

                else

                {

                    logData = tokenResult;

                }



                if (logData == null)

                {

                    TempData["ErrorMessage"] = "Log not found.";

                    return RedirectToAction("Index");

                }



                ViewBag.User = true;
                var profile = new LogDetails

                {

                    LogId = logData["logId"]?.ToString() ?? "",

                    Name = logData["name"]?.ToString() ?? "",

                    Surname = logData["surname"]?.ToString() ?? "",

                    IdNumber = logData["idNumber"]?.ToString() ?? "",

                    EmployeeNumber = logData["employeeNumber"]?.ToString() ?? "",

                    Department = logData["department"]?.ToString() ?? "",

                    Contract = logData["contract"]?.ToString() ?? "",

                    Gender = logData["gender"]?.ToString() ?? "",

                    VerificationImageUrl = logData["verificationImageUrl"]?.ToString() ?? "",
                    Reason = logData["reason"]?.ToString() ?? "N/A",

                };



                ViewBag.Status = logData["status"]?.ToString() ?? "";

                ViewBag.CompletedAt = logData["completedAt"]?.ToString() ?? "";
                ViewBag.isAdmin = logData["isAdmin"]?.ToObject<bool>() ?? false;


                return View("UserLogProfile", profile);

            }

            catch (Exception ex)

            {

                _logger.LogError(ex, "Unexpected error loading log {logId}", logId);

                TempData["ErrorMessage"] = $"Unexpected error: {ex.Message}";

                return RedirectToAction("Index");

            }

        }
        [HttpGet]
        public async Task<IActionResult> GetUsers()
        {
            var token = HttpContext.Session.GetString("AccessToken");
            if (string.IsNullOrEmpty(token))
                return RedirectToAction("Login");

            try
            {
                var request = new HttpRequestMessage(HttpMethod.Get, "getusers");
                request.Headers.Add("token", token);

                var response = await _http.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    TempData["ErrorMessage"] = "Unable to fetch users.";
                    return View("RegisteredUsers", new List<Employee>());
                }

                var body = await response.Content.ReadAsStringAsync();

                var settings = new JsonSerializerSettings
                {
                    MissingMemberHandling = MissingMemberHandling.Ignore,
                    NullValueHandling = NullValueHandling.Ignore,
                    ContractResolver = new Newtonsoft.Json.Serialization.DefaultContractResolver
                    {
                        NamingStrategy = new Newtonsoft.Json.Serialization.CamelCaseNamingStrategy()
                    }
                };

                var parsed = JsonConvert.DeserializeObject<Dictionary<string, List<Employees>>>(body, settings);
                var users = parsed != null && parsed.ContainsKey("users") ? parsed["users"] : new List<Employees>();

                // remove auditors
                users = users.Where(u => !u.IsAuditor).ToList();

                ViewBag.CurrentName = HttpContext.Session.GetString("Uid");
                ViewBag.IsAdmin = false;
                ViewBag.IsAuditor = true;

                return View("RegisteredUsers", users);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to fetch users.");
                TempData["ErrorMessage"] = "Unexpected error while loading users.";
                return View("RegisteredUsers", new List<Employee>());
            }
        }



        [HttpGet]
        public async Task<IActionResult> GetEmployees()
        {
            var token = HttpContext.Session.GetString("AccessToken");
            if (string.IsNullOrEmpty(token))
                return RedirectToAction("Login");

            try
            {
                var profileReq = new HttpRequestMessage(HttpMethod.Get, "profile");
                profileReq.Headers.Add("token", token);
                var profileRes = await _http.SendAsync(profileReq);

                bool isAdmin = false;
                bool isAuditor = false;
                if (profileRes.IsSuccessStatusCode)
                {
                    var profileBody = await profileRes.Content.ReadAsStringAsync();
                    dynamic profile = JsonConvert.DeserializeObject(profileBody)!;
                    isAdmin = profile.isAdmin == true;
                    isAuditor = profile.isAuditor == true;
                }

                var request = new HttpRequestMessage(HttpMethod.Get, "http://localhost:5000/api/Home/getemployees");
                request.Headers.Add("token", token);

                var response = await _http.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    TempData["ErrorMessage"] = "Unable to fetch employees.";
                    return View(new List<Employees>());
                }

                ViewBag.IsAdmin = isAdmin;
                ViewBag.IsAuditor = isAuditor;
                ViewBag.User = !isAdmin && !isAuditor;

                var body = await response.Content.ReadAsStringAsync();
                var parsed = JsonConvert.DeserializeObject<Dictionary<string, List<Employees>>>(body);
                var employees = parsed != null && parsed.ContainsKey("employees") ? parsed["employees"] : new List<Employees>();

                return View(employees);
            }
            catch (Exception ex)
            {
                TempData["ErrorMessage"] = "Unexpected error while loading employees.";
                return View(new List<Employees>());
            }
        }



        public override void OnActionExecuting(ActionExecutingContext context)
        {
            var s = HttpContext.Session;
            ViewBag.IsAdmin = s.GetString("IsAdmin") == "true";
            ViewBag.IsAuditor = s.GetString("IsAuditor") == "true";
            ViewBag.User = s.GetString("User") == "true";
            base.OnActionExecuting(context);
        }
        
        [HttpGet]
        public IActionResult ResetPassword()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> ResetPassword(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                ViewBag.Error = "Please enter your email address.";
                return View();
            }

            try
            {
                var payload = new { email };
                var content = new StringContent(JsonConvert.SerializeObject(payload), Encoding.UTF8, "application/json");
                var response = await _http.PostAsync("resetpassword", content);

                if (response.IsSuccessStatusCode)
                {
                    ViewBag.Message = "A password reset email has been sent to your address.";
                    return View();
                }

                var body = await response.Content.ReadAsStringAsync();
                ViewBag.Error = $"Reset failed: {body}";
                return View();
            }
            catch (Exception ex)
            {
                ViewBag.Error = $"Unexpected error: {ex.Message}";
                return View();
            }
        }



    }







}