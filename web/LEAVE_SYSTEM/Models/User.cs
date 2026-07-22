namespace LEAVE_SYSTEM.Models
{
    using Google.Cloud.Firestore;

    [FirestoreData]
    public class User
    {
        [FirestoreDocumentId]
        public string Id { get; set; }

        [FirestoreProperty("firstname")]
        public string FirstName { get; set; }

        [FirestoreProperty("surname")]
        public string Surname { get; set; }

        [FirestoreProperty("email")]
        public string Email { get; set; }
    }
}
