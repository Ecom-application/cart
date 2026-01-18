# Stage 1: Build the application
# Use the .NET 8 SDK image for building
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS builder
ARG TARGETARCH

WORKDIR /usr/src/app/

# Copy the source code and protobuf definitions
# Based on the provided project structure
COPY ./src/ ./src/
COPY ./pb/ ./pb/

# Restore dependencies for the specific target architecture
RUN dotnet restore ./src/cart.csproj -r linux-musl-$TARGETARCH

# Publish the application as a self-contained executable
RUN dotnet publish ./src/cart.csproj -r linux-musl-$TARGETARCH --no-restore -o /cart

# Stage 2: Create the runtime image
# Use a minimal alpine-based runtime-deps image
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine3.20

WORKDIR /usr/src/app/

# Copy the published output from the builder stage
COPY --from=builder /cart/ ./

# Environment variable to prevent reloading config on change in container environments
ENV DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE=false

# Expose the port used by the Cart Service
EXPOSE ${CART_PORT}

# Set the entry point to the service executable
ENTRYPOINT [ "./cart" ]