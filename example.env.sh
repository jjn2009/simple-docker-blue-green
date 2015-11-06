
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