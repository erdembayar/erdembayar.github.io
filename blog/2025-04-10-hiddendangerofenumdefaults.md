# The Hidden Danger of `0` in Enums

## ⚠️ Why Using `0` as a Default Enum Value in C# Is a Bug Waiting to Happen

I ran into a nasty bug recently that took me hours to track down. The culprit? A simple enum with `Success = 0` in a library we were consuming.

If you've worked with POSIX-style return codes, you know `0` means "everything is fine" and non-zero means something went wrong. That's fine for C and Unix, but it's a time bomb in C#, especially when deserializing data.

Here's why: in C#, any enum variable defaults to `0` when deserialized if the property is missing in the JSON. So what happens when you combine that with `Success = 0`? Disaster.

I know same problem exist in most other languages too.

I honestly think the C# compiler should warn us about this. If you use `0` for anything other than an "undefined" or "none" state in an enum, the compiler should raise a warning or even an error.

When I pointed this out to the library author, they said it's a historic thing: "The train left the station long time ago, now it's hard to change."

## The Real-World Scenario That Bit Me

We were consuming a third-party API that returned operation results. The API had evolved slightly between versions, but our code was still expecting the old format:

```csharp
// The enum in the library
enum OperationResult
{
    Success = 0,
    NotFound = 1,
    Unauthorized = 2,
    Timeout = 3,
    Failed = 4
}

// Our code deserializing the API response
var apiResponse = JsonSerializer.Deserialize<ApiResponse>(jsonData);

// Check the operation status
if (apiResponse.Result == OperationResult.Success)
{
    Console.WriteLine("Everything went fine!");
    // Proceed with operations that assume success
}
```

Here's what was happening: in v2 of the API, they changed the property name from `Result` to `Status`. Our old code was deserializing `Result`, which was now missing from the response. When a property is missing during deserialization, the enum defaults to `0`...which is `Success`!

So our system was reporting successful operations for EVERY API call, regardless of whether they actually succeeded or not. Classic case of "failing silently."

This is particularly nasty because:

1. The code looks perfectly reasonable
2. It works fine with the old API version
3. It silently starts failing when the API changes
4. There's no crash, no exception, nothing to alert you

## A Better Way

After hitting this issue, besides fixing the immediate problem, I added additional assertions to verify that the properties we expect exist in the JSON before attempting deserialization.

These days, I've gone a step further. I always wrap enum properties in nullable types when dealing with serialization:

```csharp
public class ApiResponse
{
    public OperationResult? Result { get; set; }
    // Other properties...
}

// Deserialize
var apiResponse = JsonSerializer.Deserialize<ApiResponse>(jsonData);

// Check the operation status with null check
if (apiResponse.Result == null)
{
    throw new InvalidOperationException("Missing result status in API response!");
}
else if (apiResponse.Result == OperationResult.Success)
{
    Console.WriteLine("Now we KNOW it worked");
}
```

With this pattern, if the property is missing during deserialization, the `Result` will be `null` instead of defaulting to zero. You'll get a clear exception instead of silently assuming success.

## The Real Problem: Historical Baggage

The whole "0 means success" convention comes from the early days of Unix and C, where a minimalist approach made sense. But in a strongly typed language like C#, we have better options.

Honestly, it drives me crazy that the compiler doesn't warn about this pattern. How many hours have been wasted debugging issues caused by it? When I talked to other developers, they shared similar stories — it's a common pain point.

This becomes a serious security risk when used to check whether something passed verification or not.

Bottom line: Don't blindly follow conventions from other languages. In C#, make success a non-zero value, or use nullable types to force explicit handling. And always be extra cautious when deserializing data — structure changes can silently turn into logic bugs.

What about you? Ever been bitten by enum defaults during deserialization?

I filed an issue: https://github.com/dotnet/roslyn/issues/78138, please upvote if you found it useful. 