namespace LEAVE_SYSTEM.Models
{
    public class AuditTrailModel
    {
        public string Reference { get; set; }
        public string Employee { get; set; }
        public string Department { get; set; }
        public string Action { get; set; }
        public DateTime? Timestamp { get; set; }
        public string Reason { get; set; }
    }

}
