using CloudinaryDotNet;
using Firebase.Auth;
using FirebaseAdmin;
using Google.Cloud.Firestore;
using WebApplication1.services;
using Amazon;
using Amazon.Rekognition;
using Amazon.Runtime;

var builder = WebApplication.CreateBuilder(args);

//string path = Path.Combine(Directory.GetCurrentDirectory(), "secrets", "firebase-admin-sdk-key.json");
//Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", path);


builder.Services.AddSingleton<IAmazonRekognition>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    var accessKey = config["AWS:AccessKey"];
    var secretKey = config["AWS:SecretKey"];
    var region = RegionEndpoint.GetBySystemName(config["AWS:Region"]);
    return new AmazonRekognitionClient(new BasicAWSCredentials(accessKey, secretKey), region);
});

builder.Services.AddScoped<FaceComparisonService>();

builder.WebHost.ConfigureKestrel(serverOptions => { 
    serverOptions.ListenAnyIP(5000);
   // serverOptions.ListenAnyIP(5001,
   // listenOptions => { listenOptions.UseHttps(); });
});

string path = Path.Combine(Directory.GetCurrentDirectory(), "secrets", "firebase-admin-sdk-key.json");
Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", path);

FirebaseApp.Create();

builder.Services.AddSingleton(provider =>
    new FirebaseAuthProvider(
        new FirebaseConfig("")
    )
);
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
        policy
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod());
});

// Register Cloudinary
var cloudName = builder.Configuration["Cloudinary:CloudName"];
var apiKey = builder.Configuration["Cloudinary:ApiKey"];
var apiSecret = builder.Configuration["Cloudinary:ApiSecret"];

var account = new Account(cloudName, apiKey, apiSecret);
var cloudinary = new Cloudinary(account) { Api = { Secure = true } };
builder.Services.AddSingleton(cloudinary);




// Register Firestore
builder.Services.AddSingleton(provider => FirestoreDb.Create("leavesystem-520ac"));



builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();
app.UseCors("AllowFlutter");

app.UseAuthorization();


app.MapControllers();

app.Run();
