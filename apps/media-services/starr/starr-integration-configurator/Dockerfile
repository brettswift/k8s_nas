FROM alpine:3.20

# Install dependencies
RUN apk add --no-cache \
    curl \
    jq \
    bash \
    kubectl

# Copy configuration script
COPY configure-integrations.sh /usr/local/bin/configure-integrations.sh
RUN chmod +x /usr/local/bin/configure-integrations.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/configure-integrations.sh"]

