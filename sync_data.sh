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

# 사용자 확인 프롬프트
echo "🛠  이 작업은 로컬 데이터를 삭제하고 서버에서 복사해옵니다."
if $ONLY_OPEN_WEBUI; then
  echo "📂 open_webui/data 만 동기화합니다."
else
  echo "📂 data 와 open_webui/data 둘 다 동기화합니다."
fi
read -p "계속하시겠습니까? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "❌ 작업이 취소되었습니다."
  exit 1
fi

# sudo 권한 체크
if [[ "$EUID" -ne 0 ]]; then
  echo "🔐 sudo 권한이 필요합니다. 비밀번호를 입력해주세요."
  exec sudo "$0" "$@"
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
ssh -t ${SERVER_USER}@${SERVER_IP} <<EOF
  echo "🧼 임시 폴더 정리 중..."
  sudo mkdir -p ${HOST_TEMP_PATH}
  sudo rm -rf ${HOST_TEMP_PATH}/data ${HOST_TEMP_PATH}/open_webui_data

  if $ONLY_OPEN_WEBUI; then
    echo "📦 open_webui/data 가져오는 중..."
    sudo docker cp ${CONTAINER_ID}:${CONTAINER_OPENWEBUI_DATA_PATH} ${HOST_TEMP_PATH}/open_webui_data
  else
    echo "📦 전체 데이터 가져오는 중..."
    sudo docker cp ${CONTAINER_ID}:${CONTAINER_DATA_PATH} ${HOST_TEMP_PATH}/data
    sudo docker cp ${CONTAINER_ID}:${CONTAINER_OPENWEBUI_DATA_PATH} ${HOST_TEMP_PATH}/open_webui_data
  fi
EOF

echo "📥 로컬로 복사 중..."
if $ONLY_OPEN_WEBUI; then
  scp -r ${SERVER_USER}@${SERVER_IP}:${HOST_TEMP_PATH}/open_webui_data/* "$LOCAL_BASE_PATH/open_webui/data/"
else
  scp -r ${SERVER_USER}@${SERVER_IP}:${HOST_TEMP_PATH}/data/* "$LOCAL_BASE_PATH/data/"
  scp -r ${SERVER_USER}@${SERVER_IP}:${HOST_TEMP_PATH}/open_webui_data/* "$LOCAL_BASE_PATH/open_webui/data/"
fi

echo "✅ 데이터 동기화 완료!"
