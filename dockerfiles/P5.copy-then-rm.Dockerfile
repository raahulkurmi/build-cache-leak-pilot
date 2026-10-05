# syntax=docker/dockerfile:1
# P5 (extra): COPY the secret, then rm it in a LATER layer. The rm does not remove it
# from the earlier layer blob -> expected to leak in the max cache.
FROM alpine:3.20 AS builder
WORKDIR /app
COPY .npmrc /root/.npmrc
RUN rm -f /root/.npmrc && echo "built, secret file deleted later" > /app/out.txt

FROM alpine:3.20 AS final
WORKDIR /app
COPY --from=builder /app/out.txt /app/out.txt
CMD ["cat", "/app/out.txt"]
