namespace WebApplication1.Models
{
    public class AddLogRequest
    {
        public string EmployeeNumber { get; set; }
        public string IdNumber { get; set; }
        public string Citizenship { get; set; }
        public int Age { get; set; }

        public string Department { get; set; }          // which department the employee belongs to
        public string ProfileImageBase64 { get; set; }  // base64 representation of profile image
    }
}
