#
# Homebrew
#
# Almost everything the 2022 version of this file did is now handled elsewhere:
#
#   - `brew shellenv` runs at the top of .zshrc (needed before zplug) and again
#     via Prezto's `homebrew` module, which caches it.
#   - FPATH for brew's completions is set by Prezto's `homebrew` module.
#   - compinit is run by Prezto's `completion` module. The old file called it a
#     second time, which is slow and can shadow completions.
#
# So this fragment is down to one setting.
#

# Suppress the "hints" Homebrew prints after some commands.
# Drop this if you ever want the suggestions back.
export HOMEBREW_NO_ENV_HINTS=1
