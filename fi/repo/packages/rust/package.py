from spack import *
import spack.pkg.builtin.rust as builtin


class Rust(builtin.Rust):

    def setup_build_environment(self, env):
        super().setup_build_environment(env)
        env.set("CARGO_HTTP_CAINFO", "/etc/ssl/certs/ca-certificates.crt")
        env.set('CARGO_HOME', join_path(self.stage.path, 'cargo_home_spack'))
        # workaround for https://github.com/rust-lang/cargo/issues/10303
        env.set("CARGO_NET_GIT_FETCH_WITH_CLI", "true")

    def setup_dependent_build_environment(self, env, dependent_spec):
        super().setup_dependent_build_environment(env, dependent_spec)
        env.set("CARGO_HTTP_CAINFO", "/etc/ssl/certs/ca-certificates.crt")
        env.set('CARGO_HOME', join_path(dependent_spec.package.stage.path, 'cargo_home_spack'))
        env.set("CARGO_NET_GIT_FETCH_WITH_CLI", "true")
