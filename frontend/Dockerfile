FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .

# Set build-time environment variables for Vite
ARG VITE_API_URL=http://192.168.1.24:5000/api
ARG VITE_ORTHANC_URL=http://192.168.1.24:8042
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_ORTHANC_URL=$VITE_ORTHANC_URL

RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
