using System.ComponentModel.DataAnnotations;

namespace WebApplication1.Models
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
