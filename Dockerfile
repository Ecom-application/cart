# Stage 1: Build the application
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS builder
ARG TARGETARCH

# Set the root workspace
WORKDIR /usr/src/app/

# 1. Copy NuGet config to the root
COPY ./NuGet.config ./

# 2. Copy the pb folder to /usr/src/app/pb/
COPY ./pb/ ./pb/

# 3. Copy the src folder to /usr/src/app/src/
COPY ./src/ ./src/

# 4. Move INTO the src folder to run commands
# This ensures $(ProjectDir) is correctly identified as /usr/src/app/src/
WORKDIR /usr/src/app/src/

# 5. Restore dependencies
# Since we are inside the 'src' folder, we point to the local file
RUN dotnet restore cart.csproj -r linux-musl-$TARGETARCH

# 6. Build and Publish
# Relative path ../pb is now perfectly aligned
RUN dotnet publish cart.csproj -r linux-musl-$TARGETARCH --no-restore -o /cart

# Stage 2: Final runtime image
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine3.20

WORKDIR /usr/src/app/
COPY --from=builder /cart/ ./

ENV DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE=false
EXPOSE ${CART_PORT}

ENTRYPOINT [ "./cart" ]