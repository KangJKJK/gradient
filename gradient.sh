#!/bin/bash

# 색깔 변수 정의
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 환경 변수 설정
export WORK="/root/gradient-bot"

# 사용자 선택 메뉴
echo -e "${GREEN}스크립트작성자: https://t.me/kjkresearch${NC}"
echo -e "${BOLD}${CYAN}1. gradient 노드 설치${NC}"
echo -e "${BOLD}${CYAN}2. gradient 노드 업데이트${NC}"
echo -e "${BOLD}${CYAN}3. gradient 노드 제거${NC}"
read -p "원하는 작업을 선택하세요 (1/2/3): " choice

case $choice in
    1)
        echo -e "${YELLOW}gradient 노드를 설치합니다.${NC}"

        # 필수 패키지 설치
        echo -e "${BOLD}${CYAN}필수 패키지 설치 중...${NC}"
        sudo apt-get update
        sudo apt-get -y upgrade
        sudo apt update
        sudo apt install git
        sudo apt-get install -y ufw

        echo -e "${YELLOW}작업 공간 준비 중...${NC}"
        if [ -d "$WORK" ]; then
            echo -e "${YELLOW}기존 작업 공간 삭제 중...${NC}"
            rm -rf "$WORK"
        fi

        git clone https://github.com/web3bothub/gradient-bot
        cd "$WORK"

        # Docker 설치 준비
        echo -e "${YELLOW}Docker 설치 준비 중...${NC}"
        sudo apt-get update
        sudo apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release

        # Docker 공식 GPG 키 추가
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        # Docker 저장소 추가
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Docker 설치 확인 및 설정
        if ! command -v docker &> /dev/null; then
            echo -e "${YELLOW}Docker가 설치되어 있지 않습니다. Docker를 설치합니다...${NC}"
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # Docker 서비스 시작 및 활성화
            sudo systemctl start docker
            sudo systemctl enable docker
            
            # 현재 사용자를 docker 그룹에 추가
            sudo usermod -aG docker $USER
            echo -e "${GREEN}Docker 설치가 완료되었습니다. 변경사항을 적용하려면 시스템을 재로그인하세요.${NC}"
        else
            echo -e "${GREEN}Docker가 이미 설치되어 있습니다.${NC}"
        fi

        # Docker Compose 설치
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

        # 프록시 정보 입력 안내
        echo -e "${YELLOW}프록시 정보를 입력하세요. 입력형식: http://user:pass@ip:port${NC}"
        echo -e "${YELLOW}여러 개의 프록시는 줄바꿈으로 구분하세요.${NC}"
        echo -e "${YELLOW}입력을 마치려면 엔터를 두 번 누르세요.${NC}"

        # 프록시 타입 선택
        read -p "프록시 타입을 선택하세요 (1: HTTP, 2: SOCKS5): " proxy_type

        # proxies.txt 파일 초기화
        > "$WORK/proxies.txt"

        # 프록시 정보 입력 받기
        while IFS= read -r line; do
            [[ -z "$line" ]] && break
            
            case $proxy_type in
                1)
                    # HTTP를 SOCKS5로 변환
                    socks5_line="${line/http:/socks5:}"
                    echo "$socks5_line" >> "$WORK/proxies.txt"
                    ;;
                2)
                    # SOCKS5는 그대로 저장
                    echo "$line" >> "$WORK/proxies.txt"
                    ;;
                *)
                    echo -e "${RED}잘못된 선택입니다. 프로그램을 종료합니다.${NC}"
                    exit 1
                    ;;
            esac
        done

        echo -e "${GREEN}프록시 정보가 proxies.txt 파일에 저장되었습니다.${NC}"

        # 사용자에게 이메일과 비밀번호 입력 받기
        echo -e "${YELLOW}소셜계정으로 가입하신 경우 대시보드에서 forgot password를 클릭한 후 패스워드를 생성하셔야합니다.${NC}"
        echo -e "${YELLOW}입력을 마치려면 엔터를 두 번 누르세요.${NC}"
        read -p "이메일을 입력하세요: " APP_USER
        read -p "비밀번호를 입력하세요: " APP_PASS
        echo

        # Docker 명령어 실행
        docker run -d \
        -e APP_USER="$APP_USER" \
        -e APP_PASS="$APP_PASS" \
        -v ./proxies.txt:/app/proxies.txt \
        overtrue/gradient-bot

        # 현재 사용 중인 포트 확인
        used_ports=$(netstat -tuln | awk '{print $4}' | grep -o '[0-9]*$' | sort -u)

        # 각 포트에 대해 ufw allow 실행
        for port in $used_ports; do
            echo -e "${GREEN}포트 ${port}을(를) 허용합니다.${NC}"
            sudo ufw allow $port/tcp
        done


        echo -e "${YELLOW}현재 실행 중인 gradient 관련 컨테이너 목록:${NC}"
        docker ps | grep gradient
        read -p "gradient 컨테이너 ID를 입력하세요. 맨앞에있는 알파뱃과 숫자의 혼합입니다.: " container_id1
        echo -e "${YELLOW}로그를 보시려면 다음 명령어를 입력하세요: docker logs -f $container_id1${NC}"
        ;;
    2)
        echo -e "${YELLOW}gradient 노드를 업데이트합니다.${NC}"
        cd "$WORK"
        sudo apt-get update
        sudo apt-get -y upgrade
        # gradient 컨테이너 제거
        echo -e "${YELLOW}현재 실행 중인 gradient 관련 컨테이너 목록:${NC}"
        docker ps | grep gradient  # gradient 관련 컨테이너 목록 출력
        read -p "제거할 gradient 컨테이너 ID를 입력하세요: " container_id
        docker rm -f "$container_id"  # 컨테이너 강제 제거
        echo -e "${GREEN}컨테이너 $container_id 가 제거되었습니다.${NC}"
        docker pull overtrue/gradient-bot

        # 현재 사용 중인 포트 확인
        used_ports=$(netstat -tuln | awk '{print $4}' | grep -o '[0-9]*$' | sort -u)

        # 각 포트에 대해 ufw allow 실행
        for port in $used_ports; do
            echo -e "${GREEN}포트 ${port}을(를) 허용합니다.${NC}"
            sudo ufw allow $port/tcp
        done

         # 사용자에게 이메일과 비밀번호 입력 받기
        read -p "이메일을 입력하세요: " APP_USER
        read -p "비밀번호를 입력하세요: " APP_PASS
        echo

        # Docker 명령어 실행
        docker run -d \
        -e APP_USER="$APP_USER" \
        -e APP_PASS="$APP_PASS" \
        -v ./proxies.txt:/app/proxies.txt \
        overtrue/gradient-bot
        ;;

    3)
        echo -e "${YELLOW}gradient 노드를 중지하고 완전히 제거합니다.${NC}"
        
        # 실행 중인 모든 gradient 컨테이너 찾아서 중지 및 제거
        echo -e "${YELLOW}실행 중인 모든 gradient 컨테이너를 중지하고 제거합니다...${NC}"
        docker ps -a | grep gradient | awk '{print $1}' | xargs -r docker stop
        docker ps -a | grep gradient | awk '{print $1}' | xargs -r docker rm
        
        # gradient 관련 Docker 이미지 제거
        echo -e "${YELLOW}gradient 관련 Docker 이미지를 제거합니다...${NC}"
        docker images | grep gradient | awk '{print $3}' | xargs -r docker rmi -f
        echo
        
        # 작업 디렉토리 제거
        if [ -d "$WORK" ]; then
            echo -e "${YELLOW}작업 디렉토리를 제거합니다...${NC}"
            rm -rf "$WORK"
        fi
        
        echo -e "${GREEN}gradient 노드가 완전히 제거되었습니다.${NC}"
        ;;

    *)
        echo -e "${RED}잘못된 선택입니다. 1, 2, 3 중 하나를 선택하세요.${NC}"
        ;;
esac
