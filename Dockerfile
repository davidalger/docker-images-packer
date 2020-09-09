FROM centos:8

ARG PACKER_VERSION=1.6.2
ARG PACKER_VERSION_SHA256SUM=089fc9885263bb283f20e3e7917f85bb109d9335f24d59c81e6f3a0d4a96a608

RUN dnf install -y unzip \
    && dnf clean all \
    && rm -rf /var/cache/dnf

RUN curl -s https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
      -o packer_${PACKER_VERSION}_linux_amd64.zip

RUN echo "${PACKER_VERSION_SHA256SUM} packer_${PACKER_VERSION}_linux_amd64.zip" > checksum && sha256sum -c checksum

RUN unzip packer_${PACKER_VERSION}_linux_amd64.zip

FROM davidalger/ansible:2.9
COPY --from=0 packer /usr/bin/packer
ENTRYPOINT ["/usr/bin/packer"]
