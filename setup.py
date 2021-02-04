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

from setuptools import setup

setup(
    name="bootstrap_your_zuul",
    version="0.1.0",
    packages=["bootstrap_your_zuul"],
    description="A Zuul configuration generator.",
    license="ASL v2.0",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    install_requires=["zuulfmt", "pyyaml"],
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: Information Technology",
        "License :: OSI Approved :: Apache Software License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3.6",
    ],
    entry_points={"console_scripts": ["bootstrap-your-zuul=bootstrap_your_zuul:main"]},
)
