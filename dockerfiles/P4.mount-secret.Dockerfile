# syntax=docker/dockerfile:1
# P4 (CONTROL): fake secret supplied via --mount=type=secret; never written to a layer.
FROM alpine:3.20 AS builder
WORKDIR /app
RUN --mount=type=secret,id=tok \
    test -s /run/secrets/tok && echo "built using mounted secret" > /app/out.txt

FROM alpine:3.20 AS final
WORKDIR /app
COPY --from=builder /app/out.txt /app/out.txt
CMD ["cat", "/app/out.txt"]
