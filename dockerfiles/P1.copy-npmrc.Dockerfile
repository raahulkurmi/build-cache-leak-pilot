# syntax=docker/dockerfile:1
# P1: fake secret arrives as a COPY'd file (.npmrc) in the builder stage.
FROM alpine:3.20 AS builder
WORKDIR /app
# build context contains .npmrc holding FAKE-SECRET-P1-...-DO-NOT-USE
COPY .npmrc /root/.npmrc
RUN echo "built with npmrc present" > /app/out.txt

FROM alpine:3.20 AS final
WORKDIR /app
COPY --from=builder /app/out.txt /app/out.txt
CMD ["cat", "/app/out.txt"]
