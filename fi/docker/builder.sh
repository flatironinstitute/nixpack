#!/bin/bash -e

mkdir -p $out/bin
tar -xzf $docker -C $out/bin --strip-components=1
tar -xzf $rootless -C $out/bin --strip-components=1
tar -xzf $rootlesskit -C $out/bin

rm -f $out/bin/docker-rootless-setuptool.sh

mkdir -p $out/config/systemd/user
cat <<- EOT > $out/config/systemd/user/docker.service
	[Unit]
	Description=Docker Application Container Engine (Rootless)
	Documentation=https://docs.docker.com/go/rootless/

	[Service]
	Environment=PATH=$out/bin:/sbin:/usr/sbin:/bin:/usr/bin
	ExecStart=$out/bin/dockerd-rootless.sh --data-root /home/\${USER}/.local/share/docker
	ExecReload=/bin/kill -s HUP \$MAINPID
	TimeoutSec=0
	RestartSec=10
	Restart=always
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

	[Install]
	WantedBy=default.target
EOT
