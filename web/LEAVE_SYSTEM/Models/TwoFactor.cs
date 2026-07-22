namespace LEAVE_SYSTEM.Models
{
    public class TwoFactor
    {

        public string EmailAddress { get; set; } = "";
        public string Code { get; set; } = "";
        public string Password { get; set; } = "";
    }
}
