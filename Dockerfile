FROM postgres:9.5
MAINTAINER Jorge Martínez "j.martinezortega@gmail.com"

ENV POSTGIS_MAJOR 2.2
ENV POSTGIS_VERSION 2.2.1+dfsg-2.pgdg80+1

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
    postgis=$POSTGIS_VERSION && \
  rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
  apt-get install -y \
    wget \
    unzip \
  && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /docker-entrypoint-initdb.d &&\
      mkdir -p /data

COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh

COPY docker-entrypoint.sh /
RUN wget http://mapserver.inegi.org.mx/MGN/mge2014v6_2.zip && \
  wget http://mapserver.inegi.org.mx/MGN/mgm2014v6_2.zip && \
  wget http://mapserver.inegi.org.mx/MGN/mglu2014v6_2.zip && \
  wget http://mapserver.inegi.org.mx/MGN/mglr2014v6_2.zip && \
  mv mg*2014*.zip /data/ && \
  cd /data/ && \
  for i in `ls -1`;do unzip $i; rm $i; done

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432

CMD ["postgres"]
