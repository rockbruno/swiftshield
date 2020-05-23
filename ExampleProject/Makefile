.PHONY : swiftshield

swiftshield:
	cd ../ && make build && make package
	../.build/release/_PRODUCT/bin/swiftshield obfuscate -p ./ExampleProject.xcodeproj -s ExampleProject -v
	open ./ExampleProject.xcodeproj
	open ./swiftshield-output