using HttpLoggingSample;
using Microsoft.AspNetCore.HttpLogging;
using MugMiles.Services;

namespace MugMiles;

public static class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);
        builder.Logging.ClearProviders();
        builder.Logging.AddConsole();

        builder.Services.AddHttpLogging(logging =>
        {
            logging.LoggingFields = HttpLoggingFields.All;
            logging.CombineLogs = true;
        });
        builder.Services.AddHttpLoggingInterceptor<SampleHttpLoggingInterceptor>();

        // Add services to the container.
        builder.Services.AddGrpc();
        builder.Services.AddGrpcHealthChecks();

        // Configure Kestrel for better cloud deployment
        builder.WebHost.ConfigureKestrel(options =>
        {
            options.ListenAnyIP(8080, listenOptions =>
            {
                listenOptions.Protocols = Microsoft.AspNetCore.Server.Kestrel.Core.HttpProtocols.Http2;
            });
        });

        var app = builder.Build();

        app.UseHttpLogging();

        // Configure the HTTP request pipeline.
        app.MapGrpcService<GreeterService>();
        app.MapGrpcHealthChecksService();
        
        app.MapGet("/",
            () =>
                "Communication with gRPC endpoints must be made through a gRPC client. To learn how to create a client, visit: https://go.microsoft.com/fwlink/?linkid=2086909");

        app.MapGet("/health", () => "OK");

        app.Run();
    }
}
