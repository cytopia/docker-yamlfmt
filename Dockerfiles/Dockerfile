FROM alpine:3.9
LABEL \
	maintainer="cytopia <cytopia@everythingcli.org>" \
	repo="https://github.com/cytopia/docker-yamlfmt"

ARG VERSION=latest
RUN set -x \
	&& apk add --no-cache \
		bash \
		python3 \
	&& if [ "${VERSION}" = "latest" ]; then \
		pip3 install --no-cache-dir --no-compile yamlfmt; \
	else \
		pip3 install --no-cache-dir --no-compile yamlfmt==${VERSION}; \
	fi \
	&& find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf \
	&& find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf

COPY ./data/docker-entrypoint.sh /docker-entrypoint.sh
WORKDIR /data
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--help"]
