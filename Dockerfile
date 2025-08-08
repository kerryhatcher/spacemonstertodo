# Simple Dockerfile for serving the full Space Monster Todo app
FROM nginx:alpine

# Copy the complete single-file application
COPY public/index.html /usr/share/nginx/html/index.html

# Configure nginx to serve on port 80
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]