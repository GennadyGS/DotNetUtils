dotnet restore --source $env:user\.nuget\packages\
dotnet build --no-restore $args
