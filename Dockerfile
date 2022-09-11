FROM node:alpine
LABEL org.opencontainers.image.title="gtfs-via-postgres"
LABEL org.opencontainers.image.description="Process GTFS using PostgreSQL."
LABEL org.opencontainers.image.authors="Jannis R <mail@jannisr.de>"
LABEL org.opencontainers.image.documentation="https://github.com/derhuerst/gtfs-via-postgres"
LABEL org.opencontainers.image.source="https://github.com/derhuerst/gtfs-via-postgres"
LABEL org.opencontainers.image.revision="4.0.0"
LABEL org.opencontainers.image.licenses="(Apache-2.0 AND Prosperity-3.0.0)"

WORKDIR /app
ADD package.json /app
RUN npm install --production && npm cache clean --force

ADD . /app
RUN ln -s /app/cli.js /usr/local/bin/gtfs-via-postgres
RUN apk add --no-cache postgresql-client
ENV PGPORT=5432 PGUSER=postgres PGPASSWORD=password
VOLUME /gtfs
WORKDIR /gtfs


ENTRYPOINT ["/bin/sh", "-c", "env | grep PG; gtfs-via-postgres $0 $@ | psql -b"]
