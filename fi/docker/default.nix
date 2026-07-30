packs:

let docker = derivation rec {
  __noChroot = true;
  inherit (packs) system;
  pname = "docker";
  version = "29.6.2";
  buildkit = "0.36.0";
  name = "${pname}-${version}";
  docker = builtins.fetchurl {
    url = "https://download.docker.com/linux/static/stable/${packs.target}/${name}.tgz";
    sha256 = "0x5clc9bx7fz1v2qwmhm57wbhpifkmdqhp24sm9j93i3jbm4l86n";
  };
  rootless = builtins.fetchurl {
    url = "https://download.docker.com/linux/static/stable/${packs.target}/docker-rootless-extras-${version}.tgz";
    sha256 = "1naw78d0k0zrakqwglk6vhrvgllkckwihf2zx58w4wyq2pr67j3j";
  };
  buildx = builtins.fetchurl {
    url = "https://github.com/docker/buildx/releases/download/v${buildkit}/buildx-v${buildkit}.linux-amd64";
    sha256 = "07823fdfcd82a41be90155a8b16876c1a780a6462de805a9f3f63b3119ccfb99";
  };
  PATH = "/bin:/usr/bin";
  setupsh = ./setup.sh;
  builder = ./builder.sh;
}; in

docker // {
  module = with docker; {
    name = pname;
    version = version;
    prefix = docker;
    context = {
      short_description = "user rootless docker (for workstations)";
      long_description = "Use this module to run docker on your own workstation.";
    };
    postscript = ''
      local xdg_runtime_dir = os.getenv("XDG_RUNTIME_DIR")
      if (mode() == "load") then
        local user = os.getenv("USER")
        local subid = capture("/bin/getsubids " .. user);
        if not (subid:match(user) and isDir(pathJoin("/home", user)) and isDir(xdg_runtime_dir)) then
          LmodBreak("The docker module can be used to run a rootless docker daemon on your own workstation.  If you have a workstation and you'd like to use docker, please try loading it there.  For more details, see: https://wiki.flatironinstitute.org/SCC/Software/DockerSingularity")
        end
      end

      execute {cmd="${docker}/bin/dockerd-rootless-setup.sh && /bin/systemctl --user start docker", modeA={"load"}}
      execute {cmd="/bin/systemctl --user stop docker", modeA={"unload"}}
      setenv("DOCKER_HOST", "unix://" .. pathJoin(xdg_runtime_dir, "docker.sock"))
    '';
  };
}
