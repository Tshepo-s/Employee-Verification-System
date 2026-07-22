namespace LEAVE_SYSTEM.Models
{
    public class AuditLog
    {
     
            public string LogId { get; set; } = "";
            public string IdNumber { get; set; } = "";
            public string VerifierFirstName { get; set; } = "";
            public string VerifierSurname { get; set; } = "";
            public string VerifierPersonnelNumber { get; set; } = "";
            public string Department { get; set; } = "";
            public string Result { get; set; } = "";
            public string Reason { get; set; } = "";
            public DateTime? Timestamp { get; set; }

    }
}
