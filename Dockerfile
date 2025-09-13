# ---------- build stage ----------
FROM node:18 AS builder
ENV LANG=C.UTF-8
WORKDIR /ws-scrcpy

# 先只拷贝依赖清单，利用缓存
COPY package*.json ./

# 构建期准备：node-gyp 及编译工具（原生模块所需）
RUN npm install -g node-gyp \
  && apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

# 有 lock 用 ci，没有就用 install，避免直接失败
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# 拷贝源码并构建
COPY . .
# 如果项目是用 npm start 直接跑生产，可跳过这步
# 没有 dist 的话把下面两行按需改成 build/或去掉
RUN npm run dist

# 只保留生产依赖，减少体积
RUN npm prune --omit=dev \
  && npm cache clean --force

# ---------- runtime stage ----------
FROM node:18-slim
ENV LANG=C.UTF-8
WORKDIR /ws-scrcpy

# 运行时需要 adb
RUN apt-get update \
  && apt-get install -y --no-install-recommends android-tools-adb \
  && rm -rf /var/lib/apt/lists/*

# 直接复用已经裁剪好的 node_modules，运行阶段不再联网装包
COPY --from=builder /ws-scrcpy/package*.json ./
COPY --from=builder /ws-scrcpy/node_modules ./node_modules
# 如果有 dist，就拷贝 dist；若用 npm start 直跑源码，可改为 COPY 源码
COPY --from=builder /ws-scrcpy/dist ./dist

EXPOSE 8000
# 若你的生产启动是 npm start，则改成：CMD ["npm","start"]
CMD ["node", "dist/index.js"]
