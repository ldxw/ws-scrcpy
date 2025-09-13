FROM node:18

ENV LANG C.UTF-8
WORKDIR /ws-scrcpy

RUN npm install -g node-gyp
RUN apt update;apt install android-tools-adb -y

COPY . .

RUN npm install
RUN npm run dist

EXPOSE 8000

CMD ["node","dist/index.js"]