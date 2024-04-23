.PHONY : start-server start-client
start-server: etp etp/apps.txt etp/menger etp/julia
	@cd etp; cargo run --release

start-client:
	@cd supancc; racket main.rkt

etp:
	git submodule init
	git submodule update

etp/apps.txt:
	rm -f etp/apps.txt
	echo "menger" >> $@
	echo "julia" >> $@

etp/menger: menger/target/release/menger
	ln -sf ../$< ./$@

etp/julia: julia/target/release/julia
	ln -sf ../$< ./$@

menger/target/release/menger: menger/src/main.rs srray
	cd menger; cargo build --release

srray:
	git submodule init
	git submodule update

julia/target/release/julia: julia/src/main.rs
	cd julia; cargo build --release
