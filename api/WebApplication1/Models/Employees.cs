namespace WebApplication1.Models
{
    public class Employees
    {
        public string Uid { get; set; }
        public string FirstName { get; set; }
        public string Surname { get; set; }
        public string email { get; set; }
        public string Department { get; set; }
        public string Contract { get; set; }
        public bool IsAdmin { get; set; }
        public bool IsAuditor { get; set; }
        public string Gender { get; set; }
        public string PopiaConsent { get; set; }
        public string ProfileImageUrl { get; set; }
        public string employeeNumber { get; set; }
        public DateTime? CreatedAt { get; set; }
        public string IdNumber { get;  set; }
    }
}
