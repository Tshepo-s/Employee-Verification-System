namespace LEAVE_SYSTEM.Models
{
    public class AuditTrail
    {
        public string LogId { get; set; } = "";
        public string IdNumber { get; set; } = "";
        public string Department { get; set; } = "";
        public string VerifiedBy { get; set; } = "";
        public string Result { get; set; } = "";
        public string Reason { get; set; } = "";
        public DateTime? Timestamp { get; set; }
    }
}
