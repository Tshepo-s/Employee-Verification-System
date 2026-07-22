namespace LEAVE_SYSTEM.services
{
    public class LogService
    {
        private readonly HttpClient _httpClient;
        public LogService(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }
        public async Task<bool> AddLogAsync(string uid, string employeeNumber, string idNumber)
        {
            var logRequest = new
            {
                Uid = uid,
                EmployeeNumber = employeeNumber,
                IdNumber = idNumber
            };
            var response = await _httpClient.PostAsJsonAsync("api/logs", logRequest);
            return response.IsSuccessStatusCode;
        }
        public async Task<List<Dictionary<string, object>>> GetLogsAsync(string uid)
        {
            var logs = await _httpClient.GetFromJsonAsync<List<Dictionary<string, object>>>($"api/logs/{uid}");
            return logs ?? new List<Dictionary<string, object>>();
        }
    }
}
