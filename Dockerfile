# Stage 1: Build the application
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS builder
ARG TARGETARCH

WORKDIR /usr/src/app/

# 1. Copy project files and NuGet config first
COPY ./src/cart.csproj ./src/
COPY ./NuGet.config ./

# 2. Copy the pb folder (Required for restore to see gRPC definitions)
COPY ./pb/ ./pb/

# 3. Restore dependencies
RUN dotnet restore ./src/cart.csproj -r linux-musl-$TARGETARCH

# 4. NOW copy the rest of the source code (After restore, so it doesn't overwrite)
COPY ./src/ ./src/

# 5. Build and Publish
RUN dotnet publish ./src/cart.csproj -r linux-musl-$TARGETARCH --no-restore -o /cart

# Stage 2: Final runtime image
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine3.20

WORKDIR /usr/src/app/
COPY --from=builder /cart/ ./

ENV DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE=false

# Port mapping for the Cart Service
EXPOSE ${CART_PORT}

ENTRYPOINT [ "./cart" ]