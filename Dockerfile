# Lightweight Linux base image
FROM alpine:3.20

# Install only required packages:
#   bash        - the app is written in bash, not POSIX sh
#   coreutils   - full-featured `df`, `uptime`, `date`, etc.
#   iputils     - provides `ping` for network checks
#   bind-tools  - provides `dig` for host resolution
RUN apk add --no-cache bash coreutils iputils bind-tools

WORKDIR /app

# Copy the application into the image
COPY app/ /app/

# Set executable permissions
RUN chmod +x /app/diagnostic.sh /app/health-check.sh

# Run as a non-root user
RUN addgroup -S diag && adduser -S diag -G diag
USER diag

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD ["/app/health-check.sh"]

ENTRYPOINT ["/app/diagnostic.sh"]
CMD ["help"]
