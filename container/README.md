# Anima LoRA Factory 5.1 — Linux x86_64 CUDA container

This directory contains a headless Linux container build. It does not launch a
desktop UI or a browser. Open the web UI manually from the host.

The build verifies and extracts the upstream release ZIP from the repository,
then applies `patches/linux-container.patch`. The expanded application source
is not duplicated in this branch.

## Requirements

- Linux x86_64
- NVIDIA GPU and a compatible NVIDIA driver
- Docker Engine with Docker Compose
- NVIDIA Container Toolkit configured for Docker
- Python is not required on the host

The default image uses the configuration verified by a complete LoRA training
and ComfyUI conversion run on an NVIDIA RTX PRO 4000 Blackwell (`sm_120`):
PyTorch 2.11.0, torchvision 0.26.0, and CUDA 12.8 (`cu128`).

## Start

1. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

2. Relative data paths default to directories beside this README. You can edit
   `.env` to use absolute host paths instead. The model directory must contain
   the Anima base model, VAE, and Qwen3 text encoder. Set `HOST_UID` and
   `HOST_GID` to the owner of those directories (`id -u` and `id -g`) so output
   files are not created as root.

3. Build and start:

   ```bash
   docker compose build
   docker compose up -d
   docker compose logs -f
   ```

4. Open <http://127.0.0.1:8000> manually.

Use these paths in the web UI:

| Purpose | Container path |
| --- | --- |
| Training images | `/workspace/datasets` |
| Anima base model | `/workspace/models/<base-model>.safetensors` |
| VAE | `/workspace/models/<vae>.safetensors` |
| Qwen3 encoder | `/workspace/models/<qwen3>.safetensors` |
| Output directory | `/workspace/output` |

Each path field also has a **Select** button. It opens a server-side browser
limited to the corresponding mounted directory. Dataset and output fields can
select directories; model, VAE, and Qwen3 fields show `.safetensors` files from
`/workspace/models`. Manual path entry remains available.

Native desktop file dialogs and automatic shutdown are disabled in the
container build.
Training history is persisted in `./state`.
PyTorch, TorchInductor, and Hugging Face caches are also stored below
`./state`, with an explicit container username so arbitrary host UID/GID values
work even when they do not have an entry in the image's `/etc/passwd`.

## Stop

```bash
docker compose down
```

## Diagnostics

Verify Docker GPU access before troubleshooting the application:

```bash
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
```

The container exits early if CUDA is unavailable or the installed PyTorch wheel
does not contain code for the detected GPU architecture.

## Upstream updates

For a new upstream ZIP, update `UPSTREAM_ARCHIVE`, `UPSTREAM_DIRECTORY`, and
`UPSTREAM_SHA256` together, then refresh `patches/linux-container.patch` against
that exact source. Patch application uses `--fuzz=0`, so a conflicting upstream
change stops the image build instead of silently applying an uncertain merge.

## Network exposure

Compose publishes the UI on host loopback only. Do not change the binding to
`0.0.0.0` without adding authentication and reviewing the file-serving API.
