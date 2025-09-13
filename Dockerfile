# ---------- build stage ----------
FROM node:18 AS builder
ENV LANG=C.UTF-8
WORKDIR /ws-scrcpy

# 利用缓存：先只拷贝依赖清单
COPY package*.json ./
# 如有 node-gyp 需求，装下编译工具
RUN npm install -g node-gyp \
  && apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

# 安装依赖（有 lock 用 ci，没有就用 install）
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# 再拷贝源码并构建
COPY . .
# 根据你的项目脚本择一：
# RUN npm run build
RUN npm run dist

# ---------- runtime stage ----------
FROM node:18-slim
ENV LANG=C.UTF-8
WORKDIR /ws-scrcpy

# 运行时需要 adb
RUN apt-get update \
  && apt-get install -y --no-install-recommends android-tools-adb \
  && rm -rf /var/lib/apt/lists/*

# 仅拷贝运行需要的文件
COPY --from=builder /ws-scrcpy/package*.json ./
RUN npm ci --omit=dev || npm install --omit=dev
COPY --from=builder /ws-scrcpy/dist ./dist

EXPOSE 8000
CMD ["node", "dist/index.js"]
