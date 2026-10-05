# syntax=docker/dockerfile:1
# P2b: fake secret arrives as a build ARG only (no ENV promotion) in the builder stage.
# Isolates the build-arg channel (RUN history / provenance invocation args) from P2's
# image-config ENV channel. The RUN consumes the ARG but never writes it to a layer.
FROM alpine:3.20 AS builder
ARG LEAK_MARKER
WORKDIR /app
RUN test -n "$LEAK_MARKER" && echo "built with build-arg present" > /app/out.txt

FROM alpine:3.20 AS final
WORKDIR /app
COPY --from=builder /app/out.txt /app/out.txt
CMD ["cat", "/app/out.txt"]
