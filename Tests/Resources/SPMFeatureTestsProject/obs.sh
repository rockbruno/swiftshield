#!/bin/sh

# To exit the script as soon as one of the commands failed
set -e

./swiftshield obfuscate \
    --project-file SPMFeatureTestsProject.xcodeproj \
    --scheme "SPMFeatureTestsProject"

#set -o pipefail && xcodebuild clean build -scheme "SPMFeatureTestsProject" -project ./SPMFeatureTestsProject.xcodeproj -destination "platform=iOS Simulator,name=iPhone 13 Pro,OS=latest" | xcbeautify
