# simple-docker-blue-green

This is intended to be used with docker hub to enable very simple blue green switching redeploys, filling in the last part of the pipeline for [github commit] -> [docker hub build] -> [service redeploy]. While both blue and green are running the nginx proxy will load balance between them. nginx-proxy is used for picking up events from the docker daemon and using those events to determine which containers should be added to the nginx config https://github.com/jwilder/nginx-proxy

# Setup

you need to edit /etc/hosts to include your domain name you wish to use, if you use docker-machine then find the ip
```
$ docker-machine ip MACHINE_NAME
192.168.99.100 # it should return something like this
```

Then add it to etc hosts
```
sudo echo 192.168.99.100 local.dev >> /etc/hosts
```

clone and cd into the project
```
git clone https://github.com/jjn2009/simple-docker-blue-green.git
cd simple-docker-blue-green
```

Copy the example example.env.sh to env.sh
```
cp example.env.sh env.sh
```


If you want to test this run watch in one terminal, this will request to switch from blue to green as much as possible, for me it runs about every 4 seconds (it tries to pull the latest which there is none), watch is synchronous but locking is also implemented to prevent two redeploys at once, which would cause a collision
```
# "brew install watch" if you do not have watch installed on OSX
watch -n0 sh switch.sh
```

Open another and run a stress test against the url you have chosen.
```
ab -n 10000 -c 30 http://local.dev/
```

as you can see here it has not dropped any requests for myself
```
$ ab -n 10000 -c 30 http://local.dev/
This is ApacheBench, Version 2.3 <$Revision: 1663405 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking local.dev (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:        nginx/1.9.6
Server Hostname:        local.dev
Server Port:            80

Document Path:          /
Document Length:        5 bytes

Concurrency Level:      30
Time taken for tests:   15.649 seconds
Complete requests:      10000
Failed requests:        0                # yay
Total transferred:      2330000 bytes
HTML transferred:       50000 bytes
Requests per second:    639.00 [#/sec] (mean)
Time per request:       46.948 [ms] (mean)
Time per request:       1.565 [ms] (mean, across all concurrent requests)
Transfer rate:          145.40 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.1      0       2
Processing:     1   47   9.0     45     156
Waiting:        1   46   8.9     44     155
Total:          1   47   9.0     45     156

Percentage of the requests served within a certain time (ms)
  50%     45
  66%     46
  75%     46
  80%     47
  90%     55
  95%     65
  98%     73
  99%     81
 100%    156 (longest request)
 ```


if you want to do something more complex open env.sh to use your own settings
```
# The image we are load balancing with blue green
export IMAGE=nginx

# If you are doing this locally you need to 
# set FQDN (domain name) in /etc/hosts
export VIRTUAL_HOST=local.dev

# The port you want to proxy to
export EXPOSE=80

# if you want some OPTS for all instances here is where they go
export OPTS=""

# This only happens for blue instances
export BLUEOPTS="-v `pwd`/blue:/usr/share/nginx/html"

# Only for green conversely
export GREENOPTS="-v `pwd`/green:/usr/share/nginx/html"

# How long you want to wait for your service to come up
# before deleting the other instance
export SLEEPTIME=1
```

# TODO
- Add http service to consume the webhook from docker hub
- Allow arbitrary numbers of instances for blue and green
- Make this an actual robust project in something other than bash
- Try with multiple nodes using swarm (should work fine as is... maybe)
- revert back if upgrade failed



