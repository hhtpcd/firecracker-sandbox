FROM rust:1.68 AS builder

RUN apt-get update && apt-get install clang --no-install-recommends -y

WORKDIR /usr/src/overlay-init

COPY . .

RUN cargo install --path .

FROM debian:latest

USER root

RUN mkdir -p /mnt

COPY --from=builder /usr/local/cargo/bin/overlay-init /usr/sbin/init
