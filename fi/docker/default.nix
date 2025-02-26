packs:

let docker = derivation rec {
  inherit (packs) system;
  pname = "docker";
  version = "28.0.1";
  name = "${pname}-${version}";
  docker = builtins.fetchurl {
    url = "https://download.docker.com/linux/static/stable/${packs.target}/${name}.tgz";
    sha256 = "0ij7ha9b596lq7pvcxd5r345nm76dlgdim5w1nn9w6bqbmmximjy";
  };
  rootless = builtins.fetchurl {
    url = "https://download.docker.com/linux/static/stable/${packs.target}/docker-rootless-extras-${version}.tgz";
    sha256 = "1fsx7w5b91r23pad3hpwyvcljc62hw60b42nqqpp463ggvfzykil";
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
