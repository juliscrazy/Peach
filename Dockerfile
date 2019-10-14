FROM python:3.7

RUN apt update

RUN apt install nodejs npm -y

RUN npm i -g yarn

WORKDIR /app

COPY . .

RUN pip3 install -r requirements.txt

RUN yarn

EXPOSE 5000

CMD [ "yarn", "dev" ]