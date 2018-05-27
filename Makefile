all: fix_grpc_python_import gen_keys_to_client

fix_grpc_python_import: to_servicers to_gondor
	cd py_protos/ && sed -i '' 's/^\(import.*pb2\)/from . \1/g' *.py
	cd user_account/protos/ && sed -i '' 's/^\(import.*pb2\)/from . \1/g' *.py
	cd imladris/protos/ && sed -i '' 's/^\(import.*pb2\)/from . \1/g' *.py
	cd valinor/protos/ && sed -i '' 's/^\(import.*pb2\)/from . \1/g' *.py

to_servicers: protos/shadowfax.proto protos/user_account.proto protos/imladris.proto protos/valinor.proto
	python -m grpc_tools.protoc -Iprotos --python_out=user_account/protos --grpc_python_out=user_account/protos protos/user_account.proto
	python -m grpc_tools.protoc -Iprotos --python_out=imladris/protos --grpc_python_out=imladris/protos protos/imladris.proto
	python -m grpc_tools.protoc -Iprotos --python_out=valinor/protos --grpc_python_out=valinor/protos protos/valinor.proto
	python -m grpc_tools.protoc -Iprotos --python_out=py_protos --grpc_python_out=py_protos protos/shadowfax.proto

to_gondor: protos/shadowfax.proto protos/user_account.proto protos/imladris.proto protos/valinor.proto
	python -m grpc_tools.protoc -Iprotos --python_out=py_protos --grpc_python_out=py_protos protos/user_account.proto
	python -m grpc_tools.protoc -Iprotos --python_out=py_protos --grpc_python_out=py_protos protos/imladris.proto
	python -m grpc_tools.protoc -Iprotos --python_out=py_protos --grpc_python_out=py_protos protos/valinor.proto
	protoc -Iprotos --swift_out=Shadowfax/Shadowfax/Shadowfax/src/protos --swiftgrpc_out=Client=true,Server=false:Shadowfax/Shadowfax/Shadowfax/src/protos protos/shadowfax.proto

update_config: basicconfig.py
	cp basicconfig.py imladris/basicconfig.py
	cp basicconfig.py user_account/basicconfig.py
	cp basicconfig.py valinor/basicconfig.py

gen_key:
	openssl req -newkey rsa:2048 -nodes -keyout keys/gondor.key -x509 -days 365 -out keys/gondor.crt -subj "/C=CN/ST=GD/L=SZ/O=SDMC/OU=SystemDepartment/CN=api.superyoung.win"
	openssl req -newkey rsa:2048 -nodes -keyout keys/imladris.key -x509 -days 365 -out keys/imladris.crt -subj "/C=CN/ST=GD/L=SZ/O=SDMC/OU=SystemDepartment/CN=api.superyoung.win"
	openssl req -newkey rsa:2048 -nodes -keyout keys/user_account.key -x509 -days 365 -out keys/user_account.crt -subj "/C=CN/ST=GD/L=SZ/O=SDMC/OU=SystemDepartment/CN=api.superyoung.win"
	openssl req -newkey rsa:2048 -nodes -keyout keys/valinor.key -x509 -days 365 -out keys/valinor.crt -subj "/C=CN/ST=GD/L=SZ/O=SDMC/OU=SystemDepartment/CN=api.superyoung.win"

gen_keys_to_client: gen_key
	cp ./keys/*.crt Shadowfax/Shadowfax/crts/

reconstruct: clean
	touch imladris/protos/__init__.py user_account/protos/__init__.py valinor/protos/__init__.py

clean:
	rm -rf py_protos/* imladris/protos/* user_account/protos/* valinor/protos/*
