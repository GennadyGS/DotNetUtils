dotnet restore --source $env:UserProfile\.nuget\packages\
dotnet build --no-restore $args
