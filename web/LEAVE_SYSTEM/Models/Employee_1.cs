using Google.Cloud.Firestore;
using System.ComponentModel.DataAnnotations;

namespace LEAVE_SYSTEM.Models
{
    public class Employee
    {
        public Timestamp CreatedAt { get; set; }

        [Display(Name = "First Name")]
        [Required(ErrorMessage = "First Name is required.")]
        [StringLength(50, MinimumLength = 2, ErrorMessage = "The First Name must be between 2 and 50 characters.")]
        [RegularExpression("^[a-zA-Z]+$", ErrorMessage = "Only characters are allowed.")]
        public string FirstName { get; set; }

        [Display(Name = "Surname")]
        [Required(ErrorMessage = "Surname is required.")]
        [StringLength(50, MinimumLength = 2, ErrorMessage = "The Surname must be between 2 and 50 characters.")]
        [RegularExpression("^[a-zA-Z]+$", ErrorMessage = "Only characters are allowed.")]
        public string Surname { get; set; }

        [EmailAddress]
        [Required(ErrorMessage = "Email is required.")]
        [RegularExpression(@"^[^@\s]+@[^@\s]+\.[^@\s]+$", ErrorMessage = "Invalid email address format.")]
        public string EmailAddress { get; set; }

        [Required(ErrorMessage = "Password is required.")]
        [RegularExpression(@"^(?=.*@).{8,}$", ErrorMessage = "Password must be at least 8 characters long and include the '@' symbol.")]
        [DataType(DataType.Password)]
        public string Password { get; set; }


        [Required(ErrorMessage = "Department is required.")]
        public string Department { get; set; }

        [Required(ErrorMessage = "Contract is required.")]
        public string Contract { get; set; }

        [Required(ErrorMessage = "Gender is required.")]
        public string Gender { get; set; }

        [Required(ErrorMessage = "ID Number is required.")]
        public string IdNumber { get; set; }

        [Required(ErrorMessage = "Employee Number is required.")]
        public string EmployeeNumber { get; set; }


        [Required(ErrorMessage = "POPIA consent is required.")]
        public string PopiaConsent { get; set; }
        public string ProfileImageBase64 { get; set; }  
    }
}
