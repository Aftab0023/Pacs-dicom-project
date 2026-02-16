FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["PACS.API/PACS.API.csproj", "PACS.API/"]
COPY ["PACS.Core/PACS.Core.csproj", "PACS.Core/"]
COPY ["PACS.Infrastructure/PACS.Infrastructure.csproj", "PACS.Infrastructure/"]
RUN dotnet restore "PACS.API/PACS.API.csproj"
COPY . .
WORKDIR "/src/PACS.API"
RUN dotnet build "PACS.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "PACS.API.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "PACS.API.dll"]
