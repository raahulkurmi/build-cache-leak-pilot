# syntax=docker/dockerfile:1
# P2: fake secret arrives as a build ARG promoted to ENV in the builder stage.
FROM alpine:3.20 AS builder
ARG SECRET
ENV SECRET=${SECRET}
WORKDIR /app
RUN echo "built with env secret present" > /app/out.txt

FROM alpine:3.20 AS final
WORKDIR /app
COPY --from=builder /app/out.txt /app/out.txt
CMD ["cat", "/app/out.txt"]
