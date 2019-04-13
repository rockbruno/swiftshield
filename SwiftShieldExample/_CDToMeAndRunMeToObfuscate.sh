pod install
echo "Running sudo chmod to make the pods folder writable"
sudo chmod -R 774 ./Pods
../bin/swiftshield -project-root ./ -automatic -automatic-project-file ./SwiftShieldExample.xcworkspace -automatic-project-scheme SwiftShieldExample -verbose