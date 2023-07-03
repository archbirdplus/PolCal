
clean:
	rm -r ./.build/debug/PolCalPackageTests.xctest

./.build/debug/PolCalPackageTests.xctest:
	echo "rebuilding .xctest file"
	swift test --filter "$a"

test:
	@swift test | sed -E " \
		s/0 failures/[34m0 failures[39m[49m/g; \
		s/(\d\d+|[1-9]) failures?/[31m\1 FAILURE[39m[49m/g; \
		s/passed/[32mpassed[39m[49m/g; \
		s/error/[31merror[39m[49m/g"

debug-test: ./.build/debug/PolCalPackageTests.xctest
	lldb /Applications/Xcode.app/Contents/Developer/usr/bin/xctest ./.build/debug/PolCalPackageTests.xctest

fresh: clean test

