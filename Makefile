all:
	@eval $(opam env)
	@dune build
	@cp _build/default/src/main_server.exe scrabblos-server
	@cp _build/default/src/printing_proxy.exe scrabblos-proxy
	@cp _build/default/src/client.exe scrabblos-client

clean:
	@dune clean
	@rm -f scrabblos-server scrabblos-proxy scrabblos-client

install: all
	@dune install

uninstall:
	@dune uninstall
