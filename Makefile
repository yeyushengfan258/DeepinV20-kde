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

all: clean
	mkdir --parents $(PWD)/build
	rpmbuild --quiet -bb $(PWD)/project.spec --build-in-place --buildroot=$(PWD)/build --define \"_rpmdir $(PWD)\"

docker_init:
	docker build -t $(CONTAINER) $(PWD)

docker_build: clean
	mkdir --parents $(PWD)/build
	docker run --volume `pwd`:$(PWD) --rm -ti $(CONTAINER) /bin/bash -c \
		"cd $(PWD) && rpmbuild --quiet -bb $(shell pwd)/project.spec --build-in-place --buildroot=$(shell pwd)/build --define \"_rpmdir $(shell pwd)\""

docker_shell:
	docker run --volume `pwd`:$(PWD) --rm -ti $(CONTAINER)

docker_run:
	echo "$(RUN_ARGS)"
	docker run --volume `pwd`:$(PWD) --rm -ti $(CONTAINER) /bin/bash -c $(RUN_ARGS)

clean:	
	rm -rf $(PWD)/build
