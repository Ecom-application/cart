# Stage 1: Build the application
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS builder
ARG TARGETARCH

WORKDIR /usr/src/app/

# 1. Copy NuGet config to the root
COPY ./NuGet.config ./

# 2. Create the exact folder structure the .csproj expects
# We put the project file inside a 'src' folder
COPY ./src/cart.csproj ./src/
# We put the protos inside a 'pb' folder at the same level as 'src'
COPY ./pb/ ./pb/

# 3. Restore dependencies
# We run restore from the root, pointing to the file in the subfolder
RUN dotnet restore ./src/cart.csproj -r linux-musl-$TARGETARCH

# 4. Copy the rest of the source code into 'src'
COPY ./src/ ./src/

# 5. Build and Publish
# The compiler now sees 'pb' at '../pb' relative to 'src/cart.csproj'
RUN dotnet publish ./src/cart.csproj -r linux-musl-$TARGETARCH --no-restore -o /cart

# Stage 2: Final runtime image
FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine3.20

WORKDIR /usr/src/app/
COPY --from=builder /cart/ ./

ENV DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE=false
EXPOSE ${CART_PORT}

ENTRYPOINT [ "./cart" ]