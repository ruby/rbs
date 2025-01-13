# This script copies and signs the current `ruby` executable,
# so that it can be run in a debugger or profiler, like Xcode's
# Instruments.
#
# The output folder is configured by `destination_folder` below,
# but it's just the current dir by default.
# This script will create a new `Ruby.app` bundle in that dest.
#
# Before running this script:
#
#	1. Create a signing certificate for yourself.
#
#    Follow the instructions under the heading "To obtain a self-signed certificate using Certificate Assistant"
#    https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html
#
#	 The defaults worked for me, so I didn't need to check "Let me override defaults".
#
#    Once done, it should show up when you run `security find-identity`
#
# 2. Set `$signing_cert_name` to the name of your new certificate
#
# 3. Run `sudo DevToolsSecurity -enable` (Optional)
#    This will make it so you don't get prompted for a password every time you run a debugger/profiler.
#
# After running this script, you can either use the `dest/Ruby.app/Contents/macOS/ruby` binary from there,
# or copy it to another place of your choosing.

require "rbconfig"
require "pathname"
require "tempfile"

# Inputs
$signing_cert_name = "'Alexander Momchilov (Shopify)'"
destination_folder = Pathname.pwd

app_bundle = create_bundle_skeleton(at: destination_folder)

copy_ruby_executable(into: app_bundle)

sign_bundle(app_bundle)

if verify_entitlements(app_bundle)
	puts "Successfully created a signed Ruby at: #{app_bundle}"
	exit(true)
else
	puts "Something went wrong."
	exit(false)
end





BEGIN { # Helper methods
	def create_bundle_skeleton(at:)
		destination = at

		app_bundle = (destination / "Ruby.app").expand_path
		contents_folder = app_bundle / "Contents"

		contents_folder.mkpath

		info_plist_content = <<~INFO_PLIST
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>CFBundleInfoDictionaryVersion</key>
			<string>6.0</string>
			<key>CFBundleExecutable</key>
			<string>ruby</string>
			<key>CFBundleIdentifier</key>
			<string>com.shopify.amomchilov.Ruby</string>
			<key>CFBundleName</key>
			<string>Ruby</string>
			<key>CFBundleDisplayName</key>
			<string>Ruby</string>
			<key>CFBundleShortVersionString</key>
			<string>#{RUBY_VERSION}</string>
			<key>CFBundleVersion</key>
			<string>#{RUBY_VERSION}p#{RUBY_PATCHLEVEL}</string>
			<key>NSHumanReadableCopyright</key>
			<string>#{RUBY_COPYRIGHT.delete_prefix("ruby - ")}</string>
		</dict>
		</plist>
		INFO_PLIST

		(contents_folder / "Info.plist").write(info_plist_content)

		app_bundle
	end

	def copy_ruby_executable(into:)
		app_bundle = into
		destination = (app_bundle / "Contents/MacOS")

		begin
			destination.mkpath
		rescue Errno::EEXIST
			# Folder already exists. No problem.
		end

		original_ruby = Pathname.new(RbConfig.ruby)
		puts "Copying Ruby #{RUBY_VERSION} from #{original_ruby}"
		FileUtils.cp(original_ruby, destination)
		destination
	end

	def sign_bundle(bundle_path)
		entitlements_plist = <<~PLIST
			<?xml version="1.0" encoding="UTF-8"?>
			<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
			<plist version="1.0">
			<dict>
				<key>com.apple.security.get-task-allow</key>
				<true/>

				<!-- https://developer.apple.com/documentation/BundleResources/Entitlements/com.apple.security.cs.disable-library-validation -->
				<key>com.apple.security.cs.disable-library-validation</key>
				<true/>
			</dict>
			</plist>
		PLIST

		Tempfile.create("entitlements.plist") do |entitlements_file|
			entitlements_path = entitlements_file.path

			args = [
				"/usr/bin/codesign",
				"--force", # Replace the existing signiture, if any
				"--sign", $signing_cert_name,
				"-o", "runtime",
				"--entitlements", entitlements_file.path,
				"--timestamp\\=none",
				"--generate-entitlement-der", # necessary?
				"#{bundle_path}"
			]

			entitlements_file.puts(entitlements_plist)
			entitlements_file.flush

			puts "\nSigning #{bundle_path}."
			puts "----- codesign output:"
			system(args.join(" "), exception: true)
			puts "-----\n\n"
		end

		nil
	end

	def verify_entitlements(bundle_path)
		puts "Verifying the code signature..."
		entitlements_xml = `codesign --display --entitlements - --xml #{bundle_path} 2>/dev/null`

		disable_lib_validation = "com.apple.security.cs.disable-library-validation"
		allow_debugging = "com.apple.security.get-task-allow"

		issues = []

		# Doing dumb string matching, so we don't need to pull in an XML/Plist parser.
		if entitlements_xml.include?(disable_lib_validation)
			if entitlements_xml.include?("<key>#{disable_lib_validation}</key><true/>")
				puts "\t- ✅ Entitlement #{disable_lib_validation.inspect} was set correctly"
			else
				issues << "\t- ❌ #{disable_lib_validation.inspect} was not `true` in the bundle's entitlements."
			end
		else
			issues << "\t- ❌ #{disable_lib_validation.inspect} was missing from the bundle's entitlements."
		end

		if entitlements_xml.include?(allow_debugging)
			if entitlements_xml.include?("<key>#{allow_debugging}</key><true/>")
				puts "\t- ✅ Entitlement #{allow_debugging.inspect} was set correctly"
			else
				issues << "\t- ❌ #{allow_debugging.inspect} was not `true` in the bundle's entitlements."
			end
		else
			issues << "\t- ❌ #{allow_debugging.inspect} was missing from the bundle's entitlements."
		end

		if issues.any?
			puts "There were issues with the code-signing:"
			puts issues
			puts
			return false
		end

		puts

		true
	end
}
