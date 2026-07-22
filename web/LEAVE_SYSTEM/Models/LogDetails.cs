using System.ComponentModel.DataAnnotations;

namespace LEAVE_SYSTEM.Models
{
    public class LogDetails
    {

        public string Name { get; set; }
        public string Surname { get; set; }
        public string Status { get; set; }
        public DateTime? CompletedAt { get; set; }
        public string Uid { get; set; }
        public string Id { get; set; }
        public string IdNumber { get; set; }
        public string LogId { get; set; }

        public string EmployeeNumber { get; set; }
        public string VerificationImageUrl { get; set; }
        public string Department { get;  set; }
        public string Contract { get;  set; }
        public string Gender { get; internal set; }
        public string Reason { get; internal set; }

    }

}


