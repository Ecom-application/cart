# Stage 1: Build the application
# Use the .NET 8 SDK for building as required by the project file
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS builder
ARG TARGETARCH

WORKDIR /usr/src/app/

# Copy only project files first for better layer caching
COPY ./src/cart.csproj ./src/
COPY ./NuGet.config ./

# Restore dependencies for the target architecture
RUN dotnet restore ./src/cart.csproj -r linux-musl-$TARGETARCH

# Copy the remaining source code and protobuf definitions
COPY ./src/ ./src/
COPY ./pb/ ./pb/

# Publish as a self-contained, single-file executable
RUN dotnet publish ./src/cart.csproj -r linux-musl-$TARGETARCH --no-restore -o /cart

# Stage 2: Final runtime image
# Use the alpine-based runtime-deps for a lightweight container
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine3.20

WORKDIR /usr/src/app/
COPY --from=builder /cart/ ./

# Disable configuration reloading to optimize for container environments
ENV DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE=false

# The service uses Kestrel with HTTP2 for gRPC
# It will listen on the port provided by the CART_PORT environment variable
EXPOSE ${CART_PORT}

ENTRYPOINT [ "./cart" ]