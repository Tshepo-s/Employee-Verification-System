using System.ComponentModel.DataAnnotations;

namespace LEAVE_SYSTEM.Models
{
    public class LoginViewModel
    {
        [EmailAddress]
        [Required]
        public string EmailAddress { get; set; }

        [Required]
        public string Password { get; set; }
    }
}
