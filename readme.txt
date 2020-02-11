Download the setup.sh from this repo and manually move it to your device.

Run the setup.sh, keep an eye on any errors as APT seems to be somewhat flakey.

On your PC you need:

http://www.graphviz.org/

http://www.doxygen.org/

Usage:

call using /Applications/iNalyzer.App/iNalyzer <arguments>

list			- List all of the applications and their bundleGUID
clean			- Clean up the iNalyzer working directory
version			- Print the version
help			- Print the help screen
info <bundleGUID>	- Print information On the App
ipa <bundleGUID>	- Export the install app to an IPA
sandbox <bundleGUID>	- creates a zip of the application sandbox
dynamic <bundleGUID>	- "Analyses the application sandbox for dynamicly created files things like Plists Databases etc etc"
nslog <bundleGUID>	- This is broken im not fixing it
cycript <bundleGUID>	- This is broken im not fixing it
static <bundleGUID>	- Analyses the static application folder, looks at the binaries

Original info:
https://appsec-labs.com/inalyzer/
https://appsec-labs.com/tools/iNalyzer-User-Guide.pdf
