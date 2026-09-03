FROM alpine:3.24

RUN apk add --no-cache \
        nut \
        libusb \
        su-exec \
    && mkdir -p /run/nut /var/state/nut \
    && chown -R nut:nut /run/nut /var/state/nut

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3493

ENTRYPOINT ["/entrypoint.sh"]
