#!/bin/bash

# 서버 정보
SERVER_USER="mergefeat"
SERVER_IP="10.89.211.27"
CONTAINER_ID="effd9514273e"

# 경로
CONTAINER_DATA_PATH="/app/backend/data"
CONTAINER_OPENWEBUI_DATA_PATH="/app/backend/open_webui/data"
HOST_TEMP_PATH="/home/mergefeat/temp_data_sync"
LOCAL_BASE_PATH="/Users/Jiho/Public/hkust-open-webui/backend"

# 인자 확인
ONLY_OPEN_WEBUI=false
if [[ "$1" == "--owui" ]]; then
  ONLY_OPEN_WEBUI=true
fi

echo "🔄 로컬 디렉토리 삭제 중..."

if $ONLY_OPEN_WEBUI; then
  rm -rf "$LOCAL_BASE_PATH/open_webui/data"
  mkdir -p "$LOCAL_BASE_PATH/open_webui/data"
else
  rm -rf "$LOCAL_BASE_PATH/data"
  rm -rf "$LOCAL_BASE_PATH/open_webui/data"
  mkdir -p "$LOCAL_BASE_PATH/data"
  mkdir -p "$LOCAL_BASE_PATH/open_webui/data"
fi

echo "🚀 서버에서 도커 컨테이너 파일을 호스트로 복사 중..."
ssh ${SERVER_USER}@${SERVER_IP} <<EOF
  mkdir -p ${HOST_TEMP_PATH}
  rm -rf ${HOST_TEMP_PATH}/data ${HOST_TEMP_PATH}/open_webui_data

  ${ONLY_OPEN_WEBUI:+sudo docker cp ${CONTAINER_ID}:${CONTAINER_OPENWEBUI_DATA_PATH} ${HOST_TEMP_PATH}/open_webui_data}
  ${ONLY_OPEN_WEBUI:-sudo docker cp ${CONTAINER_ID}:${CONTAINER_DATA_PATH} ${HOST_TEMP_PATH}/data && sudo docker cp ${CONTAINER_ID}:${CONTAINER_OPENWEBUI_DATA_PATH} ${HOST_TEMP_PATH}/open_webui_data}
EOF

echo "📦 복사된 파일을 로컬로 가져오는 중..."
if $ONLY_OPEN_WEBUI; then
  scp -r ${SERVER_USER}@${SERVER_IP}:${HOST_TEMP_PATH}/open_webui_data/* "$LOCAL_BASE_PATH/open_webui/data/"
else
  scp -r ${SERVER_USER}@${SERVER_IP}:${HOST_TEMP_PATH}/data/* "$LOCAL_BASE_PATH/data/"
  scp -r ${SERVER_USER}@${SERVER_IP}:${HOST_TEMP_PATH}/open_webui_data/* "$LOCAL_BASE_PATH/open_webui/data/"
fi

echo "✅ 데이터 동기화 완료!"
