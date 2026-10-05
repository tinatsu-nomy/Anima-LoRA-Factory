ARG CUDA_IMAGE=nvidia/cuda:12.8.0-runtime-ubuntu22.04

FROM ubuntu:22.04 AS source

ENV DEBIAN_FRONTEND=noninteractive

ARG UPSTREAM_ARCHIVE=Anima-LoRA-Factory-v5.1.zip
ARG UPSTREAM_DIRECTORY=Anima-LoRA-Factory-v5.1
ARG UPSTREAM_SHA256=6d79ca7f7ecea0f3972605babc06ef91b97787625ea50a2fba7a7c1a9e6ccb8b

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates patch unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /source

COPY ${UPSTREAM_ARCHIVE} /tmp/upstream.zip
RUN echo "${UPSTREAM_SHA256}  /tmp/upstream.zip" | sha256sum -c - \
    && unzip -q /tmp/upstream.zip -d /source \
    && mv "/source/${UPSTREAM_DIRECTORY}" /source/app

COPY container/patches/linux-container.patch /tmp/linux-container.patch
RUN patch --batch --forward --fuzz=0 -p1 -d /source/app < /tmp/linux-container.patch \
    && rm -rf \
        /source/app/backend/sd-scripts/bitsandbytes_windows \
        /source/app/start.bat

FROM ${CUDA_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONUTF8=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    HOME=/app/data \
    USER=anima \
    LOGNAME=anima \
    XDG_CACHE_HOME=/app/data/cache \
    TORCHINDUCTOR_CACHE_DIR=/app/data/torchinductor \
    APP_PORT=8000

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libglib2.0-0 \
        libgl1 \
        python3.10 \
        python3.10-venv \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

ARG TORCH_SPEC=torch==2.11.0
ARG TORCHVISION_SPEC=torchvision==0.26.0
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cu128

WORKDIR /app

COPY --from=source /source/app/backend/requirements.txt /tmp/app-requirements.txt
COPY --from=source /source/app/backend/sd-scripts/requirements.txt /tmp/sd-scripts-requirements.txt
COPY --from=source /source/app/backend/sd-scripts/setup.py /app/backend/sd-scripts/setup.py
COPY --from=source /source/app/backend/sd-scripts/library /app/backend/sd-scripts/library

RUN python3 -m pip install --upgrade pip setuptools wheel \
    && python3 -m pip install "${TORCH_SPEC}" "${TORCHVISION_SPEC}" --index-url "${TORCH_INDEX_URL}" \
    && python3 -m pip install -r /tmp/app-requirements.txt \
    && cd /app/backend/sd-scripts \
    && python3 -m pip install -r /tmp/sd-scripts-requirements.txt

COPY --from=source /source/app /app
COPY container/docker-entrypoint.sh /usr/local/bin/anima-lora-factory

RUN chmod 0755 /usr/local/bin/anima-lora-factory \
    && mkdir -p /workspace/datasets /workspace/models /workspace/output /app/data

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/', timeout=3)" || exit 1

ENTRYPOINT ["/usr/local/bin/anima-lora-factory"]
