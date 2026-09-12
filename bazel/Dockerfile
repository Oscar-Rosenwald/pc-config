FROM gcr.io/distroless/static:nonroot
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"

# WORKDIR /home/nonroot

EXPOSE 9121
USER 65532
ENTRYPOINT [ \
    "/bazel-remote-linux-amd64", \
    "--http_address=:9121", \
    "--dir=/data", \
    "--profile_address=:6060", \
    "--max_size", "50" \
]