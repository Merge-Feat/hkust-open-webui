#!/bin/bash

PORT="${PORT:-8080}"

if [[ "$1" == "--reset" ]]; then
    rm -rf logs/*
fi

uvicorn open_webui.main:app --port $PORT --host 0.0.0.0 --forwarded-allow-ips '*' --reload