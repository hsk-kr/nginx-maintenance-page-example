For the past year, there has been lots of news hitting our industry. AI is at the center. Besides all the topics, I also started to work on my side project, which I would’ve never tried before. After work, we only have a few hours. If you have a strong willingness to do something, you can do whatever you want. But for me, I want to rest, I want to look around, I want to kill my time by doing unproductive things while trying to do something productive. Out of that, I have a couple of hours a day, and AI enables me to make some meaningful progress towards my goal. This post is not about that, but I just wanted to mention it.

I will launch my service, and it will be a B2C service. I’ve never created a service that directly faces users. As I have been working as a software developer, I have learned how to read code, write code, and use code that’s already there. However, I’ve never created a service from scratch to a ready-to-launch level.

I built my own server, set up a deployment process, and handled DB migration. But I still have one concern – what should I do when an emergency situation happens? Users will pay for my service, and I have to be responsible. There will be moments when I have to stop the service for a bit, or during the build-deploy process, to deploy safely, I may need to pause the service for a minute.

For that, I thought it would be good to show a page that lets users know the service is under update or maintenance. It should be achievable as soon as possible.

To be honest, I got help from AI. This method is very useful, and I felt like sharing it.

---

The example includes:

- Web Service: I made it using Nginx and its development server. But it could be any web service depending on your purpose.

- Nginx: Nginx will control the flow.

- Docker: I deployed the service using docker-compose. In my web service, I used docker-swarm, but anyway, this can be used in any type of service.

---

## Web Service

`pnpm create next-app maintenance`

I didn’t edit the website. I just needed a web service to show this example.

---

## Nginx

![file explorer](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/vcfvywpx85qhzr1wjlb7.png)

I created a `data` folder in the root. Inside the `data` folder, there’s an `nginx` folder, and it has two files: `maintenance.html`, which will be shown to users in maintenance mode, and `nginx.conf` to configure nginx.

### maintenance.html

```html
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="utf-8">
  <title>We will be back soon!</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>

<body>
  <h1>Sorry!</h1>
  <p>We are updating our web server to provide a better and more convenient service. Please wait a moment. The service
    will be back shortly.</p>
</body>

</html>
```

You can add more content depending on your purpose. I created a simple one.

### nginx.conf

```
server {
    listen 3000;

    error_page 503 /maintenance.html;         # where to send 503s
    location = /maintenance.html {            # serve the static page
        root /nginx-data;
        internal;                             # prevent direct linking when not in maintenance
    }
    
    location / {
        if (-f /nginx-data/maintenance.flag) {
            return 503;                           # send 503 Service Unavailable
        }

        proxy_pass http://frontend:3000;
    }
}
```

The default port for the Next development server is `3000`. I proxied port `30000` to `3000`. frontend is the name of the container in the docker-compose file, which I’ll mention later.

When a 503 error happens, it will redirect to the `/maintenance.html` path.

Below that, there is a definition for the `/maintenance.html` root.

`root /nginx-data` means the file will be read from this root path. Using internal, this page can’t be accessed directly. This page should only be shown on our intention.

In the location / block, it proxies requests to `http://frontend:3000`.

But if there is a file `/nginx-data/maintenance.flag`, it will return 503, which shows our maintenance page.
---

## Docker

```
FROM node:23-alpine

RUN npm install -g pnpm

WORKDIR /app

COPY . .

RUN pnpm install

CMD ["pnpm", "run", "dev"]
```

This is for the Next.js service. It’s very simple. It installs the dependencies needed to run the Next.js app and starts the development server.

```
services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile
    networks:
      - custom 

  nginx:
    # Build the custom Nginx+Certbot image
    image: nginx:latest
    restart: always
    ports:
      - '30000:3000'
    volumes:
      - ./data/nginx:/nginx-data
      - ./data/nginx/nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - frontend 
    networks:
      - custom 

networks:
  custom:
    driver: bridge
```

Here, what we need to look closely at is the nginx container. It uses the latest nginx image. Since my port `3000` is already used, I used `30000`. Port `30000` will connect to port `3000` inside the container.

In our `nginx` folder, there is a `nginx.conf` file. This file will be copied to `/etc/nginx/conf.d/default.conf` inside the container.

If you wondered what the `nginx-data` folder was, it’s our nginx folder. It’s mounted in the `/nginx-data` folder inside the container.

---

## Result

![docker compose up](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/5apnc6eiekfsaw0wjazq.png)

Let’s run docker compose with `docker compose up`.

![website](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/gilopz9oplikxievc9l6.png)

Go to `localhost:30000` to see if the app runs properly.

![script](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/015685435obosg9285nv.png) 


Here are two shell script files to create or delete the maintenance.flag file. If nginx detects the file, it will redirect requests to our maintenance page.

The `maintenance-on` file creates the `maintenance.flag` file.
The `maintenance-off` file removes the `maintenance.flag` file.

![maintenance-on](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/cq0hfz47wcgpwpzf1569.png)

![maintenance page](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ba78zp343olho56usw93.png)

Now, if you go to `localhost:30000` you will see this maintenance page.

![maintenance-off](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/bnazg8ruccfozjk4v3sf.png)

![website back](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/iyufv1xztl61cp48m338.png)

If you run `maintenance-off`, you will see the website back to our Next.js app.

---

## Conclusion

This example handles a very basic case. You can run this command from your remote machine. In my case, I turn it on between deploy and before the web service is stable. I also created GitHub Actions so I can turn maintenance mode on and off with one click.

I hope you find it helpful.

You can check the full code here:

https://github.com/hsk-kr/nginx-maintenance-page-example

---

PS.

I’ve been actively using AI on my side project. It’s very helpful, and I’m happy that I finally got to work on my project, which I couldn’t even start before.

Since January 2022, I’ve been writing at least one post a month. A few days ago, I didn’t know what to write. I felt like AI does much better than I do. I tried to write posts that are hard to find online, but now, we can simply ask AI anything.

But then, a couple of days ago, I had some issues in my project because I applied code that AI generated without understanding it. I tried to find posts that can help with it, but it wasn’t easy. After some research, I found one post and I managed to make it work – even better, I was able to make it more efficient.

AI does a better job than I do, but asking AI what to do is still up to me. We can get knowledge from AI, but if we don’t know what to ask, it’s hard. Searching for things and reading posts we didn’t expect can teach us something new. Finding exactly what we need is important, but I believe in random opportunities to learn unexpected things – this expands our knowledge. I almost thought about stopping writing posts, but I’ll probably keep going for a while.

Now, I can write posts quickly using AI, and it enabled me to do something I couldn’t do this quickly before. I really appreciate it.

Writing half about the post and half about mumbling – sorry about that.

Hope you have a nice day!

Happy Coding!
