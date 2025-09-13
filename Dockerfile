FROM node:16

ENV LANG C.UTF-8
WORKDIR /ws-scrcpy

# 安装依赖工具
RUN npm install -g node-gyp
RUN apt update && apt install android-tools-adb -y && rm -rf /var/lib/apt/lists/*

# 从本地复制项目文件到容器工作目录
COPY . .

# 安装项目依赖并构建
RUN npm install
RUN npm run dist

EXPOSE 8000

CMD ["node", "dist/index.js"]
    