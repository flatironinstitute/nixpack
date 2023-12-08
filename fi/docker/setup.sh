#!/bin/sh

if [[ ! -x $DOCKER_ROOT/bin/dockerd-rootless.sh || ! -d /home/$USER ]] || ! /bin/getsubids $USER >& /dev/null ; then
	echo "Please make sure the docker module is loaded and you are on your own workstation."
	exit 1
fi

cfg=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
mkdir -p $cfg
rm -f $cfg/docker.service
cat <<- EOT > $cfg/docker.service
	[Unit]
	Description=Docker Application Container Engine (Rootless)
	Documentation=https://docs.docker.com/go/rootless/
	RequiresMountsFor=/home/$USER
	ConditionHost=`hostname`
	ConditionUser=$USER

	[Service]
	Environment=PATH=$DOCKER_ROOT/bin:/sbin:/usr/sbin:/bin:/usr/bin
	ExecStart=$DOCKER_ROOT/bin/dockerd-rootless.sh --data-root /home/$USER/.local/share/docker
	ExecReload=/bin/kill -s HUP \$MAINPID
	TimeoutSec=10
	Restart=no
	StartLimitBurst=3
	StartLimitInterval=60s
	LimitNOFILE=infinity
	LimitNPROC=infinity
	LimitCORE=infinity
	TasksMax=infinity
	Delegate=yes
	Type=notify
	NotifyAccess=all
	KillMode=mixed
EOT
systemctl --user daemon-reload
