#!/bin/sh
set -eu

if [ "$(uname -m)" != "x86_64" ]; then
    echo "[ERROR] This image supports Linux x86_64 only." >&2
    exit 1
fi

mkdir -p \
    "${XDG_CACHE_HOME:-/app/data/cache}" \
    "${TORCHINDUCTOR_CACHE_DIR:-/app/data/torchinductor}" \
    "${HF_HOME:-/app/data/huggingface}"

python3 - <<'PY'
import sys

try:
    import torch
except Exception as exc:
    raise SystemExit(f"[ERROR] PyTorch could not be imported: {exc}")

if not torch.cuda.is_available():
    raise SystemExit(
        "[ERROR] CUDA is unavailable. Start the container with the NVIDIA runtime "
        "(for Compose: docker compose up; for Docker: --gpus all)."
    )

major, minor = torch.cuda.get_device_capability(0)
supported = torch.cuda.get_arch_list()
arch = f"sm_{major}{minor}"
if arch not in supported:
    raise SystemExit(
        f"[ERROR] GPU {torch.cuda.get_device_name(0)} requires {arch}, but this "
        f"PyTorch build supports {', '.join(supported)}. Rebuild with a matching "
        "CUDA/PyTorch image."
    )

print(f"[INFO] Python {sys.version.split()[0]}")
print(f"[INFO] PyTorch {torch.__version__}; CUDA {torch.version.cuda}")
print(f"[INFO] GPU: {torch.cuda.get_device_name(0)} ({arch})")
PY

echo "[INFO] Anima LoRA Factory: http://127.0.0.1:${APP_PORT:-8000}"
echo "[INFO] Enter container paths in the UI: /workspace/datasets, /workspace/models, /workspace/output"

cd /app/backend
exec python3 main.py
