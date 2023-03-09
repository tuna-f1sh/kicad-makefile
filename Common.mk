COMMON_INCLUDED = TRUE
# Useful functions
# Returns the first argument (typically a directory), if the file or directory
# named by concatenating the first and optionally second argument
# (directory and optional filename) exists
dir_if_exists = $(if $(wildcard $(1)$(2)),$(1))

# Run a shell script if it exists. Stops make on error.
runscript_if_exists =                                                          \
    $(if $(wildcard $(1)),                                                     \
         $(if $(findstring 0,                                                  \
                  $(lastword $(shell $(abspath $(wildcard $(1))); echo $$?))), \
              $(info Info: $(1) success),                                      \
              $(error ERROR: $(1) failed)))

# For message printing: pad the right side of the first argument with spaces to
# the number of bytes indicated by the second argument.
space_pad_to = $(shell echo "$(1)                                                       " | head -c$(2))

# Call with some text, and a prefix tag if desired (like [AUTODETECTED]),
config_info = $(call space_pad_to,$(2),$(3)) $(1)
show_config_info = $(call shell_output,$(call space_pad_to,$(2),$(3)) $(1))

# Call with the name of the variable, a prefix tag if desired (like [AUTODETECTED]),
# and an explanation if desired (like (found in $$PATH)
show_config_variable = $(call show_config_info,$(1) = $($(1)),$(2),$(3))
config_variable = $(call config_info,$(1) = $($(1)),$(2),$(3))

# Just a nice simple visual separator
show_separator = $(call shell_output,-------------------------)

# Git tag-revsions-hash
git_tag_ver = $(shell git describe --abbrev=4 --always --tags --long 2>/dev/null)
git_commit = $(shell git describe --abbrev=5 --always --long 2>/dev/null)

# Printing defines
define newline

endef

null  :=
space := $(null) #
comma := ,

########################################################################
#
# Detect OS

ifeq ($(OS),Windows_NT)
    CURRENT_OS = WINDOWS
    GREP = grep
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        CURRENT_OS = LINUX
        GREP = grep
    endif
    ifeq ($(UNAME_S),Darwin)
        CURRENT_OS = MAC
        # use gnu grep if available
        ifeq (, $(shell which ggrep))
            GREP = grep
        else
            GREP = ggrep
        endif
    endif
endif
