.PHONY : all start-server start-client

all: etp/etp etp/apps.txt etp/menger etp/julia

start-server: all
	@./start-server

start-client:
	@./start-client

etp/etp: etp/target/release/etp
	ln -sf ../$< ./$@

etp/target/release/etp: etp/src/main.rs
	cd etp; cargo build --release

etp/src/main.rs:
	git submodule init
	git submodule update

etp/apps.txt: etp/src/main.rs
	rm -f etp/apps.txt
	echo "menger" >> $@
	echo "julia" >> $@

etp/menger: menger/target/release/menger
	ln -sf ../$< ./$@

etp/julia: julia/target/release/julia
	ln -sf ../$< ./$@

menger/target/release/menger: menger/src/main.rs srray/src/lib.rs
	cd menger; cargo build --release

srray/src/lib.rs:
	git submodule init
	git submodule update

julia/target/release/julia: julia/src/main.rs
	cd julia; cargo build --release
