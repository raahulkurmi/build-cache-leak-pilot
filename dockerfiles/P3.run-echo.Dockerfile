# syntax=docker/dockerfile:1
# P3: fake secret written to a file by RUN echo in the builder stage.
FROM alpine:3.20 AS builder
ARG SECRET
WORKDIR /app
RUN echo "$SECRET" > /tmp/secret.txt && echo "built" > /app/out.txt

FROM alpine:3.20 AS final
WORKDIR /app
COPY --from=builder /app/out.txt /app/out.txt
CMD ["cat", "/app/out.txt"]
