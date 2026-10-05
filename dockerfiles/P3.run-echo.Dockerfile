# syntax=docker/dockerfile:1
# P3: fake secret written to a file by RUN echo in the builder stage.
# The marker is a literal baked into the RUN: 02_gen_secrets.sh substitutes __MARKER__
# in the per-run context copy. No build-arg, so P3 does not depend on P2's SECRET arg.
FROM alpine:3.20 AS builder
WORKDIR /app
RUN echo "__MARKER__" > /tmp/secret.txt && echo "built" > /app/out.txt

FROM alpine:3.20 AS final
WORKDIR /app
COPY --from=builder /app/out.txt /app/out.txt
CMD ["cat", "/app/out.txt"]
