.DEFAULT_GOAL := build

setup:
	sudo modprobe loop; \
	sudo modprobe binfmt_misc

build: setup
	@set -e;	\
	for file in `ls ./scripts/[0-99]*.sh`;	\
	do					\
		bash $${file};			\
	done					\

flash:
	$(CURDIR)/scripts/flash.sh

clean:
	sudo rm -rf $(CURDIR)/tempdir; \
	docker ps -a | awk '{ print $$1,$$2 }' | grep jetson-image:builder | awk '{print $$1 }' | xargs -I {} docker rm {};

distclean: clean
	docker rmi jetson-image:builder -f; \
	rm -rf $(CURDIR)/downloads $(CURDIR)/tempdir
