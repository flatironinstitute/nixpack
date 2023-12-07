packs:

let docker = derivation rec {
  inherit (packs) system;
  pname = "docker";
  version = "24.0.7";
  name = "${pname}-${version}";
  docker = builtins.fetchurl {
    url = "https://download.docker.com/linux/static/stable/${packs.target}/${name}.tgz";
    sha256 = "0gdxg5iirzlpafbywbwww3h2adykmiprcnkjxabspb56gykmjkcq";
  };
  rootless = builtins.fetchurl {
    url = "https://download.docker.com/linux/static/stable/${packs.target}/docker-rootless-extras-${version}.tgz";
    sha256 = "1wz6waxkh84jsi5acxw1c0gvi4dnsqixnahnbcz68ixcdllrw3jr";
  };
  # needed for https://github.com/rootless-containers/rootlesskit/pull/369
  rootlesskit = builtins.fetchurl {
    url = "https://github.com/rootless-containers/rootlesskit/releases/download/v1.1.1/rootlesskit-${packs.target}.tar.gz";
    sha256 = "13wyshzlw3dd2800629qkshwykcvmxi49qp268nzxjh5nkxsz0rw";
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
