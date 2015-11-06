# Source the variables we need from env.sh
source env.sh

# calling this script twice will cause a collision
# so lets use a lock
if [ -f "./switch.lock" ]; then
	echo "Collision detected exiting"
	exit 1
fi
# Nobody is calling this script so lets lock now
touch ./switch.lock

# At this point we can set a trap
# and make sure the lock gets removed once the script is done no matter what
function removepid {
	rm ./switch.lock
}
trap removepid EXIT

# Lets set some vars to detect what is going on at this point
# is there a blue instance? a green? is the proxy setup yet?
DPS=`docker ps`
B=`echo $DPS | grep "blue-instance"`
G=`echo $DPS | grep "green-instance"`
NP=`echo $DPS | grep "nginx-proxy-instance"`

# Get the latest image before we do the switch
PULL=`docker pull $IMAGE`
IS_NEW=`echo $PULL | grep "Downloaded newer image for"`

# Output a warning just in case
# you could exit at this point or sleep and call this script again
if [ -z "$IS_NEW" ]; then
	echo "Warning this is not a new image"
fi

# Start the proxy server, this server will make sure any requests to
# domain name get directed to the right place
if [ -z "$NP" ]; then
	echo "starting proxy server"
	docker run -d -p 80:80 --name nginx-proxy-instance -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
fi


# if both are started lets remove the green
# TODO could figure out which is the newest some how
if [ ! -z "$B" ] && [ ! -z "$G" ]; then
	docker rm -f green-instance
fi

# if neither have instances just start b
if [ -z "$B" ] && [ -z "$G" ]; then
	echo "Neither have instances starting the service for the first time"
	echo docker run -d -e VIRTUAL_HOST=$VIRTUAL_HOST --expose=$EXPOSE $OPTS $BLUEOPTS --name blue-instance $IMAGE
	docker run -d -e VIRTUAL_HOST=$VIRTUAL_HOST --expose=$EXPOSE $OPTS $BLUEOPTS --name blue-instance $IMAGE
# if there are no instances of blue start a blue, set green to delete
elif [ -z "$B" ]; then
	echo "Starting B"
	DELETE="green-instance"
	echo docker run -d -e VIRTUAL_HOST=$VIRTUAL_HOST --expose=$EXPOSE $OPTS $BLUEOPTS --name blue-instance $IMAGE
	docker run -d -e VIRTUAL_HOST=$VIRTUAL_HOST --expose=$EXPOSE $OPTS $BLUEOPTS --name blue-instance $IMAGE
# start a green if there are none, set blue to delete
elif [ -z "$G" ]; then
	DELETE="blue-instance"
	echo "Starting G"
	echo docker run -d -e VIRTUAL_HOST=$VIRTUAL_HOST --expose=$EXPOSE $OPTS $GREENOPTS --name green-instance $IMAGE
	docker run -d -e VIRTUAL_HOST=$VIRTUAL_HOST --expose=$EXPOSE $OPTS $GREENOPTS --name green-instance $IMAGE
fi

# How long do we want to wait for the new instance to come up?
sleep $SLEEPTIME

# Now get rid of the other instance
if [ ! -z "$DELETE" ]; then
	echo "Removing $DELETE"
	docker rm -f $DELETE
fi