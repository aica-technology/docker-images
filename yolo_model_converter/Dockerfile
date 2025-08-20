ARG PYTHON_VERSION=3.12

FROM python:${PYTHON_VERSION}-slim

ARG ULTRALYTICS_VERSION=8.3.182
ENV UID=1000
ENV GID=1000

RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir \
                ultralytics==${ULTRALYTICS_VERSION} \
                "onnx<1.18.0" \
                opencv-python-headless

RUN apt-get update && apt-get install --no-install-recommends -y \
      libgl1 \
      libglib2.0-0 \
      libsm6 \
      libxrender1 \
      libxext6 \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /ws
RUN cat <<EOF > converter.py
#!/usr/bin/env python3
import os
import shutil
from pathlib import Path
from ultralytics import YOLO
model_name = os.getenv("model")
if model_name:
    model = YOLO(model_name)
    model.export(format="onnx")
    export_name = model_name.replace('.pt', '.onnx')
    export_name = Path(export_name).name
    shutil.move(f"{export_name}", "/exports/")
    os.chown(f"/exports/{export_name}", int(os.getenv("UID")), int(os.getenv("GID")))
else:
    print("No model specified")
EOF
RUN chmod +x converter.py

ENTRYPOINT [ "/ws/converter.py" ]