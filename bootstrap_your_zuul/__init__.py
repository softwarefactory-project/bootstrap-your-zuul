# Copyright (c) 2021 Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import argparse
import subprocess
from pathlib import Path
from typing import Any, List, Tuple
import yaml
import zuulfmt  # type: ignore
import json


# TODO: use a released version here
byz = "~/src/softwarefactory-project.io/software-factory/bootstrap-your-zuul/package.dhall"


class IndentedListDumper(yaml.Dumper):
    def increase_indent(self, flow=False, indentless=False):  # type: ignore
        return super(IndentedListDumper, self).increase_indent(flow, False)  # type: ignore


def pread(argv: List[str], stdin: str) -> str:
    proc = subprocess.Popen(argv, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
    stdout, _ = proc.communicate(stdin.encode("utf-8"))
    if proc.wait():
        raise RuntimeError("%s: failed" % " ".join(argv))
    return stdout.decode("utf-8")


def json_to_dhall(type_: str, obj: Any) -> str:
    return pread(["json-to-dhall", type_], json.dumps(obj))


def dhall_to_json(expression: str) -> Any:
    return yaml.safe_load(pread(["dhall-to-yaml"], expression))


def yaml_dump(obj: Any) -> str:
    return yaml.dump(obj, Dumper=IndentedListDumper, default_flow_style=False)  # type: ignore


def write(filepath: Path, content: str) -> None:
    previous = filepath.read_text() if filepath.exists() else ""
    if previous != content:
        filepath.parent.mkdir(parents=True, exist_ok=True)
        filepath.write_text(content)
        print("* " + str(filepath) + ": updated!")


def render(config_file: Path) -> List[Tuple[Path, str]]:
    if config_file.suffix == ".dhall":
        dhall_config = str(config_file.resolve())
    else:
        dhall_config = "(BYZ.JsonConfig.toConfig %s)" % json_to_dhall(
            "(%s).JsonConfig.Type" % byz, yaml.safe_load(config_file.read_text())
        )
    config = dhall_to_json("let BYZ = %s in BYZ.render %s" % (byz, dhall_config))
    return list(
        map(
            lambda file_path_content: (
                Path(file_path_content[0]),
                zuulfmt.fmt("\n" + yaml_dump(config[file_path_content[1]])),
            ),
            [
                ("/etc/zuul/main.yaml", "tenant"),
                ("zuul.d/pipelines.yaml", "pipelines"),
                ("zuul.d/jobs.yaml", "jobs"),
                ("playbooks/base/pre.yaml", "playbook_pre"),
                ("playbooks/base/post.yaml", "playbook_post"),
            ],
        )
    )


def usage() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Zuul configuration generator")
    parser.add_argument("config", help="Tenant BYZ configuration file")
    parser.add_argument("--write", metavar="DIR", help="Write configuration")
    return parser.parse_args()


def main() -> None:
    args = usage()
    for k, v in render(Path(args.config)):
        if args.write and not k.is_absolute():
            write(args.write / k, v)
        else:
            print("* " + str(k))
            print(v.strip())
            print()


if __name__ == "__main__":
    main()
