namespace WebApplication1.Models
{
    public class TwoFactorViewModel
    {
        public string EmailAddress { get; set; } = "";
        public string Code { get; set; } = "";
        public string Password { get; set; } = ""; 
    }
}
