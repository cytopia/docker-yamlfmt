#!/usr/bin/env bash

# Be strict
set -e
set -u
set -o pipefail


###
### Globals
###
ARG_WRITE=0                       # yamlfmt arg for -w
ARG_IGNORE=                       # yamlfmt arg to ignore files found via glob
REG_GLOB='(\*.+)|(.+\*)|(.+\*.+)' # Regex pattern to identify valid glob supported by 'find'


###
### Show Usage
###
print_usage() {
	>&2 echo "Usage: cytopia/yamlfmt [-h] [-w] [file|pattern]"
	>&2 echo
	>&2 echo "positional arguments:"
	>&2 echo "  file           file to parse"
	>&2 echo "  pattern        glob pattern for recursive scanning. (e.g.: *\\.yml)"
	>&2 echo
	>&2 echo "optional arguments:"
	>&2 echo "  -h, --help     show this help message and exit"
	>&2 echo "  -w, --write    write formatted outpout to (source) file instead of stdout"
	>&2 echo "  -i, --ignore   comma separated list of paths to ignore when using glob pattern."
}


###
### Validate YAML file
###
### @param  int    write file (-w): 1: Yes and 0: No
### @param  string Path to file.
### @return int    Success (0: success, >0: Failure)
###
_yamlfmt() {
	local write="${1}"
	local file="${2}"
	# shellcheck disable=SC2155
	local temp="/tmp/$(basename "${file}")"
	local ret=0

	# Overwrite original file
	if [ "${write}" -eq "1" ]; then
		local cmd="yamlfmt -w ${file}"
		echo "${cmd}"

		if ! eval "${cmd}" > "${temp}"; then
			ret=$(( ret + 1 ))
		fi

	# Diff file
	else
		local cmd="yamlfmt ${file}"
		echo "${cmd}"

		cp -f "${file}" "${temp}"
		if ! eval "yamlfmt -w ${temp}"; then
			ret=$(( ret + 1 ))
		fi

		# Only diff if file is not empty
		if [ -s "${temp}" ]; then
			if !  diff "${file}" "${temp}"; then
				ret=$(( ret + 1 ))
			fi
		fi
	fi

	return "${ret}"
}


###
### Arguments appended?
###
if [ "${#}" -gt "0" ]; then

	while [ "${#}" -gt "0"  ]; do
		case "${1}" in
			# Show Help and exit
			--help|-h)
				print_usage
				exit 0
				;;
			# Add yamlfmt argument to write to file
			--write|-w)
				shift
				ARG_WRITE=1
				;;
			# Ignore glob patterh
			-i)
				shift
				if [ "${#}" -lt "1" ]; then
					>&2 echo "Error, -i requires an argument"
					exit 1
				fi
				ARG_IGNORE="${1}"
				shift
				;;
			# Anything else is handled here
			*)
				# Case 1/2: Its a file
				if [ -f "${1}" ]; then
					# Argument check
					if [ "${#}" -gt "1" ]; then
						>&2 echo "Error, you cannot specify arguments after the file position."
						print_usage
						exit 1
					fi
					_yamlfmt "${ARG_WRITE}" "${1}"
					exit "${?}"
				# Case 2/2:  Its a glob
				else
					# Glob check
					if ! echo "${1}" | grep -qE "${REG_GLOB}"; then
						>&2 echo "Error, invalid file or wrong glob format. Allowed: '${REG_GLOB}'"
						exit 1
					fi
					# Argument check
					if [ "${#}" -gt "1" ]; then
						>&2 echo "Error, you cannot specify arguments after the glob position."
						print_usage
						exit 1
					fi

					# Iterate over all files found by glob and jsonlint them
					if [ -z "${ARG_IGNORE}" ]; then
						find_cmd="find . -name \"${1}\" -type f -print0"
					else
						find_cmd="find . -not \( -path \"${ARG_IGNORE}\" \) -name \"${1}\" -type f -print0"
					fi

					echo "${find_cmd}"
					ret=0
					while IFS= read -rd '' file; do
						if ! _yamlfmt "${ARG_WRITE}" "${file}"; then
							ret=$(( ret + 1 ))
						fi
					done < <(eval "${find_cmd}")
					exit "${ret}"
				fi
				;;
		esac
	done

###
### No arguments appended
###
else
	print_usage
	exit 0
fi
