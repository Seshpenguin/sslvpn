FROM ubuntu:18.04

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN sed -i 's/# deb/deb/g' /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y systemd

RUN cd /lib/systemd/system/sysinit.target.wants/ \
    && ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1


# Add User Account and copy ssh key
RUN useradd vpn
RUN mkdir /home/vpn
RUN mkdir /home/vpn/.ssh
COPY id_rsa.pub /home/vpn/.ssh/authorized_keys

RUN apt-get install stunnel4 apache2 sslh openssh-server -y
#RUN openssl genrsa -des3 -out stunnel.key 4096
#RUN openssl req -new -key stunnel.key -x509 -days 1000 -out stunnel.crt

RUN openssl req \
        -new \
        -newkey ec \
        -pkeyopt ec_paramgen_curve:prime256v1 \
        -days 365 \
        -nodes \
        -x509 \
        -subj "/C=CA/ST=Ontario/L=Toronto/O=Organization/CN=droplet.dolphinbox.net" \
        -keyout stunnel.key \
        -out stunnel.crt


RUN cat stunnel.crt stunnel.key > stunnel.pem && mv stunnel.pem /etc/stunnel/
COPY stunnel.conf /etc/stunnel/stunnel.conf
RUN sed -i "s/ENABLED=.*/ENABLED=1/g" /etc/default/stunnel4
RUN sed -i "s/#GatewayPorts.*/GatewayPorts yes/g" /etc/ssh/sshd_config
RUN sed -i "s/RUN=.*/RUN=yes/g" /etc/default/sslh
RUN sed -i '/DAEMON_OPTS/d' /etc/default/sslh
RUN echo 'DAEMON_OPTS="--user sslh --listen 0.0.0.0:8080 --ssh 127.0.0.1:22 --http 127.0.0.1:80 --pidfile /var/run/sslh/sslh.pid"' >> /etc/default/sslh
RUN cat /etc/default/sslh

RUN systemctl enable stunnel4 && systemctl enable apache2 && systemctl enable sslh && systemctl enable ssh
RUN systemctl disable dev-sda1.device

RUN apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 443
EXPOSE 80

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/lib/systemd/systemd"]
