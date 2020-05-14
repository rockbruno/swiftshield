.PHONY : swiftshield

swiftshield:
	cd ../ && make build
	../.build/release/swiftshield obfuscate -p ./ExampleProject.xcodeproj -s ExampleProject
	open ./ExampleProject.xcodeproj
	open ./swiftshield-output