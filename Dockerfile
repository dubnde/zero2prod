FROM rust:1.65 AS chef

# We only pay the installation cost once, 
# it will be cached from the second build onwards
RUN cargo install cargo-chef
WORKDIR /zero2prod

FROM chef AS planner
COPY . .
RUN cargo chef prepare  --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /zero2prod/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build --release --bin zero2prod

# We do not need the Rust toolchain to run the binary!
FROM debian:bullseye-slim AS runtime
WORKDIR /zero2prod
COPY --from=builder /zero2prod/target/release/zero2prod /usr/local/bin
ENTRYPOINT ["/usr/local/bin/zero2prod"]