# Copyright 2020 Alex Woroschilow <alex.woroschilow@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2,
# or (at your option) any later version, as published by the Free
# Software Foundation
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
PWD:=$(shell pwd)
CONTAINER:=centos8
# If the first argument is "run"...
ifeq (docker_run,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):;@:)
endif

all: clean
	mkdir --parents $(PWD)/build
	rpmbuild -bb $(PWD)/project.spec \
		--build-in-place \
		--buildroot=$(PWD)/build \
		--define "_rpmdir $(PWD)"

docker_init:
	docker build -t $(CONTAINER) $(PWD)

docker_build: clean
	mkdir --parents $(PWD)/build
	docker run --volume $(PWD):$(PWD) --rm -ti $(CONTAINER) /bin/bash -c \
		"cd $(PWD) && rpmbuild -bb $(PWD)/project.spec \
						--build-in-place \
						--buildroot=$(PWD)/build \
						--define \"_rpmdir $(PWD)\""

# With this command you can easily switch to the 
# container shell in the current terminal
docker_shell:
	docker run --volume $(PWD):$(PWD) --rm -ti $(CONTAINER)

# With this command you can run any command
# in the container and get the response in 
# the current terminal session
docker_run:
	@docker run --volume $(PWD):$(PWD) --rm -ti $(CONTAINER) /bin/bash -c \
			"cd $(PWD) && $(RUN_ARGS)"

clean:	
	rm -rf $(PWD)/build
