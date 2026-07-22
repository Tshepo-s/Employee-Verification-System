namespace LEAVE_SYSTEM.Models
{
    public class HomeViewModel
    {
        public string CurrentName { get; set; }
        public List<Log> Logs { get; set; } = new();
    }

}
